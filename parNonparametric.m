function parNonparametric(source, destination, epoch, option)
%PARNONPARAMETRIC perform nonparametric analysis in activity files using parallel process
%
%   PARNONPARAMETRIC(SOURCE, DESTINATION, EPOCH, OPTION) run nonparametric analysis on all
%   files stored in SOURCE and save results in seperate files in
%   DESTINATION. EPOCH is a scalar that specifies the epoch of all files. 
%   OPTION is a struct specifying cycle length targeted and starttime.
%
%   $Author:    Peng Li
%

% to amend, including name patterns as input
allFiles = dir(fullfile(source, '*epoch15.txt'));

fprintf('==\tNONPARA PROC\r');
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
    runFile('detNonparametric', curFile, destination, epoch, c.Value, option);
    
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
tbl.Properties.VariableNames = {'filename', ['is_' num2str(option.isivInfo.TimeScaleInMin)], ['iv_' num2str(option.isivInfo.TimeScaleInMin)], ...
    'period', 'perc_missing_data', 'perc_missing_bin', 'isiv_timescale', 'm10', 'm10_mid_time', 'l5', 'l5_mid_time'};
writetable(tbl, fullfile(destination, 'nonpara_stat.sum'), 'FileType', 'text');
fprintf('==\tresults consolidated\r');

fprintf('==\tFINISHED\r');
end

function prog(x)
if mod(x, 500) == 0
    fprintf('==\t%d done\r', x)
end
end