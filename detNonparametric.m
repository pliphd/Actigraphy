function [res, fmt] = detNonparametric(actigraphy, epoch, varargin)
%DETNONPARAMETRIC do nonparametric analysis (ISIV and M10L5)
%   
%   [RES, FMT] = DETNONPARAMETRIC(ACTIGRAPHY, EPOCH, STARTTIME, QUALITY, ISIVINFO)
%       performs sleep detection on ACTIGRAPHY of epoch length EPOCH and 
%       return results to the caller.
%       FMT request the format to write RES to file
%
%   $Author:    Peng Li
%   $Date:      Jun 18, 2021
% 

% to be modified
narginchk(5, 5);

startTime  = varargin{1};
a = acti(actigraphy, 'Epoch', epoch, 'StartTime', startTime);
a.GapSeries = ~varargin{2};

para = varargin{3};

a.ISIVInfo = para;
a = a.isivAnalysis;

a = a.m10l5Analysis;

% request summary results here
res = [a.ISIVSummary{:, :} a.M10L5Summary{:, :}];

fmt = '%f\t%f\t%d\t%f\t%f\t%d\t%f\t%f\t%f\t%f\n';