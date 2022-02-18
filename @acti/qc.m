function this = qc(this)
%QC qc an ACTI object
% 
% $Author: Peng Li
% $Date:   Feb 07, 2022
% 

len = length(this.Data);
qcMessage = "";

%% 1: consistant off-wrist during nighttime
% time restrition mask between 21:00 and 7:00
[~, ind] = doMask2(len, this.Epoch, this.TimeInfo.StartDate, ...
    '21:00', '7:00');

maxZeroSeg = splitapply(@(x) contZero(this.Data, x, this.Epoch), ind, (1:size(ind, 1))');

offWristPortion = maxZeroSeg ./ (10*3600/this.Epoch);

if sum(offWristPortion > 0.5) / numel(offWristPortion) > 0.5
    offWristFlag   = 1;
    qcMessage      = qcMessage + "off-wrist during nighttime; ";
else
    offWristFlag   = 0;
end

%% 2: failure days senario 1
pointsPer24 = 24*3600 / this.Epoch;

if len > pointsPer24
    dataPerDay  = reshape(this.Data(1:pointsPer24*floor(len/pointsPer24)), pointsPer24, []);
else
    dataPerDay  = this.Data;
end

maxBelow10 = splitapply(@(x) below10(x, this.Epoch), dataPerDay, 1:size(dataPerDay, 2));

failedPortion = maxBelow10 ./ pointsPer24;
if sum(failedPortion > 0.5) / numel(failedPortion) > 0.5
    failureDaysFlag = 1;
    qcMessage       = qcMessage + "device failure (continuous below 10 for too long); ";
else
    failureDaysFlag = 0;
end

%% 3: failure days senario 2
maxActive = splitapply(@(x) active(x, this.Epoch), dataPerDay, 1:size(dataPerDay, 2));

activePortion = maxActive ./ pointsPer24;
if sum(activePortion > 0.5) / numel(activePortion) > 0.5
    activeDaysFlag = 1;
    qcMessage      = qcMessage + "device failure (continuous no zeros for too long); ";
else
    activeDaysFlag = 0;
end

%% 4: failure days senario 3 1+2
if ~failureDaysFlag && ~activeDaysFlag
    maxBelow10 = splitapply(@(x) below10(x, this.Epoch), dataPerDay, 1:size(dataPerDay, 2));
    maxActive  = splitapply(@(x) active(x, this.Epoch), dataPerDay, 1:size(dataPerDay, 2));

    maxMix = max([maxBelow10(:) maxActive(:)], [], 2);

    activeOrFailurePortion = maxMix ./ pointsPer24;
    if sum(activeOrFailurePortion > 0.5) / numel(activeOrFailurePortion) > 0.5
        activeOrFailureDaysFlag = 1;
        qcMessage               = qcMessage + "device failure (mixed days with majority below 10 or no zeros); ";
    else
        activeOrFailureDaysFlag = 0;
    end
end

qcPass = ~(offWristFlag || failureDaysFlag || activeDaysFlag || activeOrFailureDaysFlag);

this.QCimpression.pass    = qcPass;
this.QCimpression.message = qcMessage;
end

function zeroLenMax = contZero(sig, ind, epoch)
ts  = sig(ind(1):ind(2));
tf  = ts == 0 | isnan(ts);
seg = detConstantOne(tf);

zeroLen = seg(:, 2) - seg(:, 1);
zeroLen(zeroLen < 2*3600/epoch) = [];

zeroLenMax = sum(zeroLen);

if isempty(zeroLenMax)
    zeroLenMax = 0;
end
end

function below10Max = below10(sigPerDay, epoch)
tf  = sigPerDay <= 10 | isnan(sigPerDay);
seg = detConstantOne(tf);

below10 = seg(:, 2) - seg(:, 1);
below10(below10 < 2*3600/epoch) = [];

below10Max = sum(below10);

if isempty(below10Max)
    below10Max = 0;
end
end

function activeMax = active(sigPerDay, epoch)
tf  = sigPerDay > 0;
seg = detConstantOne(tf);

act = seg(:, 2) - seg(:, 1);
act(act < 2*3600/epoch) = [];

activeMax = sum(act);

if isempty(activeMax)
    activeMax = 0;
end
end