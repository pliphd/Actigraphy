% batch processing
% convert 3-D accelerometer data to 1-D activity counts time-series
% epoch is pre-defined as 30 sec
% 
% $Author:  Peng Li, Ph.D.
% 

clc; clear; close all; diary off;

%% parameters
% re-define epoch length below if needed
epochLength = 30;   % sec

% below parameters have been used in our other projects. better not to
% change
thre        = 0.01; % 0.01 g as default non-moving threshold
minLenNoMov = 10;   % sec

% i/o
pathname = uigetdir(".", "Please select the folder containing accelerometer files in ASCII format ...");
if ~pathname
    return;
end
allfiles = dir(fullfile(pathname, "*.txt"));

outpath  = fullfile(pathname, "activity_counts");
if ~(exist(outpath, "dir") == 7)
    mkdir(outpath);
end

%% loop
logname = "log_" + datestr(datetime(now, 'ConvertFrom', 'datenum'), 'yyyymmddHHMMss') + ".log";
diary(fullfile(outpath, logname));

t = nan(numel(allfiles), 1);
for iF = 1:numel(allfiles)
    curFile = allfiles(iF).name;

    fprintf(">> processing now: %s\n", curFile);

    tic;

    % parse name
    nameparts = strsplit(curFile, "_");
    fs = str2double(nameparts{end-1}(1:end-2));

    dat = readtimetable(fullfile(pathname, curFile), ...
        'FileType', 'text', ...
        'NumHeaderLines', 1, 'ReadVariableNames', 0, ...
        'Delimiter', ',');

    % ++++++ step 1: get episodes that are less likely to have movement
    [consDat, errorMsg, success] = getNoMovingEpi(dat, fs, thre, minLenNoMov);

    if ~success
        fprintf(">> ++ %s\n", errorMsg);
        continue;
    end

    % ++++++ step 2: recalibration
    % adapt to the input of estimateCalibration, which removes time inside
    if height(consDat) < 4
        errorMsg = errorMsg + "; " + "Abort: too few seconds without moving";
        fprintf(">> ++ %s\n", errorMsg);
        success  = ~success;
        continue;
    elseif height(consDat) < 10
        errorMsg = errorMsg + "; " + "Warn: calibration may not be accurate";
        fprintf(">> ++ %s\n", errorMsg);
    end

    calib = estimateCalibration([nan(height(consDat), 1) consDat{:, :}], 'useTemp', 0);

    % adjust input to rescaleData
    acc  = [datenum(dat.Time) dat{:, :}];
    iDat = struct('ACC', acc);
    rDat = rescaleData(iDat, calib);

    % ++++++ step 3: calculate activity count
    % first order difference
    chgAcc = abs(diff(rDat.ACC(:, 2:end), 1, 1));

    % filtering, the resolution r=1/256, it looks that in stable episode, the
    % change are within 7r. Using 5r as a conservative filter
    chgAccFiltered = chgAcc;
    chgAccFiltered = floor(chgAccFiltered*256/5)*5/256;

    % magnitude of vector, per second
    magAcc = sqrt(sum(chgAccFiltered.^2, 2)) * fs;

    % re-adapt to timetable framework
    magAccTT = array2timetable(magAcc, 'RowTimes', datetime(rDat.ACC(2:end, 1), 'ConvertFrom', 'datenum'));

    % calculate activity counts per epoch
    epochAcc = retime(magAccTT, "regular", "sum", "SampleRate", 1/epochLength);
    accts    = epochAcc.(1);

    % ++++++ step 4: output
    newfilename = nameparts{1} + "_" + nameparts{2} + "_" + strcat(nameparts{3:8}) + ".txt";
    save(fullfile(outpath, newfilename), "accts", "-ascii");

    t(iF) = toc;
    fprintf(">> ++ time used: %.2f min\n", t(iF)/60)

    estiRemaining = mean(t, 'omitnan') * (numel(allfiles) - iF) / 60;
    fprintf(">> ++ Estimate remaining: %.2f min (or %.2f hour)\n-------", estiRemaining, estiRemaining/60);
end
disp("ALL DONE");
diary off;