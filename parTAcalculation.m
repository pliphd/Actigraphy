function parTAcalculation(source, destination, epoch, option)
%PARTACALCULATION calculate total activity in activity files using parallel process
%
%   PARTACALCULATION(SOURCE, DESTINATION, EPOCH, OPTION) run all
%   files stored in SOURCE and save results in seperate files in
%   DESTINATION. EPOCH is a scalar that specifies the epoch of all files.
%   OPTION is a struct specifying the startime and windowlength
%   information.
%
%   $Author:    Peng Li
%

allFiles = dir(fullfile(source, '*.txt'));

fprintf('==\tTOTAL ACTIVITY\r');
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

parfor idx = 1:numel(allFiles)
    curFile = fullfile(source, allFiles(idx).name);
    runFile('detTotalActivity', curFile, destination, epoch, [], option);
    
    send(q, idx);
end

fprintf('==\tFINISHED\r');
end

function prog(x)
if mod(x, 500) == 0
    fprintf('==\t%d done\r', x)
end
end