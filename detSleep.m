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
%   $Modif.:    Apr 22, 2021
%                   restricted to at least 2 days of data
%               Jun 24, 2021
%                   adapt results and format to changes in summary sleep
%                   statics changes
%               Feb 01, 2024
%                   adapt SleepInfo to the new SleepInfo struct with Method
%                   field
% 

% to be modified
narginchk(6, 6);

if length(actigraphy)*epoch / 3600 / 24 >= 2
    startTime  = varargin{1};
    a = acti(actigraphy, 'Epoch', epoch, 'StartTime', startTime);
    a.GapSeries = ~varargin{2};
    
    window = varargin{3};
    para   = varargin{4};
    
    a.SleepInfo = struct('StartTime', window.StartTime, ...
        'EndTime', window.EndTime, ...
        'ModeParameter', para.ModeParameter, ...
        'Method', para.Method);
    
    a = a.sleepDet;
    
    % request results
    sleep = a.Sleep;
    
    % request summary results here
    res = a.SleepSummary.Report{:, :};
else
    sleep = [nan nan];
    res   = [nan nan nan nan];
end
fmt = '%f\t%f\t%f\t%f\n';