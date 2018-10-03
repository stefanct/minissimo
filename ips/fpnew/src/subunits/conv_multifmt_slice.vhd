-------------------------------------------------------------------------------
-- Title      : Floating-Point Multiformat Conversion Slice
-- Project    :
-------------------------------------------------------------------------------
-- File       : conv_multifmt_slice.vhd
-- Author     : Stefan Mach  <smach@iis.ee.ethz.ch>
-- Company    : Integrated Systems Laboratory, ETH Zurich
-- Created    : 2018-03-24
-- Last update: 2018-10-06
-- Platform   : ModelSim (simulation), Synopsys (synthesis)
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Parametric slice containing all floating-point operations that
--              operate on a singular format.
--              Supported operations from fpnew_pkg.fpOp:
--              - F2I
--              - I2F
--              - F2F
-------------------------------------------------------------------------------
-- Copyright (C) 2018 ETH Zurich, University of Bologna
-- All rights reserved.
--
-- This code is under development and not yet released to the public.
-- Until it is released, the code is under the copyright of ETH Zurich and
-- the University of Bologna, and may contain confidential and/or unpublished
-- work. Any reuse/redistribution is strictly forbidden without written
-- permission from ETH Zurich.
--
-- Bug fixes and contributions will eventually be released under the
-- SolderPad open hardware license in the context of the PULP platform
-- (http://www.pulp-platform.org), under the copyright of ETH Zurich and the
-- University of Bologna.
-------------------------------------------------------------------------------

library IEEE, work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.fpnew_pkg.all;
use work.fpnew_fmts_pkg.all;
use work.fpnew_comps_pkg.all;

--! @brief Floating-Point Multiformat Conversion Slice
--! @details Parametric slice containing all floating-point operations that
--! operate on a singular format.
--! Supported operations from fpnew_pkg.fpOp:
--! - F2I
--! - I2F
--! - F2F
entity conv_multifmt_slice is

  generic (
    FORMATS : activeFormats_t := (Active   => (FP32 to FP16ALT => true, others => false),
                                  Encoding => DEFAULTENCODING);

    INTFORMATS : activeIntFormats_t := (Active => (others => true),
                                        Length => INTFMTLENGTHS);

    CPKFORMATS : fmtBooleans_t := (FP64 => true, FP32 => true, others => false);

    LATENCIES   : fmtNaturals_t := (others => 0);
    SLICE_WIDTH : natural       := 64;
    GENVECTORS  : boolean       := false;
    TAG_WIDTH   : natural       := 0);

  port (
    Clk_CI                    : in  std_logic;
    Reset_RBI                 : in  std_logic;
    ---------------------------------------------------------------------------
    A_DI, B_DI, C_DI          : in  std_logic_vector(SLICE_WIDTH-1 downto 0);
    ABox_SI, BBox_SI, CBox_SI : in  fmtLogic_t;
    RoundMode_SI              : in  rvRoundingMode_t;
    Op_SI                     : in  fpOp_t;
    OpMod_SI                  : in  std_logic;
    FpFmt_SI                  : in  fpFmt_t;
    FpFmt2_SI                 : in  fpFmt_t;
    IntFmt_SI                 : in  intFmt_t;
    VectorialOp_SI            : in  std_logic;
    Tag_DI                    : in  std_logic_vector(TAG_WIDTH-1 downto 0);
    ---------------------------------------------------------------------------
    InValid_SI                : in  std_logic;
    InReady_SO                : out std_logic;
    Flush_SI                  : in  std_logic;
    ---------------------------------------------------------------------------
    Z_DO                      : out std_logic_vector(SLICE_WIDTH-1 downto 0);
    Status_DO                 : out rvStatus_t;
    Tag_DO                    : out std_logic_vector(TAG_WIDTH-1 downto 0);
    Zext_SO                   : out std_logic;
    ---------------------------------------------------------------------------
    OutValid_SO               : out std_logic;
    OutReady_SI               : in  std_logic);

end entity conv_multifmt_slice;


architecture parallel_paths of conv_multifmt_slice is

  -----------------------------------------------------------------------------
  -- Constant Definitions
  -----------------------------------------------------------------------------
  -- Latency given by highest latency in active set
  constant LATENCY : natural := largestActiveLatency(LATENCIES, FORMATS);

  -- Check how many bits are needed for the narrowest active float format
  constant MIN_WIDTH : natural := MINWIDTH(FORMATS);

  -- Largest integer format we need to handle
  constant INT_WIDTH : natural := MAXWIDTH(INTFORMATS);

  -- The number of parallel lanes the slice can hold - given by narrowest format
  constant NUMLANES : natural := SLICE_WIDTH/MIN_WIDTH;

  constant FMTBITS      : natural := clog2(fpFmt_t'pos(fpFmt_t'high));
  constant IFMTBITS     : natural := clog2(intFmt_t'pos(intFmt_t'high));
  constant FMTSLVBITS   : natural := maximum(FMTBITS, IFMTBITS);
  constant TAGINT_WIDTH : natural := TAG_WIDTH+FMTSLVBITS+1;
  constant VECTAG_WIDTH : natural := 3;  -- cpk flag + 2 shift option
  ---------------------------------------------------------------------------
  -- Type Definitions
  ---------------------------------------------------------------------------

  -- Vectors of results for the lanes
  type fmtResults_t is array (fpFmt_t) of std_logic_vector(SLICE_WIDTH-1 downto 0);
  type intFmtResults_t is array (intFmt_t) of std_logic_vector(SLICE_WIDTH-1 downto 0);
  type laneResults_t is array (0 to NUMLANES-1) of std_logic_vector(SLICE_WIDTH-1 downto 0);
  type laneTags_t is array (0 to NUMLANES-1) of std_logic_vector(TAGINT_WIDTH-1 downto 0);

  -----------------------------------------------------------------------------
  -- Signal Declarations
  -----------------------------------------------------------------------------

  -- Width of input and output format (for vectors). Wider formats than
  -- SLICE_WIDTH will be ignored in the unit
  signal SrcFmtWidth_S : natural;
  signal DstFmtSlv_S   : std_logic_vector(FMTSLVBITS-1 downto 0);
  signal IsDstFmtInt_S : std_logic;
  signal SrcShift_S    : natural;
  signal DstShift_S    : std_logic_vector(1 downto 0);
  signal DstCPK_S      : std_logic;

  -- Internal tag keeps track of vectorial ops and destination width to combine
  -- results properly
  signal TagInt_D              : std_logic_vector(TAGINT_WIDTH-1 downto 0);
  signal VecTag_S, DstVecTag_S : std_logic_vector(VECTAG_WIDTH-1 downto 0);

  -- Internal Vectorial Selection
  signal VectorialOp_S               : std_logic;
  signal OpCOutReady_S, OpCInValid_S : std_logic;

  -- Output data for each format
  signal FmtOpResults_S    : fmtResults_t;
  signal IntFmtOpResults_D : intFmtResults_t;

  signal LaneResults_D     : laneResults_t;
  signal ResultVectorial_S : std_logic;
  signal IsResultFmtInt_S  : std_logic;
  signal IsResultCPK_S     : std_logic;
  signal ResultShift_S     : std_logic_vector(1 downto 0);
  signal ResultFpFmt_S     : fpFmt_t;
  signal ResultIntFmt_S    : intFmt_t;

  -- Valid, Status and Tag outputs from all lanes
  signal LaneStatus_D   : statusArray_t(0 to NUMLANES-1);
  signal LaneOutValid_S : std_logic_vector(0 to NUMLANES-1);
  signal LaneInReady_S  : std_logic_vector(0 to NUMLANES-1);
  signal LaneZext_S     : std_logic_vector(0 to NUMLANES-1);
  signal LaneTags_S     : laneTags_t;

  signal OpCDelayed_D   : std_logic_vector(Z_DO'range);
  signal PackedResult_D : std_logic_vector(Z_DO'range);

begin

  -----------------------------------------------------------------------------
  -- Input Side signals
  -----------------------------------------------------------------------------

  -- Figure out the source and destination format width (depends on op)
  with Op_SI select SrcFmtWidth_S <=
    WIDTH(FpFmt_SI, FORMATS)     when F2I,
    WIDTH(FpFmt2_SI, FORMATS)    when F2F | CPKAB | CPKCD,
    INTFORMATS.Length(IntFmt_SI) when I2F,
    0 when others;

  with Op_SI select DstFmtSlv_S <=
    std_logic_vector(resize(unsigned(to_slv(IntFmt_SI)), DstFmtSlv_S'length)) when F2I,
    std_logic_vector(resize(unsigned(to_slv(FpFmt_SI)), DstFmtSlv_S'length))  when F2F | CPKAB | CPKCD | I2F,
    (others => '-')                                                           when others;  -- don't care

  IsDstFmtInt_S <= '1' when Op_SI = F2I else '0';

  -- Mask vectorial enable if we don't have vector support
  VectorialOp_S <= VectorialOp_SI and to_sl(GENVECTORS);

  OpCInValid_S <= InValid_SI and VectorialOp_S;

  DstCPK_S <= to_sl(Op_SI = CPKAB or Op_SI = CPKCD);

  SrcShift_S <= SLICE_WIDTH/2 when (Op_SI = F2F and (VectorialOp_S and OpMod_SI) = '1'
                                    and SrcFmtWidth_S < WIDTH(FpFmt_SI, FORMATS))
                else 0;

  DstShift_S <= to_sl(Op_SI = CPKCD) & OpMod_SI when Op_SI = CPKAB or Op_SI = CPKCD else
                std_logic_vector(to_unsigned(SLICE_WIDTH/SrcFmtWidth_S/2, 2)) when Op_SI = F2F and OpMod_SI = '1' and SrcFmtWidth_S > WIDTH(FpFmt_SI, FORMATS) else
                (others => '0');


  -- Upstream Ready is signalled if first lane can accept instructions
  InReady_SO <= LaneInReady_S(0);

  -- Add the format we're using to the tag so we know how to properly unpack
  -- the result
  TagInt_D <= IsDstFmtInt_S & DstFmtSlv_S & Tag_DI;
  -- Add vectorial shift information to the vecorial tag
  VecTag_S <= DstCPK_S & DstShift_S;

  -----------------------------------------------------------------------------
  -- Generate multiformat slices
  -----------------------------------------------------------------------------

  g_sliceLanes : for i in 0 to NUMLANES-1 generate

    -- dimensions of lanes differ for formats and position, set active formats
    constant LANEFORMATS    : activeFormats_t    := getMultiLaneFormats(FORMATS, SLICE_WIDTH, i, CPKFORMATS);
    constant LANEINTFORMATS : activeIntFormats_t := getMultiLaneFormats(INTFORMATS, SLICE_WIDTH, i);
    constant LANE_WIDTH     : natural            := MAXWIDTH(LANEFORMATS);

    -- Lane's input data. Upper input bits of narrow formats are ignored
    signal AShifted_D : std_logic_vector(A_DI'range);
    signal LaneIn_D   : std_logic_vector(LANE_WIDTH-1 downto 0);

    -- Input Operand NaN-boxed checks (only for scalars)
    signal ABox_S, BBox_S, CBox_S : fmtLogic_t;

    -- Enable signal for lanes
    signal InValid_S  : std_logic;
    signal OutValid_S : std_logic;
    signal OutReady_S : std_logic;

    -- Lane-local results
    signal OpResult_D, Result_D : std_logic_vector(LANE_WIDTH-1 downto 0);
    signal OpStatus_D           : rvStatus_t;

  begin

    -- Generate instances (widest always, others only for vectors)
    g_laneInst : if i = 0 or GENVECTORS generate

      -- If inputs are vectorial, we need to bring the element to the LSB side
      AShifted_D <= std_logic_vector(unsigned(A_DI) srl i*SrcFmtWidth_S + SrcShift_S);

      -- CPK uses operand B on the second conversion unit
      LaneIn_D <= B_DI(LANE_WIDTH-1 downto 0) when i = 1 and (Op_SI = CPKAB or Op_SI = CPKCD) else
                  AShifted_D(LANE_WIDTH-1 downto 0);

      p_inNanBoxing : process (all) is
      begin  -- process p_inNanBoxing

        for fmt in fpFmt_t loop
          -- Boxing check is overriden for vectorial ops
          ABox_S(fmt) <= ABox_SI(fmt) or VectorialOp_S or to_sl(i /= 0);
          BBox_S(fmt) <= BBox_SI(fmt) or VectorialOp_S or to_sl(i /= 0);
          CBox_S(fmt) <= CBox_SI(fmt) or VectorialOp_S or to_sl(i /= 0);
        end loop;  -- fmt

      end process p_inNanBoxing;

      -- Generate input valid logic for this lane based on input valid:
      -- first lane always on, others only for vectorial ops
      InValid_S <= InValid_SI and (to_sl(i = 0) or VectorialOp_S);

      i_fp_conv_multi : fp_conv_multi
        generic map (
          FORMATS    => LANEFORMATS,
          INTFORMATS => LANEINTFORMATS,
          LATENCY    => LATENCY,
          TAG_WIDTH  => TAGINT_WIDTH)
        port map (
          Clk_CI       => Clk_CI,
          Reset_RBI    => Reset_RBI,
          A_DI         => LaneIn_D,
          ABox_SI      => ABox_S,
          RoundMode_SI => RoundMode_SI,
          Op_SI        => Op_SI,
          OpMod_SI     => OpMod_SI,
          FpFmt_SI     => FpFmt_SI,
          FpFmt2_SI    => FpFmt2_SI,
          IntFmt_SI    => IntFmt_SI,
          Tag_DI       => TagInt_D,
          InValid_SI   => InValid_S,
          InReady_SO   => LaneInReady_S(i),
          Flush_SI     => Flush_SI,
          Z_DO         => OpResult_D,
          Status_DO    => OpStatus_D,
          Tag_DO       => LaneTags_S(i),
          Zext_SO      => LaneZext_S(i),
          OutValid_SO  => OutValid_S,
          OutReady_SI  => OutReady_S);

      -- Generate the ready input for this lane based on downstream ready:
      -- First lane follows global ready, other lanes only for vectorial ops
      OutReady_S <= OutReady_SI and (to_sl(i = 0) or ResultVectorial_S);

      -- Upper lanes are only used when there is a vectorial op
      LaneOutValid_S(i) <= OutValid_S and (to_sl(i = 0) or ResultVectorial_S);

      -- Zero-Extend the result when requested, else NaN-Box unused results
      LaneResults_D(i)(LANE_WIDTH-1 downto 0) <= OpResult_D when LaneOutValid_S(i) = '1' else
                                                 (others => '0') when LaneZext_S(0) = '1' else
                                                 (others => '1');

      -- Silence status when result not used
      LaneStatus_D(i) <= OpStatus_D when LaneOutValid_S(i) = '1' else
                         (others => '0');
    end generate g_laneInst;
    -- Otherwise generate all ones/zeroes for NaN-boxing / silencing
    g_laneBypass : if (i /= 0 and not GENVECTORS) generate
      LaneResults_D(i) <= (others => '0') when LaneZext_S(0) = '1' else
                          (others => '1');
      LaneStatus_D(i)   <= (others => '0');
      LaneOutValid_S(i) <= '0';
      LaneInReady_S(i)  <= '0';
    end generate g_laneBypass;

--     g_fmtResults : for fmt in fpFmt_t generate
--       g_activeFmts : if LANEFORMATS.Active(fmt) generate
--         FmtOpResults_D(fmt)((i+1)*WIDTH(fmt, LANEFORMATS)-1 downto i*WIDTH(fmt, LANEFORMATS))
--           <= Result_D(WIDTH(fmt, LANEFORMATS)-1 downto 0);
--       end generate g_activeFmts;
--     end generate g_fmtResults;

--     g_intfmtResults : for ifmt in intFmt_t generate
--       g_activeFmts : if LANEINTFORMATS.Active(ifmt) generate
--         IntFmtOpResults_D(ifmt)((i+1)*LANEINTFORMATS.Length(ifmt)-1 downto i*LANEINTFORMATS.Length(ifmt))
--           <= Result_D(LANEINTFORMATS.Length(ifmt)-1 downto 0);
--       end generate g_activeFmts;
--     end generate g_intfmtResults;

  end generate g_sliceLanes;

  -- Operand C for vectorial casts needs to follow the pipeline
  i_op_c_pipe : fp_pipe
    generic map (
      WIDTH     => SLICE_WIDTH,
      LATENCY   => LATENCY,
      TAG_WIDTH => VECTAG_WIDTH)
    port map (
      Clk_CI         => Clk_CI,
      Reset_RBI      => Reset_RBI,
      Result_DI      => C_DI,
      Status_DI      => (others => '-'),
      Tag_DI         => VecTag_S,
      InValid_SI     => OpCInValid_S,
      InReady_SO     => open,
      Flush_SI       => Flush_SI,
      ResultPiped_DO => OpCDelayed_D,
      StatusPiped_DO => open,
      TagPiped_DO    => DstVecTag_S,
      OutValid_SO    => ResultVectorial_S,
      OutReady_SI    => OpCOutReady_S);

  OpCOutReady_S <= OutReady_SI and ResultVectorial_S;

  -- Restore the destination format information
  ResultFpFmt_S    <= to_fpFmt(LaneTags_S(0)(FMTBITS+TAG_WIDTH-1 downto TAG_WIDTH));
  ResultIntFmt_S   <= to_intFmt(LaneTags_S(0)(IFMTBITS+TAG_WIDTH-1 downto TAG_WIDTH));
  IsResultFmtInt_S <= LaneTags_S(0)(FMTSLVBITS+TAG_WIDTH);

  -- Restore the vectorial shift info
  ResultShift_S <= DstVecTag_S(1 downto 0);
  IsResultCPK_S <= DstVecTag_S(2);

  -----------------------------------------------------------------------------
  -- Result selection
  -----------------------------------------------------------------------------

  p_assembleResult : process (all) is
    variable ResultTmp : std_logic_vector(Z_DO'range);
  begin  -- process p_assembleResult

    ResultTmp := (others => not LaneZext_S(0));

    if IsResultFmtInt_S = '1' then
      for i in 0 to SLICE_WIDTH/INTFORMATS.Length(ResultIntFmt_S)-1 loop
        ResultTmp((i+1)*INTFORMATS.Length(ResultIntFmt_S)-1 downto i*INTFORMATS.Length(ResultIntFmt_S))
          := LaneResults_D(i)(INTFORMATS.Length(ResultIntFmt_S)-1 downto 0);
      end loop;
    else
      for i in 0 to SLICE_WIDTH/WIDTH(ResultFpFmt_S, FORMATS)-1 loop
        ResultTmp((i+1)*WIDTH(ResultFpFmt_S , FORMATS)-1 downto i*WIDTH(ResultFpFmt_S, FORMATS))
          := LaneResults_D(i)(WIDTH(ResultFpFmt_S, FORMATS)-1 downto 0);
      end loop;
      -- Vectorial Floats preserve some entries in OP C
      if ResultVectorial_S = '1' then
        ResultTmp := OpCDelayed_D;
        -- same thing but with shifts
        for i in 0 to SLICE_WIDTH/WIDTH(ResultFpFmt_S, FORMATS)-1 loop
          if not (i > 1 and IsResultCPK_S = '1') then
            ResultTmp((i+1+2*to_integer(unsigned(ResultShift_S)))*WIDTH(ResultFpFmt_S, FORMATS)-1 downto (i+2*to_integer(unsigned(ResultShift_S)))*WIDTH(ResultFpFmt_S, FORMATS))
              := LaneResults_D(i)(WIDTH(ResultFpFmt_S , FORMATS)-1 downto 0);
          end if;
        end loop;
      end if;
    end if;
    Z_DO <= ResultTmp;
  end process p_assembleResult;

--   Z_DO <= IntFmtOpResults_D(ResultIntFmt_S) when IsResultFmtInt_S = '1' else
--           FmtOpResults_D(ResultFpFmt_S);

  -- Separate the sign-extension information from the tag again
  Tag_DO  <= LaneTags_S(0)(Tag_DO'range);
  Zext_SO <= LaneZext_S(0);

  -- Combine slice status (logic ORing)
  Status_DO <= combined_status(LaneStatus_D);

  -- First lane dictates the flow of operations
  OutValid_SO <= LaneOutValid_S(0);


end architecture parallel_paths;
