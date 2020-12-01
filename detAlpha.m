function [res, fmt] = detAlpha(actigraphy, epoch, varargin)
%DETALPHA do detrended fluctuation analysis and fit results
%   
%   [RES, FMT] = DETALPHA(ACTIGRAPHY, EPOCH, REGION, FILENAME, STARTTIME, FILEPATH)
%       performs detrended fluctuation analysis on ACTIGRAPHY of epoch 
%       length EPOCH second and fits the results in region REGION minutes
%       RES saves fitting results together with min/max scale, goodness and
%       intercept
%       FMT request the format to write RES to file
%
%   $Author:    Peng Li
% 

% to be modified
narginchk(7, 7);

region     = varargin{1};
filename   = varargin{2};

startTime  = datenum(varargin{3});
endTime    = (length(actigraphy)-1)*epoch / (3600*24) + startTime;

filepath   = varargin{4};

t   = linspace(startTime, endTime, length(actigraphy))';
pts = physiologicaltimeseries(actigraphy, t);

% to include gaps
pts.Quality  = varargin{5};
pts.UserData = struct('Epoch', epoch);

pts.Name     = filename;

theDFA       = mydfa;
theDFA.pts   = pts;
theDFA.order = 2;
theDFA.windowLength = [];
theDFA.fitRegion    = region;

theDFA.dfa
theDFA.fit;

% request to save NFN here
theDFA.save('outdir', fullfile(filepath, 'dfa'), 'option', 'fn');

% request summary results here
res = theDFA.fitResult{:, 2:end};
fmt = '%.2f\t%.2f\t%f\t%f\t%f\r';