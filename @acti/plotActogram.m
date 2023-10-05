function h = plotActogram(this, varargin)
%PLOTACTOGRAM plot an ACTI object in actogram format
% 
% $Author: Peng Li
% $Date:   Dec 01, 2021
% 

% axes
if nargin == 2
    if isa(varargin{1}, 'actogram')
        if isempty(findobj('Tag', 'actogramFig'))
            h = actogram(this);
        else
            h = varargin{1};
            h.hostApp = this;
            cla(h.actiAxis);
        end
    else
        if ~isempty(findobj('Tag', 'actogramFig'))
            delete(findobj('Tag', 'actogramFig'));
        end
        h = actogram(this);
    end
else
    h = actogram(this);
end

set(h.actiAxis, 'NextPlot', 'add');

% fixed separator line at 9AM
seperator = hours(9);

% first line date
firstSep  = datetime(this.TimeInfo.StartDate.Year, ...
    this.TimeInfo.StartDate.Month, ...
    this.TimeInfo.StartDate.Day, ...
    hours(seperator), ...
    minutes(seperator)-hours(seperator)*60, ...
    0);
if this.TimeInfo.StartDate < firstSep
    firstSep = firstSep - days(1);
end

% fill the empty from the beginning of first line to the beginning of
% recording with NaN
y = [nan(floor((this.TimeInfo.StartDate - firstSep) / seconds(this.Epoch)), 1); this.Data];

% how many lines required
linesReq = ceil(length(y)*this.Epoch/3600/24);

% datetime each line
lineDate = firstSep + days(0:linesReq-1);

% end of last line
lastSep  = lineDate(end) + days(1) - seconds(this.Epoch);

% end of each line
lineEnd  = lastSep - days(linesReq-1:-1:0);

% fill the empty from the end of the recording to the end of last one with
% NaN
y = [y; nan(floor((lastSep - (this.TimeInfo.StartDate + seconds(this.TimeInfo.End))) / seconds(this.Epoch)), 1)];

% reshape
y = reshape(y, [], linesReq);

% x axes
xdata = (firstSep:seconds(this.Epoch):lineDate(2)-seconds(this.Epoch))';

% split plot by y-axes
datarange = prctile(y(:), 99) - min(y(:));

% Dec 19, 2022
% in case datarange == 0
if datarange == 0
    datarange = 1;
end

layrange  = datarange + ceil(.3*datarange);
baseline  = (0:linesReq-1) .* layrange;
baseline  = baseline(end:-1:1);

% fill sleep
fillColor  = [.8 .9 .95];
if ~isempty(this.Sleep)
    for iS = 1:size(this.Sleep, 1)
        cS = this.Sleep(iS, :);
        st = this.TimeInfo.StartDate + cS*seconds(this.Epoch);
        
        segLine = floor((st - firstSep) / hours(24)) + 1;
        segInd  = (st - lineDate(segLine)) ./ seconds(this.Epoch) + 1;
        
        if segLine(1) == segLine(2)
            patch(datenum([segInd(1) segInd(1) segInd(2) segInd(2)]*seconds(this.Epoch)+firstSep), ...
                [baseline(segLine(1)) baseline(segLine(1))+.8*layrange baseline(segLine(2))+.8*layrange baseline(segLine(2))], ...
                fillColor, 'EdgeColor', fillColor, 'Parent', h.actiAxis);
        else
            patch(datenum([segInd(1)*seconds(this.Epoch)+firstSep segInd(1)*seconds(this.Epoch)+firstSep lineEnd(1) lineEnd(1)]), ...
                [baseline(segLine(1)) baseline(segLine(1))+.8*layrange baseline(segLine(1))+.8*layrange baseline(segLine(1))], ...
                fillColor, 'EdgeColor', fillColor, 'Parent', h.actiAxis);
            patch(datenum([lineDate(1) lineDate(1) segInd(2)*seconds(this.Epoch)+firstSep segInd(2)*seconds(this.Epoch)+firstSep]), ...
                [baseline(segLine(2)) baseline(segLine(2))+.8*layrange baseline(segLine(2))+.8*layrange baseline(segLine(2))], ...
                fillColor, 'EdgeColor', fillColor, 'Parent', h.actiAxis);
        end
    end
end

% fill gap
fillColor  = [.95 .9 .8];
if ~isempty(this.Gap)
    for iS = 1:size(this.Gap, 1)
        cS = this.Gap(iS, :);
        st = this.TimeInfo.StartDate + cS*seconds(this.Epoch);
        
        segLine = floor((st - firstSep) / hours(24)) + 1;
        segInd  = (st - lineDate(segLine)) ./ seconds(this.Epoch) + 1;
        
        if segLine(1) == segLine(2)
            patch(datenum([segInd(1) segInd(1) segInd(2) segInd(2)]*seconds(this.Epoch)+firstSep), ...
                [baseline(segLine(1)) baseline(segLine(1))-.1*layrange baseline(segLine(2))-.1*layrange baseline(segLine(2))], ...
                fillColor, 'EdgeColor', fillColor, 'Parent', h.actiAxis);
        else
            patch(datenum([segInd(1)*seconds(this.Epoch)+firstSep segInd(1)*seconds(this.Epoch)+firstSep lineEnd(1) lineEnd(1)]), ...
                [baseline(segLine(1)) baseline(segLine(1))-.1*layrange baseline(segLine(1))-.1*layrange baseline(segLine(1))], ...
                fillColor, 'EdgeColor', fillColor, 'Parent', h.actiAxis);
            patch(datenum([lineDate(1) lineDate(1) segInd(2)*seconds(this.Epoch)+firstSep segInd(2)*seconds(this.Epoch)+firstSep]), ...
                [baseline(segLine(2)) baseline(segLine(2))-.1*layrange baseline(segLine(2))-.1*layrange baseline(segLine(2))], ...
                fillColor, 'EdgeColor', fillColor, 'Parent', h.actiAxis);
        end
    end
end

% plot activity
for iL = 1:linesReq
    plot(datenum(xdata), y(:, iL) + baseline(iL), 'Color', 'k', 'Parent', h.actiAxis);
end

set(h.actiAxis, 'YLim', [0 layrange*linesReq], 'XLim', datenum([firstSep lineDate(2)]), 'Box', 'on');

% set x-tick
XTick      = datenum(firstSep:hours(4):lineDate(2));
XTickLabel = datestr(XTick, 'hh:MM am');
set(h.actiAxis, 'XTick', XTick, 'XTickLabel', XTickLabel);

% set y-tick
YTick      = layrange/2 + baseline(end:-1:1);
YTickLabel = datestr(lineDate(end:-1:1), 'mmm dd, yyyy');
set(h.actiAxis, 'YTick', YTick, 'YTickLabel', YTickLabel);

% switch layers
child = h.actiAxis.Children;
type  = get(child, 'Type');
chd1  = child(strcmpi(type, 'patch'));
chd2  = child(~strcmpi(type, 'patch'));
h.actiAxis.Children = [chd2; chd1];