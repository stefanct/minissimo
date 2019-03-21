function [stats] = read_stats(directory)
%readStats reads statistics files written by the testbench
    
    statFiles = split(ls([directory filesep '*_statistics.log']));
        
    fprintf('\nreading statistics files...\n\n');
    
    idx = 1;
    nFiles=0;
    stats={};
    
    for k=1:length(statFiles)
        if ~isfile(statFiles{k})
            continue;
        end
        fprintf('> %s\n',statFiles{k});
        fp=fopen(statFiles{k},'r');
        while ~feof(fp)
            % read config
            stats.network{idx}      = fscanf(fp, 'test config:\nnet: %s\n');
            stats.numMaster{idx}    = fscanf(fp, 'numMaster: %5d\n',1);
            stats.numBanks{idx}     = fscanf(fp, 'numBanks: %5d\n',1);
            stats.dataWidth{idx}    = fscanf(fp, 'dataWidth: %5d\n',1);
            stats.memAddrBits{idx}  = fscanf(fp, 'memAddrBits:%5d\n',1);
            stats.testCycles{idx}   = fscanf(fp, 'testCycles: %5d\n',1);
            fscanf(fp, 'testName:\n');
            stats.testName{idx}     = '';
            c=fscanf(fp, '%c',1);
            while c~=char(10)
                stats.testName{idx} = [stats.testName{idx} c];
                c=fscanf(fp, '%c',1);
            end    
            stats.pReq{idx}         = fscanf(fp, 'pReq: %e\n',1);
            stats.maxLen{idx}       = fscanf(fp, 'maxLen: %d\n',1);
            % read test statistics
            stats.ports{idx}        = fscanf(fp, 'Port %3d: Req=%5d Gnt=%5d p=%e Wait=%e\n',5*stats.numMaster{idx});
            stats.banks{idx}        = fscanf(fp, 'Bank %03d: Req=%05d Load=%e\n',3*stats.numBanks{idx});
            fscanf(fp, '\n');
            idx=idx+1;
        end
        fclose(fp);
        nFiles=nFiles+1;
    end 
    
    % get some meta info
    % network types and number of runs
    stats.netTypes = sortrows(unique(stats.network)')';
    stats.nFiles   = nFiles;
    stats.numRuns  = idx-1;
    stats.configs  = {};
    order=[];
    % network configurations in terms of nMaster x nBanks
    for k=1:stats.numRuns
        stats.configs  = [stats.configs {[num2str(stats.numMaster{k}) 'x' num2str(stats.numBanks{k})]}];
        order(k)       = stats.numMaster{k}*stats.numBanks{k};
    end    
    % sort the configs
    [stats.configLabels, idx, ~] = unique(stats.configs);
    [~,idx]                      = sortrows(order(idx)');
    stats.configLabels           = stats.configLabels(idx);
    
    % sort according to networks
    [~,idx]                 = sortrows(stats.network');
    stats.network           = stats.network(idx);
    stats.numMaster         = stats.numMaster(idx);
    stats.numBanks          = stats.numBanks(idx);
    stats.dataWidth         = stats.dataWidth(idx);
    stats.memAddrBits       = stats.memAddrBits(idx);
    stats.testCycles        = stats.testCycles(idx);
    stats.testName          = stats.testName(idx);
    stats.pReq              = stats.pReq(idx);
    stats.maxLen            = stats.maxLen(idx);
    stats.ports             = stats.ports(idx);
    stats.banks             = stats.banks(idx);
    stats.configs           = stats.configs(idx);
    order                   = order(idx);
    % sort nMaster x nBank configs within network type
    for k = 1:length(stats.netTypes)
        tst     = strcmp(stats.netTypes{k}, stats.network);
        [~,idx] = sortrows(order(tst)');
        tmp                    = stats.network(tst);
        stats.network(tst)     = tmp(idx);
        tmp                    = stats.numMaster(tst);
        stats.numMaster(tst)   = tmp(idx);
        tmp                    = stats.numBanks(tst);
        stats.numBanks(tst)    = tmp(idx);
        tmp                    = stats.dataWidth(tst);
        stats.dataWidth(tst)   = tmp(idx);
        tmp                    = stats.memAddrBits(tst);
        stats.memAddrBits(tst) = tmp(idx);
        tmp                    = stats.testCycles(tst);
        stats.testCycles(tst)  = tmp(idx);
        tmp                    = stats.testName(tst);
        stats.testName(tst)    = tmp(idx);
        tmp                    = stats.pReq(tst);
        stats.pReq(tst)        = tmp(idx);
        tmp                    = stats.maxLen(tst);
        stats.maxLen(tst)      = tmp(idx);
        tmp                    = stats.ports(tst);
        stats.ports(tst)       = tmp(idx);
        tmp                    = stats.banks(tst);
        stats.banks(tst)       = tmp(idx);
        tmp                    = stats.configs(tst);
        stats.configs(tst)     = tmp(idx);
    end    

    fprintf('\nread %d files with %d simulation runs\n\n', stats.nFiles, stats.numRuns);
end
