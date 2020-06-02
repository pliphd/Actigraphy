function runFile(process, source, destination, epoch, fid)
%RUNFILE run a process on a specific file
%   
%   RUNFILE(PROCESS, SOURCE, DESTIMATION, EPOCH, FID) does PROCESS in file 
%       SOURCE and write results to DESTINATION. EPOCH specifies the epoch
%       length in sec of file SOURCE. FID is transfered in to save requested
%       results.
%
%   $Author:    Peng Li
% 

% parse inputs to generate file name
[~, filename] = fileparts(source);
writeFile     = fullfile(destination, [filename '.' lower(process(4:end))]);

actigraphy = load(source);

[toFile, res, fmt] = feval(process, actigraphy, epoch);
fin = fopen(writeFile, 'w');
fprintf(fin, '%d\t%d\r', toFile');
fclose(fin);

fprintf(fid, fmt, res);