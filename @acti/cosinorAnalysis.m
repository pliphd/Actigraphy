function this = cosinorAnalysis(this)
%COSINORANALYSIS Perform cosinor analysis on an ACTI object
% 
% $Author:  Peng Li
% $Date:    Jul 01, 2020
% 

period = this.CosinorInfo.HarmonicsInHour;
minLen = this.CosinorInfo.MinimumLengthInDays;

epoch  = this.Epoch; % in sec
x      = this.Data;
x(this.GapSeries) = nan;

% init
mean_activity = nanmean(x);
std_activity  = nanstd(x);
mesor = nan; p_value = nan; r_squared = nan;
amp = nan(1, numel(period));
pha = amp;
p_h = amp;

if length(x)*epoch/3600 < minLen * period(1)
    this.CosinorSummary = [table(mean_activity, std_activity, mesor, p_value, r_squared) ...
        array2table(amp, 'VariableNames', "amplitude_" + string(period)) ...
        array2table(pha, 'VariableNames', "phase_" + string(period)) ...
        array2table(p_h, 'VariableNames', "phase_" + string(period) + "_in_hour")];
    return;
end

% do
if this.timeSet
    refZeroDegree = datetime(year(this.TimeInfo.StartDate), month(this.TimeInfo.StartDate), day(this.TimeInfo.StartDate), 0, 0, 0);
    tInDegree     = hours((this.TimeInfo.StartDate + seconds(epoch) .* (1:length(this.Data)) - seconds(epoch)) - refZeroDegree) * 15;
else
    tInDegree     = hours(seconds(epoch).*(0:length(this.Data)-1))*15;
end
tInSec = tInDegree * 3600 / 15;

[~, p_value, r_squared, component, ~] = CosAna(x, tInSec, period);

% generate summary
amp = component.AC;
pha = component.theta;
p_h = component.theta ./ 15;
p_h(p_h < 0) = p_h(p_h < 0) + component.FitFreq(p_h < 0);

mesor         = component.const;

this.CosinorSummary = [table(mean_activity, std_activity, mesor, p_value, r_squared) ...
    array2table(amp', 'VariableNames', "amplitude_" + string(period)) ...
    array2table(pha', 'VariableNames', "phase_" + string(period)) ...
    array2table(p_h', 'VariableNames', "phase_" + string(period) + "_in_hour")];