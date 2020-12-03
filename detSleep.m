function [sleep, res, fmt] = detSleep(actigraphy, epoch, varargin)
%DETSLEEP do sleep detection
%   
%   [SLEEP, RES, FMT] = DETSLEEP(ACTIGRAPHY, EPOCH, STARTTIME, QUALITY)
%       performs sleep detection on ACTIGRAPHY of epoch length EPOCH and 
%       return results to the caller
%       FMT request the format to write RES to file
%       SLEEP is the actual sleep episodes to be saved
%
%   $Author:    Peng Li
%   $Date:      Dec 3, 2020
% 

% to be modified
narginchk(4, 4);

startTime  = varargin{1};
a = acti(actigraphy, 'Epoch', epoch, 'StartTime', startTime);
a.GapSeries = ~varargin{2};

a.SleepInfo = struct('StartTime', '21:00', 'EndTime', '7:00', ...
    'ModeParameter', struct('P', 0.001, 'V', [106 54 58 76 230 74 67], 'C', 0));

a = a.sleepDet;

% request results
sleep = a.Sleep;

% request summary results here
res = a.SleepSummary.Report{:, :};
fmt = '%.2f\t%.2f\r';