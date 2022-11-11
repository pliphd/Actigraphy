function this = cosinorActi(this)
%COSINORACTI Perform cosinor analysis on an ACTI object
% based on cosinor class methods
% 
% $Author:  Peng Li
% $Date:    Nov 11, 2022
% 

period = this.CosinorInfo.HarmonicsInHour;
minLen = this.CosinorInfo.MinimumLengthInDays;
alpha  = this.CosinorInfo.CIAlpha;

epoch  = this.Epoch; % in sec
x      = this.Data;
x(this.GapSeries) = nan;

% init
mean_activity = mean(x, 'omitnan');
std_activity  = std(x, 'omitnan');

mesor    = nan;
mesor_lb = nan;
mesor_ub = nan;

amp    = nan(1, numel(period));
amp_lb = amp;
amp_ub = amp;

pha    = amp;
pha_lb = pha;
pha_ub = pha;

p_h    = amp;
p_h_lb = p_h;
p_h_ub = p_h;

p_value   = nan;
r_squared = nan;

if length(x)*epoch/3600 < minLen * period(1)
    this.CosinorSummary = [table(mean_activity, std_activity, mesor, mesor_lb, mesor_ub, p_value, r_squared) ...
        array2table(amp,    'VariableNames', "amplitude_" + string(period)) ...
        array2table(amp_lb, 'VariableNames', "amplitude_lb_" + string(period)) ...
        array2table(amp_ub, 'VariableNames', "amplitude_ub_" + string(period)) ...
        array2table(pha,    'VariableNames', "phase_" + string(period)) ...
        array2table(pha_lb, 'VariableNames', "phase_lb_" + string(period)) ...
        array2table(pha_ub, 'VariableNames', "phase_ub_" + string(period)) ...
        array2table(p_h,    'VariableNames', "phase_" + string(period) + "_in_hour") ...
        array2table(p_h_lb, 'VariableNames', "phase_lb_" + string(period) + "_in_hour") ...
        array2table(p_h_ub, 'VariableNames', "phase_ub_" + string(period) + "_in_hour")];
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

if this.timeSet
    tSec = tInSec - tInSec(1);
else
    tSec = tInSec;
end

c = cosinor(x, tSec, ...
    'CycleLengthInHour', period, ...
    'alpha', alpha);

if this.timeSet
    c.StartDateTime = this.TimeInfo.StartDate;
end

c = c.fit;

p_value   = c.pValue;
r_squared = c.R2;

c = c.ci;

% backup c
this.CosinorInfo.UserData = c;

amp    = c.Amplitude;
amp_lb = c.AmplitudeCI(:, 1);
amp_ub = c.AmplitudeCI(:, 2);

pha    = c.Acrophase;
pha_lb = c.AcrophaseCI(:, 1);
pha_ub = c.AcrophaseCI(:, 2);

p_h    = c.Acrophase ./ 360 .* period(:);
p_h_lb = c.AcrophaseCI(:, 1) ./ 360 .* period(:);
p_h_ub = c.AcrophaseCI(:, 2) ./ 360 .* period(:);

mesor    = c.Mesor;
mesor_lb = c.MesorCI(1);
mesor_ub = c.MesorCI(2);

this.CosinorSummary = [table(mean_activity, std_activity, mesor, mesor_lb, mesor_ub, p_value, r_squared) ...
    array2table(amp',    'VariableNames', "amplitude_" + string(period)) ...
    array2table(amp_lb', 'VariableNames', "amplitude_lb_" + string(period)) ...
    array2table(amp_ub', 'VariableNames', "amplitude_ub_" + string(period)) ...
    array2table(pha',    'VariableNames', "phase_" + string(period)) ...
    array2table(pha_lb', 'VariableNames', "phase_lb_" + string(period)) ...
    array2table(pha_ub', 'VariableNames', "phase_ub_" + string(period)) ...
    array2table(p_h',    'VariableNames', "phase_" + string(period) + "_in_hour") ...
    array2table(p_h_lb', 'VariableNames', "phase_lb_" + string(period) + "_in_hour") ...
    array2table(p_h_ub', 'VariableNames', "phase_ub_" + string(period) + "_in_hour")];