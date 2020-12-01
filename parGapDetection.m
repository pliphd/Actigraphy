function parGapDetection(source, destination, epoch)
%PARGAPDETECTION detect gaps in activity files using parallel process
%
%   PARGAPDETECTION(SOURCE, DESTINATION, EPOCH) run gap detection on all
%   files stored in SOURCE and save detected gaps in seperate files in
%   DESTINATION. EPOCH is a scalar that specifies the epoch of all files.
%
%   $Author:    Peng Li
%

allFiles = dir(fullfile(source, '*.txt'));

fprintf('==\tGAP DETECTION\r');
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
    runFile('calGap', curFile, destination, epoch, c.Value);
    
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
tbl.Properties.VariableNames = {'filename', 'data_length', 'gap_perc'};
writetable(tbl, fullfile(destination, 'gap_stat.sum'), 'FileType', 'text');
fprintf('==\tresults consolidated\r');

fprintf('==\tFINISHED\r');
end

function prog(x)
if mod(x, 500) == 0
    fprintf('==\t%d done\r', x)
end
end