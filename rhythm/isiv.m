function [IS, IV, xPeriod, PercMissingData, PercMissingBin] = isiv(x, epoch, scale, period, varargin)
%ISIV inter-daily stability and intra-daily variability for locomotor activity data
% 
% epoch:  sampling time (in min)
% scale:  at what scale IS and IV are estimated (in min)
% period: a range (in hr) used for searching the period of input data
% varargin:
%           {1} fixed data length in cycle
% 
% Ref. 
%      Witting W, et al. Alterations in the circadian rest-activity rhythm
% in aging and Alzheimer's disease. Biol. Psychiatry 1990, 27: 563-572.
% 
% $Author:  Peng Li, Ph.D.
%           Division of Sleep Medicine, Harvard Medical School
%           Division of Sleep and Circadian Disorders, Brigham and Womens's Hospital
% $Date:    Mar 11, 2016
% $Modif.:  Aug 05, 2016
%                Add condition to determine if a long segment has been cut
%                from the very begining or the end of the recording which
%                might affect the isiv calculation
%           Nov 14, 2016
%                Resample data conditionally according to new epoch
%                required
%           Nov 22, 2016
%                Disable the change on Aug 05
%                because actually only the segment used for analysis is
%                inputted into this subroutine
%           Dec 08, 2016
%                Update the strategy to calculate IS and IV
%                Output percentage of missing data and percentage of missing bins
%           Jun 18, 2021
%                add parameter for fixed data length analysis
%                if cycle number < varargin{1}, do not perform the analysis
%           Set 18, 2023
%                default fixedCycle should be greater than 1 (which was
%                initially set at 1, resulting in IS being always 1)
% 

% parse input
% tba
if nargin == 5
    fixedCycle = varargin{1};
else
    fixedCycle = 7;
end

x = x(:);

if isscalar(period)
    xPeriod    = period;
else
    Resolution = 0.01;            % in hr
    xPeriod    = period(1):Resolution:period(2);
end

P = floor(24*60./scale); % number of episode

IS               = nan(length(xPeriod), 1);
IV               = IS;
PercMissingData  = IS;
PercMissingBin   = IS;
for iX           = 1:length(xPeriod)
    Point1hrActu = ceil(xPeriod(iX)/P*60/epoch); % actual points in 1 episode corresponding to the specific period
    newepoch     = xPeriod(iX)/P*60/Point1hrActu;
    
    if newepoch  == epoch
        newx = x;
    else
        newx = interp1(0:epoch:(length(x)-1)*epoch, x, 0:newepoch:(length(x)-1)*epoch, 'linear');
    end
    
    if numel(newx) < Point1hrActu * P * fixedCycle
        continue;
    else
        newx = newx(1:Point1hrActu * P * fixedCycle);
    end
    
    numOfHr  = floor(length(newx) / Point1hrActu);
    transHr  = reshape(newx(1:numOfHr*Point1hrActu), Point1hrActu, numOfHr);
    
    %{
    % condition: if nan exists the whole hour at the very begining or the
    % end, it means these parts are actually cut off from analysis
    if isvector(transHr)
        transTemp = transHr;
        transTemp = reshape(transTemp(1:floor(length(transTemp)/2)*2), 2, []);
        HeadEndCut = all(isnan(transTemp));
        Head       = find(HeadEndCut == 0, 1, 'first');
        End        = find(HeadEndCut == 0, 1, 'last');
        transTemp  = transTemp(:, Head:End);
        if isnan(transTemp(1))
            transTemp(1) = [];
        end
        if isnan(transTemp(end))
            transTemp(end) = [];
        end
        transHr    = transTemp(:)';
    else   
        HeadEndCut = all(isnan(transHr));
        Head       = find(HeadEndCut == 0, 1, 'first');
        End        = find(HeadEndCut == 0, 1, 'last');
        transHr    = transHr(:, Head:End);
    end
    %}
    
    HrTally             = nanmean(transHr, 1);
    N                   = length(HrTally);
    PercMissingData(iX) = sum(isnan(HrTally)) / N;
    
    K                   = floor(N/P);
    transKP             = reshape(HrTally(1:K*P), P, K)';
    PercMissingBin(iX)  = sum(all(isnan(transKP), 1)) / P;
    
    OneHrMean = nanmean(transKP, 1);
    GlobalMn  = nanmean(OneHrMean);
    
    % Qp        = P*K^2*nansum((OneHrMean - GlobalMn).^2) / nansum((transKP(:) - GlobalMn).^2);
    % IS(iX)    = Qp / (P*K);
    %
    % IV(iX)    = P*K*nansum(diff(HrTally).^2) / ((P*K-1)*nansum((GlobalMn - HrTally).^2));
    % 
    % % old version is biased when large portion of gap exists
    
    IS(iX)    = nanmean((OneHrMean - GlobalMn) .^ 2) / nanmean((transKP(:) - GlobalMn) .^ 2);
    IV(iX)    = nanmean(diff(HrTally).^2) / nanmean((GlobalMn - HrTally).^2);
end