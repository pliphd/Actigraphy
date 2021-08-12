function [res, fmt] = detMag(actigraphy, epoch, varargin)
%DETMAG do magnitude analysis and fit results
%   
%   [RES, FMT] = DETMAG(ACTIGRAPHY, EPOCH, REGION, FILENAME, STARTTIME, FILEPATH, QUALITY)
%       performs magnitude analysis on ACTIGRAPHY of epoch 
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

% overwrite actigraphy
actigraphy = abs(actigraphy(2:end, :) - actigraphy(1:end-1, :));

startTime  = datenum(varargin{3});
endTime    = (length(actigraphy)-1)*epoch / (3600*24) + startTime;

filepath   = varargin{4};

t   = linspace(startTime, endTime, length(actigraphy))';
pts = physiologicaltimeseries(actigraphy, t);

% overwrite gaps
gapOrig = varargin{5};
gapOrig(gapOrig == 0) = nan;
gapNew  = gapOrig(2:end, :) - gapOrig(1:end-1, :);
gapNew(gapNew == 0)   = 1;
gapNew(isnan(gapNew)) = 0;

pts.Quality  = gapNew;
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
theDFA.save('outdir', fullfile(filepath, 'mag'), 'option', 'fn');

% request summary results here
if ~isempty(theDFA.fitResult)
    res = theDFA.fitResult{:, 2:end};
else
    res = [nan nan nan nan nan];
end
fmt = '%.2f\t%.2f\t%f\t%f\t%f\n';