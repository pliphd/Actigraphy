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
% 

% time restrition mask
[mask, wind] = doMask2(length(this.Data), this.Epoch, this.TimeInfo.StartDate, ...
    this.SleepInfo.StartTime, this.SleepInfo.EndTime);
this.SleepSummary.Window = wind;

% sleep detection
sleepSeries = doSleepDet2(this.Data, this.Epoch, ...
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

duration_gap_out = sum(this.SleepSeries & ~this.GapSeries) / length(this.Data) * 24;
duration         = sum(this.SleepSeries)                   / length(this.Data) * 24;

validtim = sum(diff([0; this.SleepSeries & ~this.GapSeries]) == 1)-1;
if validtim < 0
    validtim = nan;
end
awake_gap_out = validtim / (length(this.Data) * this.Epoch / 3600 / 24);

validtim = sum(diff([0; this.SleepSeries]) == 1)-1;
if validtim < 0
    validtim = nan;
end
awake = validtim / (length(this.Data) * this.Epoch / 3600 / 24);

this.SleepSummary.Report = table(duration_gap_out,awake_gap_out, duration, awake, ...
    'VariableNames', {'sleep_duration_gap_out_avg', 'times_awake_gap_out_avg', 'sleep_duration_avg', 'times_awake_avg'});
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