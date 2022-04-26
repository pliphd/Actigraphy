function [res, fmt] = detUPMEMD(actigraphy, epoch, varargin)
%DETUPMEMD do uniform phase masked empirical mode decomposition and calculate
% circadian metrics
%   
%   [RES, FMT] = DETUPMEMD(ACTIGRAPHY, EPOCH, CYCLELENGTH, FILENAME, STARTTIME, FILEPATH, QUALITY, MINCYCLE)
%       performs uniform phase masked empirical mode decomposition on ACTIGRAPHY
%       of epoch length EPOCH second with target cycle length CYCLELENGTH h.
%       RES stores results amp (mean, sd), cycle length (mean, sd), and
%       phase (mean, sd).
%       FMT request the format to write RES to file
%
%   $Author:    Peng Li
% 

% to be modified
narginchk(7, 8);

cyclelen   = varargin{1};
filename   = varargin{2};
filepath   = varargin{4};

% Apr. 26, 2022
% add minCycles as a parameter
if nargin == 8
    minCycle = varargin{6};
else
    minCycle = 6; % in order to adapt previous versions
end

%% using fixed number of cycles
startTime  = datenum(varargin{3});
endTime    = (length(actigraphy)-1)*epoch / (3600*24) + startTime;
t          = linspace(startTime, endTime, length(actigraphy))';

% adapt to the MEMD program here
% ++++++++++++++++++ MEMD +++++++++++++++++++++++++++++++++++++++++
% DISCLAIMER: may need optimization
%             PL used the original MEMD from MBP directly
%             except that PL changed the i/o
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sampf = 60 / (epoch/60); % 60*1/min
fc    = 1  / cyclelen;   % 1/h

imf   = upmemd(actigraphy', sampf, fc); % need a row vector as first input

[cycleStart, cycleLength, cycleAmplitude] = ...
    IMFCycleFA(imf(end, :), sampf);

% if at least minCycle cycles
if all(isnan(cycleStart)) || numel(cycleStart) < minCycle
    res = [nan nan nan nan nan nan nan];
else
    % Apr 26, 2022
    % when minCycle == 1, use all available results
    if minCycle == 1
        cycleN   = numel(cycleStart);
    else
        cycleN   = minCycle;
    end

    % request output
    meanAmplitude = mean(cycleAmplitude(1:cycleN), 'omitnan');
    sdAmplitude   = std(cycleAmplitude(1:cycleN), 'omitnan');
    
    meanPeriod    = mean(cycleLength(1:cycleN), 'omitnan');
    sdPeriod      = std(cycleLength(1:cycleN), 'omitnan');
    
    peakTime      = datetime(t(cycleStart), 'ConvertFrom', 'datenum');
    phaseInHour   = hour(peakTime) + minute(peakTime)/60 + second(peakTime)/3600;
    meanPhase     = mean(phaseInHour, 'omitnan');
    sdPhase       = std(phaseInHour, 'omitnan');
    
    cycle6SD      = std(actigraphy(1:ceil(sum(cycleLength(1:cycleN))*3600/epoch)));
    
    res = [meanAmplitude, sdAmplitude, meanPeriod, sdPeriod, meanPhase, sdPhase, cycle6SD];
    
    % request to save component here
    comp24 = imf(end, :);
    
    if ~(exist(fullfile(filepath, 'upmemd'), 'dir') == 7)
        mkdir(fullfile(filepath, 'upmemd'));
    end
    writematrix(comp24, fullfile(filepath, 'upmemd', [filename '.upmemd']), ...
        'FileType', 'text');
end

fmt = '%f\t%f\t%f\t%f\t%f\t%f\t%f\n';

%% below back up for fixed length analysis
% % fixed length
% if length(actigraphy) < 7*24*3600/epoch
%     res = [nan nan nan nan nan nan];
% else
%     actigraphy = actigraphy(1:7*24*3600/epoch);
%     
%     startTime  = datenum(varargin{3});
%     endTime    = (length(actigraphy)-1)*epoch / (3600*24) + startTime;
%     t          = linspace(startTime, endTime, length(actigraphy))';
%     
%     % adapt to the MEMD program here
%     % ++++++++++++++++++ MEMD +++++++++++++++++++++++++++++++++++++++++
%     % DISCLAIMER: may need optimization
%     %             PL used the original MEMD from MBP directly
%     %             except that PL changed the i/o
%     % +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%     
%     sampf = 60 / (epoch/60); % 60*1/min
%     fc    = 1  / cyclelen;   % 1/h
%     
%     imf   = upmemd(actigraphy', sampf, fc); % need a row vector as first input
%     
%     [cycleStart, cycleLength, cycleAmplitude] = ...
%         IMFCycleFA(imf(end, :), sampf);
%     
%     % request output
%     meanAmplitude = nanmean(cycleAmplitude);
%     sdAmplitude   = nanstd(cycleAmplitude);
%     
%     meanPeriod    = nanmean(cycleLength);
%     sdPeriod      = nanstd(cycleLength);
%     
%     if ~isnan(cycleStart)
%         peakTime      = datetime(t(cycleStart), 'ConvertFrom', 'datenum');
%         phaseInHour   = hour(peakTime) + minute(peakTime)/60 + second(peakTime)/3600;
%         meanPhase     = nanmean(phaseInHour);
%         sdPhase       = nanstd(phaseInHour);
%     else
%         meanPhase = nan;
%         sdPhase   = nan;
%     end
%     
%     res = [meanAmplitude, sdAmplitude, meanPeriod, sdPeriod, meanPhase, sdPhase];
%     
%     % request to save component here
%     comp24 = imf(end, :);
%     
%     if ~(exist(fullfile(filepath, 'upmemd'), 'dir') == 7)
%         mkdir(fullfile(filepath, 'upmemd'));
%     end
%     writematrix(comp24, fullfile(filepath, 'upmemd', [filename '.upmemd']), ...
%         'FileType', 'text');
% end