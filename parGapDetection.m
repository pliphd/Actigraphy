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

% create unique file id within each worker
c = parallel.pool.Constant(@() fopen(tempname(destination), 'wt'), @fclose);
spmd
    fopen(c.Value);
end

parfor idx = 1:length(allFiles)
    curFile = fullfile(source, allFile(idx).name);
    runFile('detGap', curFile, destination, epoch, c.Value);
end

% throw c to run fclose
clear c;