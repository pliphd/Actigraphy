function parSleepDetection(source, destination, epoch, option)
%PARSLEEPDETECTION detect sleep in activity files using parallel process
%
%   PARSLEEPDETECTION(SOURCE, DESTINATION, EPOCH, OPTION) run all
%   files stored in SOURCE and save results in seperate files in
%   DESTINATION. EPOCH is a scalar that specifies the epoch of all files.
%   OPTION is a struct specifying the startime.
%
%   $Author:    Peng Li
%   $Date:      Dec 3, 2020
%

allFiles = dir(fullfile(source, '*.txt'));

fprintf('==\tSLEEP DETECTION\r');
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
    runFile('detSleep', curFile, destination, epoch, c.Value, option);
    
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
tbl.Properties.VariableNames = {'filename', ...
    ['sleep_duration_' replace(option.sleepWindow.StartTime, ':', '') '_' replace(option.sleepWindow.EndTime, ':', '') '_avg'], ...
    'numbers_awake_avg'};
writetable(tbl, fullfile(destination, 'sleep_stat.sum'), 'FileType', 'text');
fprintf('==\tresults consolidated\r');

fprintf('==\tFINISHED\r');
end

function prog(x)
if mod(x, 500) == 0
    fprintf('==\t%d done\r', x)
end
end