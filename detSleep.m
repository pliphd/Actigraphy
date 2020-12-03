function [sleep, res, fmt] = detSleep(actigraphy, epoch, varargin)
%DETSLEEP do sleep detection
%   
%   [SLEEP, RES, FMT] = DETSLEEP(ACTIGRAPHY, EPOCH, STARTTIME, QUALITY, WINDOW, PARAMETER)
%       performs sleep detection on ACTIGRAPHY of epoch length EPOCH and 
%       return results to the caller.
%       FMT request the format to write RES to file
%       SLEEP is the actual sleep episodes to be saved
%
%   $Author:    Peng Li
%   $Date:      Dec 3, 2020
% 

% to be modified
narginchk(6, 6);

startTime  = varargin{1};
a = acti(actigraphy, 'Epoch', epoch, 'StartTime', startTime);
a.GapSeries = ~varargin{2};

window = varargin{3};
para   = varargin{4};

a.SleepInfo = struct('StartTime', window.StartTime, ...
    'EndTime', window.EndTime, ...
    'ModeParameter', para);

a = a.sleepDet;

% request results
sleep = a.Sleep;

% request summary results here
res = a.SleepSummary.Report{:, :};
fmt = '%.2f\t%.2f\r';