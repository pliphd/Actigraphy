function this = sleepDet(this)
%SLEEPDET Perform sleep detection on an ACTI object
% 
% $Author:  Peng Li
% $Date:    Dec 02, 2020
% $Modif.:  May 17, 2021
%               generate window from doMask2 instead of recalculate based
%               on mask series
%           Jun 24, 2021
%               see comments below for summary statics
%           Jun 25, 2021
%               nan gap epochs

x = this.Data;
x(this.GapSeries) = nan;

% time restrition mask
[mask, wind] = doMask2(length(x), this.Epoch, this.TimeInfo.StartDate, ...
    this.SleepInfo.StartTime, this.SleepInfo.EndTime);
this.SleepSummary.Window = wind;

% sleep detection
sleepSeries = doSleepDet2(x, this.Epoch, ...
    this.SleepInfo.ModeParameter.V, ...
    this.SleepInfo.ModeParameter.P, ...
    this.SleepInfo.ModeParameter.C);

this.SleepSeries = sleepSeries & mask;
this.Sleep       = detConstantOne(this.SleepSeries);

% summary stat
% sumStat = arrayfun(@(x) sleepSum(this.SleepSummary.Window(x, :), ...
%     this.SleepSeries, this.GapSeries, this.Epoch), ...
%     1:size(this.SleepSummary.Window, 1), ...
%     'uni', 0);
% reportPerDay = vertcat(sumStat{:});
% report = nanmean(reportPerDay, 1);
% 
% this.SleepSummary.ReportPerDay = table(reportPerDay(:, 1), reportPerDay(:, 2), ...
%     'VariableNames', {'sleep_duration', 'times_awake'});

% comment 6/24/2021
% first, cutting into days needs to consider incomplete days since it
% happens that sleep duration in an incomplete day maybe 0, which biases
% the calculation, should get rid of the incomplete days
% second, considering gaps in sleep duration calculation is tricky too
% since there is no good way to scale it, given the different effects when
% gap presents during sleep or wake hours
% 
% desided to do this easier:
% sleep duration per day = total sleep time / data length
% take gaps out of sleep episodes, and leave exclusion later when
% analyzing the results if too many gaps
% 
% modif. 2021/09/30
%   scale to the actual length of time window for sleep detection, instead
%   of 24 hour
duration = sum(this.SleepSeries) / (length(x) - sum(this.GapSeries)) * hours(this.SleepInfo.EndTime - this.SleepInfo.StartTime);
validtim = sum(diff([0; this.SleepSeries]) == 1)-1;
if validtim < 0
    validtim = nan;
end
awake = validtim / ((length(x) - sum(this.GapSeries)) * this.Epoch / 3600 / hours(this.SleepInfo.EndTime - this.SleepInfo.StartTime));

this.SleepSummary.Report = table(duration, awake, ...
    'VariableNames', {'sleep_duration_avg', 'times_awake_avg'});
end

% function out = sleepSum(window, sleepSeries, gapSeries, epoch)
% curSleep = sleepSeries(window(1):window(2));
% curGap   = gapSeries(window(1):window(2));
% 
% % if gap percentage is over 40%, skip this night
% % otherwise, calculate, then scale the sleep duration based on percentage
% % of valid data used
% if sum(curGap)/numel(curGap) >= 0.4
%     duration = nan;
%     awake    = nan;
% else
%     duration = epoch/3600 * sum(curSleep & ~curGap) * (numel(curGap)/sum(~curGap));
%     
%     validtim = sum(diff([0; curSleep & ~curGap]) == 1)-1;
%     if validtim < 0
%         validtim = nan;
%     end
%     awake = validtim * (numel(curGap)/sum(~curGap));
% end
% out = [duration awake];
% end