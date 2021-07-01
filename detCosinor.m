function [res, fmt] = detCosinor(actigraphy, epoch, varargin)
%DETCOSINOR do cosinor analysis
%   
%   [RES, FMT] = DETCOSINOR(ACTIGRAPHY, EPOCH, STARTTIME, QUALITY, COSINORINFO)
%       performs ACTIGRAPHY of epoch length EPOCH and 
%       return results to the caller.
%       FMT request the format to write RES to file
%
%   $Author:    Peng Li
%   $Date:      Jul 01, 2021
% 

% to be modified
narginchk(5, 5);

startTime  = varargin{1};
a = acti(actigraphy, 'Epoch', epoch, 'StartTime', startTime);
a.GapSeries = ~varargin{2};

para = varargin{3};

a.CosinorInfo = para;
a = a.cosinorAnalysis;

% request summary results here
res = a.CosinorSummary{:, :};

tmp_fmt = repmat('%f\t', 1, width(res));
fmt = [tmp_fmt(1:end-1) 'n'];