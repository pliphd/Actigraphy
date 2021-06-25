function this = m10l5Analysis(this)
%M10L5ANALYSIS Perform nonparametric M10 and L5 analysis on an ACTI object
% 
% $Author:  Peng Li
% $Date:    Jun 15, 2021
% $Modif.:  Jun 25, 2021
%               instead of calculating per day, average the days first
%               see comment where revised
% 

x      = this.Data;
x(this.GapSeries) = nan;

m10 = nan; t10m = nan;
l5  = nan; t5m  = nan;

if ~this.timeSet
    this.M10L5Summary = table(m10, t10m, l5, t5m, 'VariableNames', {'m10', 'm10_mid_time', 'l5', 'l5_mid_time'});
    % error('nonparametric:M10L5:actual time is required to perform M10 and L5');
else
    missingHDuration = this.TimeInfo.StartDate - datetime(year(this.TimeInfo.StartDate), month(this.TimeInfo.StartDate), day(this.TimeInfo.StartDate));
    
    endDate          = this.TimeInfo.StartDate + feval(this.TimeInfo.Units, this.TimeInfo.End);
    missingTDuration = datetime(year(endDate), month(endDate), day(endDate)+1) - endDate;
    
    xExt = [nan(seconds(missingHDuration)/this.Epoch, 1); x; nan(seconds(missingTDuration)/this.Epoch-1, 1)];
    
    xPerDay = reshape(xExt, 24*60*60/this.Epoch, []);
    
    % revision 6/25/2021
    % may not be a good choise to do per day since the cut off time 00:00
    %   makes the L5 unreliable
    % average the days first and use 24 hours to recalculate
    % 
    % 
    % out = arrayfun(@(x) eachDay(xPerDay(:, x), this.Epoch), 1:size(xPerDay, 2), 'UniformOutput', false);
    % 
    % m10l5 = nanmean(vertcat(out{:}), 1);
    
    x24 = nanmean(xPerDay, 2);
    
    % extend data before buffering
    x24loop = [x24; x24; x24];
    
    % M10
    frameLen   = 10*60*60/this.Epoch;
    xBuffer10  = buffer(x24loop, frameLen, frameLen-1, 'nodelay');
    
    % select actual data area
    % for length N signal to buffer frames of length m
    %   there should be N-m+1 frames
    % offset further m/2 frames to move the first point in middle of the
    %   frame
    startInd   = numel(x24) - frameLen + 1 + floor(frameLen/2);
    endInd     = startInd + numel(x24) - 1;
    
    xBuffer10  = xBuffer10(:, startInd:endInd);
    index10    = 1:size(xBuffer10, 2);
    
    hourlyMean = nanmean(xBuffer10, 1) * (10*3600/this.Epoch);
    [m10, t10] = max(hourlyMean);
    t10m = index10(t10)*this.Epoch/3600;
    
    % L5
    frameLen   = 5*60*60/this.Epoch;
    xBuffer5   = buffer(x24loop, frameLen, frameLen-1, 'nodelay');
    
    % select actual data area
    % for length N signal to buffer frames of length m
    %   there should be N-m+1 frames
    % offset further m/2 frames to move the first point in middle of the
    %   frame
    startInd   = numel(x24) - frameLen + 1 + floor(frameLen/2);
    endInd     = startInd + numel(x24) - 1;
    
    xBuffer5   = xBuffer5(:, startInd:endInd);
    index5     = 1:size(xBuffer5, 2);
    
    hourlyMean = nanmean(xBuffer5, 1) * (5*3600/this.Epoch);
    [l5, t5]   = min(hourlyMean);
    t5m = index5(t5)*this.Epoch/3600;
    
    if isempty(m10),  m10  = nan; end
    if isempty(t10m), t10m = nan; end
    if isempty(l5),   l5   = nan; end
    if isempty(t5m),  t5m  = nan; end
    
    this.M10L5Summary = table(m10, t10m, l5, t5m, 'VariableNames', {'m10', 'm10_mid_time', 'l5', 'l5_mid_time'});
end
end

% function out = eachDay(x, epoch) 
%     % if over 50% gap, do nothing
%     if sum(isnan(x))/numel(x) > 0.5
%         out = [nan nan nan nan];
%         return;
%     end
%     
%     % M10
%     xBuffer10  = buffer(x, 10*60*60/epoch, 10*60*60/epoch-1, 'nodelay');
%     index10    = 1:size(xBuffer10, 2);
%     
%     % if 50% more nan, remove the vector
%     indNan     = nansum(isnan(xBuffer10), 1)/size(xBuffer10, 1) > 0.5;
%     xBuffer10(:, indNan) = [];
%     index10(indNan)      = [];
%     
%     hourlyMean = nansum(xBuffer10, 1)/10;
%     [m10, t10] = max(hourlyMean);
%     t10m = index10(t10)*epoch/3600 + 5;
%     
%     % L5
%     xBuffer5   = buffer(x, 5*60*60/epoch, 5*60*60/epoch-1, 'nodelay');
%     index5     = 1:size(xBuffer5, 2);
%     
%     % if 50% more nan, remove the vector
%     indNan     = nansum(isnan(xBuffer5), 1)/size(xBuffer5, 1) > 0.5;
%     xBuffer5(:, indNan) = [];
%     index5(indNan)      = [];
%     
%     hourlyMean = nansum(xBuffer5, 1)/5;
%     [l5, t5]   = min(hourlyMean);
%     t5m = index5(t5)*epoch/3600 + 2.5;
%     
%     out = [m10, t10m, l5, t5m];
% end