function this = m10l5Analysis(this)
%M10L5ANALYSIS Perform nonparametric M10 and L5 analysis on an ACTI object
% 
% $Author:  Peng Li
% $Date:    Jun 15, 2020
% 

x      = this.Data;
x(this.GapSeries) = nan;

if ~this.timeSet
    error('nonparametric:M10L5:actual time is required to perform M10 and L5');
else
    missingHDuration = this.TimeInfo.StartDate - datetime(year(this.TimeInfo.StartDate), month(this.TimeInfo.StartDate), day(this.TimeInfo.StartDate));
    
    endDate          = this.TimeInfo.StartDate + feval(this.TimeInfo.Units, this.TimeInfo.End);
    missingTDuration = datetime(year(endDate), month(endDate), day(endDate)+1) - endDate;
    
    xExt = [nan(seconds(missingHDuration)/this.Epoch, 1); x; nan(seconds(missingTDuration)/this.Epoch-1, 1)];
    
    xPerDay = reshape(xExt, 24*60*60/this.Epoch, []);
    
    out = arrayfun(@(x) eachDay(xPerDay(:, x), this.Epoch), 1:size(xPerDay, 2), 'UniformOutput', false);
    
    m10l5 = nanmean(vertcat(out{:}), 1);
    
    this.M10L5Summary = array2table(m10l5, 'VariableNames', {'m10', 'm10_mid_time', 'l5', 'l5_mid_time'});
end
end

function out = eachDay(x, epoch) 
    % if over 50% gap, do nothing
    if sum(isnan(x))/numel(x) > 0.5
        out = [nan nan nan nan];
        return;
    end
    
    % M10
    xBuffer10  = buffer(x, 10*60*60/epoch, 10*60*60/epoch-1, 'nodelay');
    index10    = 1:size(xBuffer10, 2);
    
    % if 50% more nan, remove the vector
    indNan     = nansum(isnan(xBuffer10), 1)/size(xBuffer10, 1) > 0.5;
    xBuffer10(:, indNan) = [];
    index10(indNan)      = [];
    
    hourlyMean = nansum(xBuffer10, 1)/10;
    [m10, t10] = max(hourlyMean);
    t10m = index10(t10)*epoch/3600 + 5;
    
    % L5
    xBuffer5   = buffer(x, 5*60*60/epoch, 5*60*60/epoch-1, 'nodelay');
    index5     = 1:size(xBuffer5, 2);
    
    % if 50% more nan, remove the vector
    indNan     = nansum(isnan(xBuffer5), 1)/size(xBuffer5, 1) > 0.5;
    xBuffer5(:, indNan) = [];
    index5(indNan)      = [];
    
    hourlyMean = nansum(xBuffer5, 1)/5;
    [l5, t5]   = min(hourlyMean);
    t5m = index5(t5)*epoch/3600 + 2.5;
    
    out = [m10, t10m, l5, t5m];
end