% test

clc; clear; close all;

%% parameters
thre        = 0.01; % 0.01 g as default non-moving threshold
minLenNoMov = 10;   % sec
epochLength = 30;   % sec

testPath = 'C:\Users\pl806\Dropbox (Partners HealthCare)\Share with MBP\Projects_Ongoing\SleepDisruption_TauAccumulation_Aging_Laura';
filename = 'SOM001_MS(2022-06-29)_30Hz_256';

fs   = 30;

dat = readtimetable(fullfile(testPath, filename), ...
    'FileType', 'text', ...
    'NumHeaderLines', 1, 'ReadVariableNames', 0, ...
    'Delimiter', ',');

%% get episodes that are less likely to have movement
[consDat, errorMsg, success] = getNoMovingEpi(dat, fs, thre, minLenNoMov);

if ~success
    continue;
end

%% recalibration
% adapt to the input of estimateCalibration, which removes time inside
if height(consDat) < 4
    errorMsg = errorMsg + "; " + "Abort: too few seconds without moving";
    success  = ~success;
    continue;
elseif height(consDat) < 10
    errorMsg = errorMsg + "; " + "Warn: calibration may not be accurate";
end

calib = estimateCalibration([nan(height(consDat), 1) consDat{:, :}], 'useTemp', 0);

% % test rescale
% figure;
% plot3(consDat.(1), consDat.(2), consDat.(3), 'LineStyle', 'none', 'marker', '.');
% axis square
% 
% acc  = [datenum(consDat.Time) consDat{:, :}];
% rdat = struct('ACC', acc);
% rConsDat = rescaleData(rdat, calib);
% 
% hold on;
% plot3(rConsDat.ACC(:, 2), rConsDat.ACC(:, 3), rConsDat.ACC(:, 4), 'LineStyle', 'none', 'marker', '.', 'Color', 'r');

% adjust input to rescaleData
acc  = [datenum(dat.Time) dat{:, :}];
iDat = struct('ACC', acc);
rDat = rescaleData(iDat, calib);

%% calculate activity count
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

% compare with VM
comPath = '..\test\GT3X\SOM001\Exports';
comname = 'SOM001_MS (2022-06-29)10sec30secDataTable.csv';
comTbl  = readtable(fullfile(comPath, comname), 'NumHeaderLines', 10, 'ReadVariableNames', 1);

figure;
hold on;
plot(comTbl.VectorMagnitude, 'r', 'LineWidth', 2);
plot(epochAcc.(1), 'b');