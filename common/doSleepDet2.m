function sleepSeries = doSleepDet2(data, epoch, V, P, C)
%DOSLEEPDET2 detect sleep episode in actigraphy DATAINMIN
% 
% REF.: [1] Cole et al. Automatic Sleep/Wake identification From Wrist
%           Activity. SLEEP. 15(5):461-469,1992.
%       [2] Jean-Louis et al. Sleep estimation from wrist movement
%           quantified by different actigraphic modalities. J Neurosci.
%           105:185-191. 2005.
%       [3] Jean-Louis et al. Determination of Sleep and Wakefulness With
%           the Actigraph Data Analysis Software (ADAS). SLEEP.
%           19(9):739-743,1996.
% 
% $Author:  Peng Li
% $Date:    Jan 09, 2020
% $Modif.:  Feb 10, 2020
%               parse data length before rescale, and refine series length
%               based on rescale factor and original data length
%           Apr 07, 2020
%               refined rescoring criterion -- instead of being applied
%               sequentially, apply them to the orignal results
%               simultaneously
%           Dec 02, 2020
%               incorporate gap info so remove off-wrist detection
%           Apr 22, 2021
%               add options to prevent empty sleepEpi
% 

rescale = 60 / epoch;
switch rescale
    case {4, 2}
        tempLen = floor(length(data) / rescale) * rescale;
        if tempLen == length(data)
            rec1 = nanmean(reshape(data, rescale, []), 1)';
        else
            res  = nanmean(data(tempLen+1:end));
            rec1 = [nanmean(reshape(data(1:tempLen), rescale, []), 1)'; res(:)];
        end
    case 3
        return; % do nothing at this moment, to interp later
    case 1
        rec1 = data;
end

%% padding to enable scoring of the head and tail (usually 4 min head and 2
% min tail)
rec2   = [rec1(1:4); rec1; rec1(end:-1:end-1)];

%% major step: scoring
N      = length(rec2) - 6;
ind    = hankel(1:N, N:length(rec2));
recMat = rec2(ind);
D      = recMat * V(:) .* P + C;

sleepSeries = D < 1;

%% rescoring
% April 7, 2020
% revise to apply rules simultaneously

wakeEpi = detConstantOne(~sleepSeries);

% wake series original
wakeSeriesOrig   = seg2Series(wakeEpi, length(sleepSeries));

% a) after at least 4 minutes scored as wake, the next 1 minute scored as sleep is rescored wake
wakeEpi(wakeEpi(:, 2) - wakeEpi(:, 1) >= 4, 2) = wakeEpi(wakeEpi(:, 2) - wakeEpi(:, 1) >= 4, 2) + 1;
wakeEpi(wakeEpi(:, 2) > length(sleepSeries), 2) = length(sleepSeries);

% wake series a
wakeSeriesAfterA = seg2Series(wakeEpi, length(sleepSeries));

% b) after at least 10 minutes scored as wake, the next 3 minutes scored as sleep are rescored wake
wakeEpi    = detConstantOne(~sleepSeries);
wakeEpi(wakeEpi(:, 2) - wakeEpi(:, 1) >= 10, 2) = wakeEpi(wakeEpi(:, 2) - wakeEpi(:, 1) >= 10, 2) + 3;
wakeEpi(wakeEpi(:, 2) > length(sleepSeries), 2) = length(sleepSeries);

% wake series b
wakeSeriesAfterB = seg2Series(wakeEpi, length(sleepSeries));

% c) after at least 15 minutes scored as wake, the next 4 minutes scored as sleep are rescored wake
wakeEpi    = detConstantOne(~sleepSeries);
wakeEpi(wakeEpi(:, 2) - wakeEpi(:, 1) >= 15, 2) = wakeEpi(wakeEpi(:, 2) - wakeEpi(:, 1) >= 15, 2) + 4;
wakeEpi(wakeEpi(:, 2) > length(sleepSeries), 2) = length(sleepSeries);

% wake series c
wakeSeriesAfterC = seg2Series(wakeEpi, length(sleepSeries));

% d) 6 minutes or less scored as sleep surrounded by >=10 minutes (before and after) scored as wake are rescored wake 

wakeEpi    = detConstantOne(~sleepSeries);
sleepEpi   = detConstantOne(sleepSeries);

if ~isempty(sleepEpi)
    if sleepEpi(1, 1) == 1
        wakeEpi = [0 1; wakeEpi]; % disrecard first sleep episode if no wake episode before it, do nothing
    end
    if sleepEpi(end, 2) == length(sleepSeries)
        wakeEpi = [wakeEpi; 0 1]; % disrecard last sleep episode if no wake episode after it, do nothing
    end
    
    merg = sleepEpi(:, 2) - sleepEpi(:, 1) <= 6 & (wakeEpi(1:end-1, 2) - wakeEpi(1:end-1, 1) + wakeEpi(2:end, 2) - wakeEpi(2:end, 1) >= 10);
    sleepEpi(merg, :) = [];
end

% wake series d
wakeSeriesAfterD = ~seg2Series(sleepEpi, length(sleepSeries));

% e) 10 minutes or less scored as sleep surrounded by >=20 minutes (before and after) scored as wake are rescored wake
sleepEpi    = detConstantOne(sleepSeries);
wakeEpi     = detConstantOne(~sleepSeries);

if ~isempty(sleepEpi)
    if sleepEpi(1, 1) == 1
        wakeEpi = [0 1; wakeEpi]; % disrecard first sleep episode if no wake episode before it, do nothing
    end
    if sleepEpi(end, 2) == length(sleepSeries)
        wakeEpi = [wakeEpi; 0 1]; % disrecard last sleep episode if no wake episode after it, do nothing
    end
    
    merg = sleepEpi(:, 2) - sleepEpi(:, 1) <= 10 & (wakeEpi(1:end-1, 2) - wakeEpi(1:end-1, 1) + wakeEpi(2:end, 2) - wakeEpi(2:end, 1) >= 20);
    sleepEpi(merg, :) = [];
end

% wake series e
wakeSeriesAfterE = ~seg2Series(sleepEpi, length(sleepSeries));

wakeSeriesFinal  = wakeSeriesOrig | wakeSeriesAfterA | ...
    wakeSeriesAfterB | wakeSeriesAfterC | wakeSeriesAfterD | wakeSeriesAfterE;

wakeEpi = detConstantOne(wakeSeriesFinal);

% 2021-12-02 disable the following criterion
% %% wake interval post arousal: 3 min as the criterion
% merg    = wakeEpi(:, 2) - wakeEpi(:, 1) <= 3;
% wakeEpi(merg, :) = [];

sleepEpi = transSegGap(wakeEpi, length(sleepSeries));

% %% potential off-wrist episodes
% % disabled--to incorporate gap
% offWCand = [];
% tempInd  = find(sleepEpi(:, 2) - sleepEpi(:, 1) >= offWristThreInHour * 60);
% if ~isempty(tempInd)
%     for iO = 1:length(tempInd)
%         if nansum(rec1((sleepEpi(tempInd(iO), 1)+5):(sleepEpi(tempInd(iO), 2)-5))) < 10
%             offWCand = [offWCand; tempInd(iO)];
%         end
%     end
% end
% if ~isempty(offWCand)
%     sleepEpi(offWCand, :) = [];
% end

%% sleep/wake indicator
sleepSeries = seg2Series(sleepEpi, length(sleepSeries));

switch rescale
    case {4, 2}
        sleepSeries = reshape(repmat(sleepSeries', rescale, 1), [], 1);
        if tempLen < length(data)
            sleepSeries(end-(length(sleepSeries)-length(data))+1:end) = [];
        end
end