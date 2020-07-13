function ta = detTotalActivity(actigraphy, epoch, varargin)
%DETTOTALACTIVITY calculate total activity
%   
%   TA = DETTOTALACTIVITY(ACTIGRAPHY, EPOCH, STARTTIME, WINDOWLENGTH)
%   calculate the total activity level in ACTIGRAPHY of epoch EPOCH second
%   with start time at STARTTIME. WINDOWLENGTH specifies the length of
%   window in hr for each calculation.
%
%   $Author:    Peng Li
% 

narginchk(4, 4);

startTime    = varargin{1};
windowLength = varargin{2};

endtime = startTime + seconds((length(actigraphy)-1) * epoch);
[window, actualWindow] = ClipWindow(startTime, endtime, epoch/60, windowLength);

totalActivity = splitapply(@(x) windMean(actigraphy, x), window, (1:size(window, 1))');

ta = table(actualWindow(:, 1), actualWindow(:, 2), totalActivity, ...
    'VariableNames', {'starttime', 'endtime', 'total_activity'});
end

function mta = windMean(actigraphy, window)
mta = nanmean(actigraphy(window(1):window(2)));
end