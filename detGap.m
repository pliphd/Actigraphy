function [gap, res, fmt] = detGap(actigraphy, epoch)
%DETGAP detection gap
%   
%   GAP = DETGAP(ACTIGRAPHY, EPOCH) detects gaps in ACTIGRAPHY with epoch
%       length EPOCH second
%
%   $Author:    Peng Li
% 

minDuration = 60 / epoch * 60 * 2;
gapseries   = actigraphy <= 0;

if any(gapseries)
    gap = detConstantOne(gapseries);
    gap(gap(:, 2) - gap(:, 1) < minDuration, :) = [];
else
    gap = [];
end

% request results
aLenInDay = round(length(actigraphy) * epoch / 60 / 60 / 24);

if ~isempty(gap)
    gapPerc = sum(gap(:, 2) - gap(:, 1) + 1) / length(actigraphy);
else
    gapPerc = 0;
end

res = [aLenInDay, gapPerc];
fmt = '%d\t%.2f\n';