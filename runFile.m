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
gapFile1 = fullfile(srcPath, [filename '.gap']);
gapFile2 = fullfile(srcPath, 'Gap', [filename '.gap']);
if exist(gapFile1, 'file') == 2
    gap = load(gapFile1);
elseif exist(gapFile2, 'file') == 2
    gap = load(gapFile2);
else
    gap = [];
end
if ~isempty(gap)
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
    
    if isfield(option, 'cycleLength')
        cyclen = option.cycleLength;
    end
    
    if isfield(option, 'sleepWindow')
        window = option.sleepWindow;
    end
    
    if isfield(option, 'sleepParameter')
        parameter = option.sleepParameter;
    end
    
    if isfield(option, 'isivInfo')
        isivInfo = option.isivInfo;
    end
    
    if isfield(option, 'cosinorInfo')
        cosinorInfo = option.cosinorInfo;
    end
end

switch process
    case 'detGap'
        [toFile, res, fmt] = feval(process, actigraphy(:, 1), epoch);
    case 'calGap'
        [toFile, res, fmt] = feval(process, actigraphy(:, 1), epoch, quality);
    case 'detTotalActivity'
        toFile             = feval(process, actigraphy(:, 1), epoch, starttime, windowLength);
    case {'detAlpha', 'detMag'}
        [res, fmt]         = feval(process, actigraphy(:, 1), epoch, region, filename, starttime, destination, quality);
    case 'detSleep'
        [toFile, res, fmt] = feval(process, actigraphy(:, 1), epoch, starttime, quality, window, parameter);
    case 'detUPMEMD'
        [res, fmt]         = feval(process, actigraphy(:, 1), epoch, cyclen, filename, starttime, destination, quality);
    case 'detNonparametric'
        [res, fmt]         = feval(process, actigraphy(:, 1), epoch, starttime, quality, isivInfo);
    case 'detCosinor'
        [res, fmt]         = feval(process, actigraphy(:, 1), epoch, starttime, quality, cosinorInfo);
end

switch process
    case {'detGap', 'calGap', 'detSleep'}
        if ~(isempty(toFile))
            fin = fopen(writeFile, 'w');
            fprintf(fin, '%d\t%d\n', toFile');
            fclose(fin);
        end
        
        fprintf(fid, ['%s\t' fmt], filename, res);
    case 'detTotalActivity'
        writetable(toFile, writeFile, 'FileType', 'text');
    case {'detAlpha', 'detMag'}
        for iR = 1:size(res, 1)
            fprintf(fid, ['%s\t' fmt], filename, res(iR, :));
        end
    case {'detUPMEMD', 'detNonparametric', 'detCosinor'}
        fprintf(fid, ['%s\t' fmt], filename, res);
end