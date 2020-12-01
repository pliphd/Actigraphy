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
[srcPath, filename] = fileparts(source);
writeFile  = fullfile(destination, [filename '.' lower(process(4:end))]);
actigraphy = load(source);

% load gap if exist
quality = ones(size(actigraphy, 1), 1);
gapFile = fullfile(srcPath, [filename(1:end-4) '.gap']);
if exist(gapFile, 'file') == 2
    gap = load(gapFile);
    
    for iS = 1:size(gap, 1)
        quality(gap(iS, 1):gap(iS, 2)) = 0;
    end
end

% parse arg
if nargin > 5
    option = varargin{1};
    
    if isfield(option, 'starttime')
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
    end
    
    if isfield(option, 'windowLength')
        windowLength = option.windowLength;
    end
    
    if isfield(option, 'region')
        region = option.region;
    end
end

switch process
    case 'detGap'
        [toFile, res, fmt] = feval(process, actigraphy(:, 1), epoch);
    case 'calGap'
        [toFile, res, fmt] = feval(process, actigraphy(:, 1), epoch, quality);
    case 'detTotalActivity'
        toFile = feval(process, actigraphy(:, 1), epoch, starttime, windowLength);
    case 'detAlpha'
        [res, fmt] = feval(process, actigraphy(:, 1), epoch, region, filename, starttime, destination, quality);
end

switch process
    case {'detGap', 'calGap'}
        if ~(isempty(toFile))
            fin = fopen(writeFile, 'w');
            fprintf(fin, '%d\t%d\r', toFile');
            fclose(fin);
        end
        
        fprintf(fid, ['%s\t' fmt], filename, res);
    case 'detTotalActivity'
        writetable(toFile, writeFile, 'FileType', 'text');
    case 'detAlpha'
        for iR = 1:size(res, 1)
            fprintf(fid, ['%s\t' fmt], filename, res(iR, :));
        end
end