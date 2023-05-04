function [res, fmt] = detUPMEMDperCycle(imf24, epoch, varargin)
%DETUPMEMDPERCYCLE extract cycle to cycle amplitude of the ~24-h component
% extracted from DETUPMEMD
%   
%   [RES, FMT] = DETUPMEMDPERCYCLE(IMF24, EPOCH, MINCYCLE)
%       FMT request the format to write RES to file
%
%   $Author:    Peng Li
% 

if nargin == 3
    minCycle = varargin{1};
else
    minCycle = 6;
end

% per  cycle
sampf = 1 / epoch * 3600; % 1/hr

[cycleStart, ~, cycleAmplitude] = ...
    li_upmemd_cycle(imf24, sampf);

% if at least minCycle cycles
if all(isnan(cycleStart)) || numel(cycleStart) < minCycle
    res = [nan nan nan nan nan nan];
else
    % when minCycle == 1, use all available results
    if minCycle == 1
        cycleN   = numel(cycleStart);
    else
        cycleN   = minCycle;
    end

    % request output
    res = cycleAmplitude(1:cycleN);
    res = res(:)';
end

fmt = '%f\t%f\t%f\t%f\t%f\t%f\n';