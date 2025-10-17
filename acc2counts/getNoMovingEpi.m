function [consDat, errorMsg, success] = getNoMovingEpi(datTT, fs, thre, minLenghNoMoving)
%GETNOMOVINGEPI identify episodes from 3-D accelerometer signals DATTT that
% correspond to when users do not move (less likely to be moving)
% 
% INPUTS
%   DATTT:              3-D accelerometer data, unit g, N by 3 timetable
%   FS:                 Sampling frequency of accelerometer data, unit Hz
%   THRE:               Threshold for identifying no moving period, unit g
%   MINLENGTHNOMOVING:  Minimal duration of episode, unit sec
% 
% OUTPUTS
%   CONSDAT:            Accelerometer data episodes identified from DATTT
%                       Averaged per second to remove noise
%                       M by 3 timetable
%   ERRORMSG:           Message for errors (empty if success)
%   SUCCESS:            1 or 0 (not success)
% 
% $Author:  Peng Li, Ph.D.
% $Date:    Apr 14, 2023
% 

mvstd = movstd(datTT{:, :}, fs);
ind0  = all(mvstd <= thre, 2);
seg   = detConstantOne(ind0);
seg(seg(:, 2) - seg(:, 1) < minLenghNoMoving*fs, :) = [];

if isempty(seg)
    errorMsg = "Abort: no segments without moving identified";
    success  = 0;
    consDat  = [];
else
    outAll   = arrayfun(@(x) retimeNow(datTT, seg(x, :)), 1:size(seg, 1), 'UniformOutput', 0);
    consDat  = vertcat(outAll{:});

    errorMsg = "";
    success  = 1;
end
end

% retime, average per sec
function outTT = retimeNow(inputTT, s)
curTT = inputTT(s(1):s(2), :);
outTT = retime(curTT, "secondly", "mean");
end