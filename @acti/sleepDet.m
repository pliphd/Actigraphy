function this = sleepDet(this)
%SLEEPDET Perform sleep detection on an ACTI object
% 
% $Author: Peng Li
% $Date:   Dec 02, 2020
% 

% time restrition mask
mask = doMask2(length(this.Data), this.Epoch, this.TimeInfo.StartDate, ...
    this.SleepInfo.StartTime, this.SleepInfo.EndTime);
this.SleepSummary.Window = detConstantOne(mask);

% sleep detection
sleepSeries = doSleepDet2(this.Data, this.Epoch, ...
    this.SleepInfo.ModeParameter.V, ...
    this.SleepInfo.ModeParameter.P, ...
    this.SleepInfo.ModeParameter.C);

this.SleepSeries = sleepSeries & mask;
this.Sleep       = detConstantOne(this.SleepSeries);

% summary stat
sumStat = arrayfun(@(x) sleepSum(this.SleepSummary.Window(x, :), ...
    this.SleepSeries, this.GapSeries, this.Epoch), ...
    1:size(this.SleepSummary.Window, 1), ...
    'uni', 0);
reportPerDay = vertcat(sumStat{:});
report = nanmean(reportPerDay, 1);
this.SleepSummary.ReportPerDay = table(reportPerDay(:, 1), reportPerDay(:, 2), ...
    'VariableNames', {'sleep_duration', 'times_awake'});
this.SleepSummary.Report = table(report(1), report(2), ...
    'VariableNames', {'sleep_duration_avg', 'times_awake_avg'});
end

function out = sleepSum(window, sleepSeries, gapSeries, epoch)
curSleep = sleepSeries(window(1):window(2));
curGap   = gapSeries(window(1):window(2));

% if gap percentage is over 40%, skip this night
% otherwise, calculate, then scale the sleep duration based on percentage
% of valid data used
if sum(curGap)/numel(curGap) >= 0.4
    duration = nan;
    awake    = nan;
else
    duration = epoch/3600 * sum(curSleep & ~curGap) * (numel(curGap)/sum(~curGap));
    
    validtim = sum(diff([0; curSleep & ~curGap]) == 1)-1;
    if validtim < 0
        validtim = nan;
    end
    awake = validtim * (numel(curGap)/sum(~curGap));
end
out = [duration awake];
end