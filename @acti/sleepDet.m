function this = sleepDet(this)
%SLEEPDET Perform sleep detection on an ACTI object
% 
% $Author:  Peng Li
% $Date:    Dec 02, 2020
% $Modif.:  May 17, 2021
%               generate window from doMask2 instead of recalculate based
%               on mask series
%           Jun 24, 2021
%               see comments below for summary statics
%           Jun 25, 2021
%               nan gap epochs
%           Jan 04, 2024
%               allow Actiware sleep detection approach
%           Jan 30, 2024
%               revise algorithms for calc. of waso and times awake
%           Oct 15, 2025
%               add post-hoc sleep episode clean-up based on Option field
%               clean up summary stat based on what are actually calculated
%               some summary stat do not make sense for nap, 24-h sleep, or
%                   nocturnal sleep

x   = this.Data;
len = length(x);
x(this.GapSeries) = nan;

% time restrition mask
[mask, wind, maskLength] = doMask2(len, this.Epoch, this.TimeInfo.StartDate, ...
    this.SleepInfo.StartTime, this.SleepInfo.EndTime);
this.SleepSummary.Window = wind;

% sleep detection
switch this.SleepInfo.Method
    case 'Cole-Kripke'
        sleepSeries = doSleepDet2(x, this.Epoch, ...
            this.SleepInfo.ModeParameter.V, ...
            this.SleepInfo.ModeParameter.P, ...
            this.SleepInfo.ModeParameter.C);
    case 'Actiware'
        sleepSeries = doSleepDetActiware(x, this.Epoch, this.SleepInfo.ModeParameter.T);
end

this.SleepSeries = sleepSeries & mask;

% post-hoc clean-up request
sleepEpi = detConstantOne(this.SleepSeries);

switch this.SleepInfo.Option
    case 'Nap 5min+'
        sleepEpi((sleepEpi(:, 2) - sleepEpi(:, 1) + 1) * this.Epoch < 5*60, :) = [];
end

this.Sleep = sleepEpi;

% Summary statistics
% 1. duration
duration = sum(seg2Series(sleepEpi, len)) / len * 24;

% 2. frequency, times awake and waso
switch this.SleepInfo.Option
    case 'Nocturnal'
        % frequency not calculated for nocturnal sleep
        % waso and times awake make more sense for nocturnal sleep
        sleepFreq = nan;

        % times awake and waso
        awake_w = zeros(numel(wind), 1);
        waso_w  = awake_w;
        for iW  = 1:size(wind, 1)
            sleepSeries_w = sleepSeries(wind(iW, 1):wind(iW, 2));
            awakeEpi_w    = detConstantOne(~sleepSeries_w);

            if isempty(awakeEpi_w)
                awake_w(iW) = 0;
                waso_w(iW)  = 0;
            else
                if size(awakeEpi_w, 1) == 1
                    if awakeEpi_w(1, 1) == 1 || awakeEpi_w(1, 2) == wind(iW, 2)-wind(iW, 1)+1
                        awake_w(iW) = 0;
                        waso_w(iW)  = 0;
                    else
                        awake_w(iW) = 1;
                        waso_w(iW)  = awakeEpi_w(1, 2) - awakeEpi_w(1, 1) + 1;
                    end
                else
                    % if first awake start from first index of wind(iW), it's considered
                    % not getting into bed yet, need to get rid
                    if awakeEpi_w(1, 1) == 1
                        awakeEpi_w(1, :) = [];
                    end
                    % if last awake end with last index of wind(iW), it's considered
                    % getup already, need to get rid
                    if awakeEpi_w(end, 2) == wind(iW, 2)-wind(iW, 1)+1
                        awakeEpi_w(end, :) = [];
                    end

                    if isempty(awakeEpi_w)
                        awake_w(iW) = 0;
                        waso_w(iW)  = 0;
                    else
                        awake_w(iW) = size(awakeEpi_w, 1);
                        waso_w(iW)  = sum(awakeEpi_w(:, 2) - awakeEpi_w(:, 1) + 1);
                    end
                end
            end
        end
        awake = sum(awake_w, 'omitnan') / len * 24 * 3600 / this.Epoch;
        waso  = sum(waso_w, 'omitnan') / len * 24 * 60;
    case 'Nap 5min+'
        awakeEpi = transSegGap(this.Sleep, len);

        % old criterion applied here: if < 3 min, treat as belonging to the same
        % nap (when calculate nap frequency)
        awakeEpi3 = awakeEpi;
        merg      = awakeEpi3(:, 2) - awakeEpi3(:, 1) <= 3;
        awakeEpi3(merg, :) = [];
        sleepFreq = (size(awakeEpi3, 1) + 1) / len * 24 * 3600 / this.Epoch;

        awake = nan;
        waso  = nan;
    case '24 h'
        sleepFreq = nan;
        awake     = nan;
        waso      = nan;
end

this.SleepSummary.Report = table(duration, sleepFreq, awake, waso, ...
    'VariableNames', {'sleep_duration_avg', 'sleep_frequency_avg', 'times_awake_avg', 'waso_avg_in_min'});
end