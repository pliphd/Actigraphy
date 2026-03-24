function this = emd(this)
%EMD Perform EMD analysis on an ACTI object
% 
% $Author:  Peng Li
% $Date:    Mar 09, 2022
% $Modif.:  Mar 24, 2026
%               Revise to enable per cycle output
% 

period = this.EMDInfo.TargetComponent;
minLen = this.EMDInfo.MinimumLengthInDays;

epoch  = this.Epoch; % in sec
x      = this.Data;

% emd doesn't support nan unfortunately. temp treat as 0 if missing
x(this.GapSeries) = 0;
x(isnan(x)) = 0;

if length(x)*epoch/3600 < minLen * period(1)
    this.EMDSummary = table(nan, nan, nan, nan, nan, nan, nan, 'VariableNames', ...
        {'meanAmplitude', 'sdAmplitude', 'meanPeriod', 'sdPeriod', 'meanPhase', 'sdPhase', 'cycleSD'});

    this.message.content = 'Min. length is not met. EMD analysis is skipped.';
    this.message.type = 'warning';
    this.analysis.emd = 0;
    return;
end

fs = 1 / epoch; % Hz
fc = 1 / period / 3600;

imf = li_upmemd(x, fs, fc);
this.Circadian = imf(:, end) + mean(x, 'omitmissing');

[cycleStart, cycleLength, cycleAmplitude] = ...
    li_upmemd_cycle(imf(:, end), fs*3600); % fs*3600 becomes 1/hr

minCycle = numel(cycleStart); % this may later be changed to an input item

% request output
meanAmplitude = mean(cycleAmplitude(1:minCycle), 'omitnan');
sdAmplitude   = std(cycleAmplitude(1:minCycle), 'omitnan');

meanPeriod    = mean(cycleLength(1:minCycle), 'omitnan');
sdPeriod      = std(cycleLength(1:minCycle), 'omitnan');

% Mar 24, 2026
% datenum is not recommended and suspect that it will be discontinued
% use datetime to improve compatibility
if this.timeSet
    staTime = this.TimeInfo.StartDate;
    verbose = sprintf('%s\n', 'Phase is in actual time.');
else
    % fake start time
    staTime = datetime(0, 1, 1, 0, 0, 0); % this corresponds to datenum 0
    verbose = sprintf('%s\n', 'Phase is w.r.t. 00:00:00 as start time.');
end

endTime = days((length(x)-1)*epoch / (3600*24)) + staTime;
t       = linspace(staTime, endTime, length(x))';

peakTime      = t(cycleStart);
phaseInHour   = hour(peakTime) + minute(peakTime)/60 + second(peakTime)/3600;
meanPhase     = mean(phaseInHour, 'omitnan');
sdPhase       = std(phaseInHour, 'omitnan');

cycleSD       = std(x(1:ceil(sum(cycleLength(1:minCycle))*3600/epoch)));

verbose = [verbose sprintf('\nTotal %d cycles detected (the first < 1/4 cycle is removed)', minCycle)];

verbose = [verbose ...
    sprintf('\n\nThe cycle lengths are (in hour):\n') ...
    sprintf('\t%s\n', string(cycleLength)) ...
    sprintf('\n\nThe phases are (in hour):\n') ...
    sprintf('\t%s\n', string(phaseInHour)) ...
    sprintf('\n\nThe cycle amplitudes are:\n') ...
    sprintf('\t%s\n', string(cycleAmplitude))];

this.EMDSummary = table(meanAmplitude, sdAmplitude, meanPeriod, sdPeriod, meanPhase, sdPhase, cycleSD);

this.EMDInfo.UserData.Verbose = verbose;
this.EMDInfo.UserData.CycleLength = cycleLength;
this.EMDInfo.UserData.PhaseInHour = phaseInHour;
this.EMDInfo.UserData.CycleAmplitude = cycleAmplitude;

this.message.content = 'EMD analysis is completed.';
this.message.type = 'success';
this.analysis.emd = 1;