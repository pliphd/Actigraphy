function runFile(process, source, destination, epoch, fid, varargin)
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

% parse arg
if nargin > 5
    option = varargin{1};
    switch option.starttime
        case 'fixed'
            starttime = option.time;
        case 'filename'
            out = feval(option.file, filename);
            starttime = out.starttime;
            
            if isfield(out, 'epoch')
                epoch = out.epoch; % overwrite epoch if applicable
            end
    end
    windowLength = option.windowLength;
end

if nargin == 5
    [toFile, res, fmt] = feval(process, actigraphy(:, 1), epoch);
else
    toFile = feval(process, actigraphy(:, 1), epoch, starttime, windowLength);
end

if ~(isempty(toFile))
    switch process
        case 'detGap'
            fin = fopen(writeFile, 'w');
            fprintf(fin, '%d\t%d\r', toFile');
            fclose(fin);
            
            fprintf(fid, ['%s\t' fmt], filename, res);
        case 'detTotalActivity'
            writetable(toFile, writeFile, 'FileType', 'text');
    end
end