function h = plotActogram(this, varargin)
%PLOTACTOGRAM plot an ACTI object in actogram format
% 
% $Author:  Peng Li
% $Date:    Dec 01, 2021
% $Modif.:  Feb 26, 2026
%               Mark primary sleep window if possible
%               Using darker colors for potential primary sleep
% 

% input parser
if nargin > 1 && isa(varargin{1}, 'actogram')
    providedHandle = varargin{1};
    nameValueArgs  = varargin(2:end);
else
    providedHandle = [];
    nameValueArgs  = varargin;
end

p = inputParser;
addParameter(p, 'Visible', true, @islogical);
parse(p, nameValueArgs{:});

createNew = true;
if ~isempty(providedHandle)
    if ~isempty(findobj('Tag', 'actigraphyFig'))
        createNew = false; % valid handle + figure still exists → reuse
    end
end

if createNew
    h = actogram(this, 'Visible', p.Results.Visible);
else
    h = providedHandle;
    h.hostApp = this;
    cla(h.actiAxis);
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
winLineColor = [.95 .4 .3];
if isprop(this, 'SleepWindow') && ~isempty(this.SleepWindow)
    sw = detConstantOne(~this.SleepWindow);
    for iW = 1:size(sw, 1)
        cW = sw(iW, :);
        stW = this.TimeInfo.StartDate + cW*seconds(this.Epoch);
        segLineW = floor((stW - firstSep) / hours(24)) + 1;
        segIndW  = (stW - lineDate(segLineW)) ./ seconds(this.Epoch) + 1;

        for jW = 1:2
            x_val = datenum(segIndW(jW)*seconds(this.Epoch)+firstSep);
            y_bottom = baseline(segLineW(jW));
            y_top = baseline(segLineW(jW)) + .8*layrange;
            plot([x_val x_val], [y_bottom y_top], 'Color', winLineColor, 'LineWidth', 1.5, 'Parent', h.actiAxis);
        end
    end
end

inColor  = [.4 .6 .8];   % Darker blue for patches inside onoff
outColor = [.8 .9 .95];  % Light blue for patches outside onoff

hasOnOff = isprop(this, 'SleepSummary') && ~isempty(this.SleepSummary) && ...
    isfield(this.SleepSummary, 'Meta') && isfield(this.SleepSummary.Meta, 'onoff') && ...
    ~isempty(this.SleepSummary.Meta.onoff);

if ~isempty(this.Sleep)
    for iS = 1:size(this.Sleep, 1)
        cS = this.Sleep(iS, :);

        % Split sleep interval based on onoff overlaps
        if ~hasOnOff
            segments = {cS};
            colors = {inColor}; % Default color if no onoff
        else
            onoff = this.SleepSummary.Meta.onoff;
            overlap_idx = find(onoff(:,1) <= cS(2) & onoff(:,2) >= cS(1));

            segments = {};
            colors = {};

            if isempty(overlap_idx)
                segments{1} = cS;
                colors{1} = outColor;
            else
                curr_st = cS(1);
                for o = 1:length(overlap_idx)
                    on_st = onoff(overlap_idx(o), 1);
                    on_en = onoff(overlap_idx(o), 2);

                    % Chunk entirely before the current onoff period
                    if curr_st < on_st
                        segments{end+1} = [curr_st, on_st];
                        colors{end+1} = outColor;
                        curr_st = on_st;
                    end

                    % Chunk inside the current onoff period
                    end_in = min(cS(2), on_en);
                    if curr_st < end_in
                        segments{end+1} = [curr_st, end_in];
                        colors{end+1} = inColor;
                        curr_st = end_in;
                    end
                end

                % Remaining chunk after the last onoff period
                if curr_st < cS(2)
                    segments{end+1} = [curr_st, cS(2)];
                    colors{end+1} = outColor;
                end
            end
        end

        % Plot each distinct segment
        for iSeg = 1:length(segments)
            seg_cS = segments{iSeg};
            seg_col = colors{iSeg};

            st = this.TimeInfo.StartDate + seg_cS*seconds(this.Epoch);
            segLine = floor((st - firstSep) / hours(24)) + 1;
            segInd  = (st - lineDate(segLine)) ./ seconds(this.Epoch) + 1;

            if segLine(1) == segLine(2)
                patch(datenum([segInd(1) segInd(1) segInd(2) segInd(2)]*seconds(this.Epoch)+firstSep), ...
                    [baseline(segLine(1)) baseline(segLine(1))+.8*layrange baseline(segLine(2))+.8*layrange baseline(segLine(2))], ...
                    seg_col, 'EdgeColor', seg_col, 'Parent', h.actiAxis);
            else
                patch(datenum([segInd(1)*seconds(this.Epoch)+firstSep segInd(1)*seconds(this.Epoch)+firstSep lineEnd(1) lineEnd(1)]), ...
                    [baseline(segLine(1)) baseline(segLine(1))+.8*layrange baseline(segLine(1))+.8*layrange baseline(segLine(1))], ...
                    seg_col, 'EdgeColor', seg_col, 'Parent', h.actiAxis);
                patch(datenum([lineDate(1) lineDate(1) segInd(2)*seconds(this.Epoch)+firstSep segInd(2)*seconds(this.Epoch)+firstSep]), ...
                    [baseline(segLine(2)) baseline(segLine(2))+.8*layrange baseline(segLine(2))+.8*layrange baseline(segLine(2))], ...
                    seg_col, 'EdgeColor', seg_col, 'Parent', h.actiAxis);
            end
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