function parUPMEMDDetection(source, destination, epoch, option)
%PARUPMEMDDETECTION do upmemd in activity files using parallel process
%
%   PARUPMEMDDETECTION(SOURCE, DESTINATION, EPOCH, OPTION) run upmemd on all
%   files stored in SOURCE and save results in seperate files in
%   DESTINATION. EPOCH is a scalar that specifies the epoch of all files. 
%   OPTION is a struct specifying cycle length targeted and starttime.
%
%   $Author:    Peng Li
%

% to amend, including name patterns as input
allFiles = dir(fullfile(source, '*epoch15.txt'));

fprintf('==\tUPMEMD PROC\r');
fprintf('==\t%d files to process\r', numel(allFiles));

p = gcp('nocreate');
if isempty(p)
    p = parpool;
    poolsize = p.NumWorkers;
else
    poolsize = p.NumWorkers;
end
fprintf('==\tdistributed into %d workers\r', poolsize);

% q the status within parfor
q = parallel.pool.DataQueue;
q.afterEach(@(x) prog(x));

% create unique file id within each worker
c = parallel.pool.Constant(@() fopen(tempname(destination), 'wt'), @fclose);
spmd
    A = fopen(c.Value);
end

parfor idx = 1:numel(allFiles)
    curFile = fullfile(source, allFiles(idx).name);
    runFile('detUPMEMD', curFile, destination, epoch, c.Value, option);
    
    send(q, idx);
end

% throw c to run fclose
clear c;

% merge
fprintf('==\tstarting consolidation\r');
spmd
    tblLab = readtable(A, 'ReadVariableNames', 0, ...
        'Delimiter', '\t');
end
tbl = vertcat(tblLab{:});
tbl.Properties.VariableNames = {'filename', 'amplitude_mean', 'amplitude_std', 'period_mean', 'period_std', 'acrophase_mean', 'acrophase_std', 'actigraphy_cycle6_std'};
writetable(tbl, fullfile(destination, 'upmemd_stat.sum'), 'FileType', 'text');
fprintf('==\tresults consolidated\r');

fprintf('==\tFINISHED\r');
end

function prog(x)
if mod(x, 500) == 0
    fprintf('==\t%d done\r', x)
end
end