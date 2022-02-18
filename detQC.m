function [res, fmt] = detQC(actigraphy, epoch, varargin)
%DETQC do actigraphy qc
%   
%   [RES, FMT] = DETQC(ACTIGRAPHY, EPOCH, STARTTIME)
%       performs QC on ACTIGRAPHY of epoch length EPOCH and 
%       return results to the caller.
%       FMT request the format to write RES to file
%
%   $Author:    Peng Li
%   $Date:      Feb 18, 2022
% 

% to be modified
narginchk(3, 3);

startTime  = varargin{1};
a = acti(actigraphy, 'Epoch', epoch, 'StartTime', startTime);

a = qc(a);

% request summary results here
res = a.QCimpression;

fmt = '%d\t%s\n';