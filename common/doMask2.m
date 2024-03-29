function [maskSeries, maskWindow, maskLength] = doMask2(dataLength, epochInSec, dataStartTime, maskStartTimestr, maskEndTimestr)
%DOMASK2 generate masking series based on start and end time
% 
% $Author:  Peng Li
% $Date:    Jan 09, 2020
% $Modif.:  Dec 02, 2020
%               relocation
%           May 17, 2021
%               output maskWindow for use in next step
%           Oct 04, 2021
%               output maskLength in hour for using in next step
% 

totalDays = ceil(dataLength .* epochInSec ./ 3600 ./ 24);

recEnd    = dataStartTime + ((dataLength-1).*epochInSec ./ 3600 ./ 24);

daytimestart = strsplit(maskStartTimestr, ':');
daytimeend   = strsplit(maskEndTimestr, ':');
dayStart     = datetime(year(dataStartTime), month(dataStartTime), day(dataStartTime), str2double(daytimestart{1}), str2double(daytimestart{2}), 0);
dayEnd       = datetime(year(dataStartTime), month(dataStartTime), day(dataStartTime), str2double(daytimeend{1}), str2double(daytimeend{2}), 0);

if dayEnd < dayStart % cross days
    dayEnd = dayEnd + 1;
end

maskLength = hours(dayEnd - dayStart);

days = [dayStart + (0:totalDays)', dayEnd + (0:totalDays)'];
days(days(:, 1) <= dataStartTime, 1) = dataStartTime;
days(days(:, 2) >= recEnd, 2) = recEnd;
days(days(:, 2) - days(:, 1) <= seconds(1), :) = [];

maskWindow = round(hours(days - dataStartTime) * 3600 / epochInSec + 1);
maskSeries = ~gap2Series(maskWindow, dataLength);