log -r sim:/*
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate sim:/tb_axi_lite_to_apb/clk
add wave -noupdate sim:/tb_axi_lite_to_apb/rst_n
add wave -noupdate sim:/tb_axi_lite_to_apb/axi_req
add wave -noupdate sim:/tb_axi_lite_to_apb/axi_resp
add wave -noupdate sim:/tb_axi_lite_to_apb/apb_req
add wave -noupdate sim:/tb_axi_lite_to_apb/apb_resps
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {16 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 500
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {408 ns}
