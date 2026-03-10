function this = gapDet(this)
%GAPDET Automatically identify potential gaps
% 
% $Author:  Peng Li
% $Date:    Feb 25, 2026
% 
params = this.GapInfo.Parameter;
rec = this.Data;
if isempty(rec)
    this.Gap = [];
    return;
end
len = length(rec);
epochSec = this.Epoch;

this.Gap = [];

% 1. Threshold criterion
switch params.ThresholdUnit
    case 'Min'
        gapseries1 = rec <= params.Threshold;
    case 'Max'
        gapseries1 = rec >= params.Threshold;
    case 'Range'
        gapseries1 = rec <= params.Threshold(1) | rec >= params.Threshold(2);
    case 'SD'
        lmean = mean(rec);
        thre = params.Threshold .* std(rec);
        gapseries1 = (abs(rec - lmean) >= thre) & 0; % this needs to be updated later
end

% 2. Duration criterion
if any(gapseries1)
    gapTemp = detConstantOne(gapseries1);
    minDurEpochs = params.MinimumDurationInMin * 60 / epochSec;
    gapTemp(gapTemp(:, 2) - gapTemp(:, 1) < minDurEpochs, :) = [];

    gapseries2 = ~gap2Series(gapTemp, len);

    % Enable adapting in NaN
    gapseries2 = gapseries2 | isnan(rec);

    % 3. Merge
    segs = transSegGap(detConstantOne(gapseries2), len);
    minDistEpochs = params.MergeIfShorterThanInMin * 60 / epochSec;
    merg = segs(:, 2) - segs(:, 1) <= minDistEpochs;
    segs(merg, :) = [];

    % Auto det will clear all cache gaps
    if ~(size(segs, 1) == 1 && all(segs == [1, len]))
        gapTemp = transSegGap(segs, len);
        gapTemp = unique(gapTemp, 'rows');
        [~, ind] = sort(gapTemp(:, 1));
        this.Gap = gapTemp(ind, :);
    end
end

if ~isempty(this.Gap)
    gapDurations = this.Gap(:, 2) - this.Gap(:, 1) + 1;  % in epochs
else
    gapDurations = 0;
end

totalNonwearEpochs = sum(gapDurations);

durationInHour    = len *epochSec / 3600;
nonwearTimeInHour = totalNonwearEpochs * epochSec / 3600;
nonwearPercentage = totalNonwearEpochs / len * 100;

this.GapSummary = table(durationInHour, nonwearTimeInHour, nonwearPercentage, ...
    'VariableNames', {'total_duration_in_hour', 'nonwear_time_in_hour', 'nonwear_percentage'});

this.message.content = 'Auto detection done!';
this.message.type = 'sucess';
end
