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

fprintf('==\t\tGAP DETECTION\t\t==\r');
fprintf('==\t%d files to process\t\t==\r', numel(allFiles));

p = gcp('nocreate');
if isempty(p)
    p = parpool;
    poolsize = p.NumWorkers;
else
    poolsize = p.NumWorkers;
end
fprintf('==\tdistributed into %d workers\t==\r', poolsize);

% q the status within parfor
q = parallel.pool.DataQueue;
afterEach(q, @(x) fprintf('==\t%d done \t\t ==\r', x));

% create unique file id within each worker
c = parallel.pool.Constant(@() fopen(tempname(destination), 'wt'), @fclose);
spmd
    fopen(c.Value);
end

parfor idx = 1:numel(allFiles)
    curFile = fullfile(source, allFiles(idx).name);
    runFile('detGap', curFile, destination, epoch, c.Value);
    
    if mod(idx, 100) == 0
        send(q, idx);
    end
end

% throw c to run fclose
clear c;

fprintf('==\t\tFINISHED!\t\t==\r');