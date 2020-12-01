function [gap, res, fmt] = calGap(actigraphy, epoch, quality)
%CALGAP calculate gap percentage from gap file
%   
%   GAP = CALGAP(ACTIGRAPHY, EPOCH, QUALITY)
%
%   $Author:    Peng Li
% 

gapseries = ~quality;

if any(gapseries)
    gap = DetConstantOne(gapseries);
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
fmt = '%d\t%.2f\r';