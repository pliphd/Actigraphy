function h = plot(this, varargin)
%PLOT plot an ACTI object
% 
% $Author: Peng Li
% $Date:   Dec 02, 2020
% 

% axes
if nargin == 2
    if isa(varargin{1}, 'actigraphy2')
        if isempty(findobj('Tag', 'actigraphyFig'))
            h = actigraphy2(this);
        else
            h = varargin{1};
            h.hostApp = this;
            cla(h.actiAxis);
        end
    else
        if ~isempty(findobj('Tag', 'actigraphyFig'))
            delete(findobj('Tag', 'actigraphyFig'));
        end
        h = actigraphy2(this);
    end
else
    h = actigraphy2(this);
end

% show range
yrange = [min(this.Data(:, end)) max(this.Data(:, end))];
yrange = [yrange(1) - .2*diff(yrange), yrange(2) + .2*diff(yrange)];

% plot signal
set(h.actiAxis, 'NextPlot', 'add');
hSig = plot(h.actiAxis, this.Point, this.Data, 'Color', 'k');

% plot day seperator
pointPerDay = 24*60*60 / this.Epoch;
TotalDays   = ceil(length(this.Point) / pointPerDay);
StartBorder = (1:TotalDays-1) .* pointPerDay + 1;
Seperator   = repmat([-1e6; 1e6], 1, length(StartBorder));
hSep = plot(h.actiAxis, [StartBorder; StartBorder], Seperator, ...
    'Color', 1-.4*(1-[.65 .65 .15]), ...
    'LineStyle', '--', 'LineWidth', 1);
xlabel(h.actiAxis, 'Points');

% plot gap
if ~isempty(this.Gap)
    for iG = size(this.Gap, 1):-1:1
        hGap(iG) = patch('Parent', h.actiAxis, ...
            'XData', [this.Gap(iG, 1) this.Gap(iG, 1) this.Gap(iG, 2) this.Gap(iG, 2)], ...
            'YData', [yrange(1) yrange(2) yrange(2) yrange(1)], ...
            'FaceColor', 'm', 'EdgeColor', 'm', 'FaceAlpha', 0.1);
        hGapText(iG) = text(h.actiAxis, this.Gap(iG, 1), ...
            yrange(2) - ((iG-1)./size(this.Gap, 1))*diff(yrange), ...
            ['Gap: # ' num2str(iG)], 'Color', 'm', ...
            'FontSize', 6);
    end
end

% plot sleep
ptH = diff(yrange)/50;
if ~isempty(this.Sleep)
    for iG = size(this.Sleep, 1):-1:1
        hSleep(iG) = patch('Parent', h.actiAxis, ...
            'XData', [this.Sleep(iG, 1) this.Sleep(iG, 1) this.Sleep(iG, 2) this.Sleep(iG, 2)], ...
            'YData', [yrange(1)+ptH yrange(1)+2*ptH yrange(1)+2*ptH yrange(1)+ptH], ...
            'FaceColor', 'b', 'EdgeColor', 'b');
        hSleepText(iG) = text(h.actiAxis, this.Sleep(iG, 1), ...
            yrange(1) + ptH/2, ...
            ['Sleep: # ' num2str(iG)], 'Color', 'b', ...
            'FontSize', 6);
    end
end

% switch layers
child = h.actiAxis.Children;
type  = get(child, 'Type');
chd1  = child(strcmpi(type, 'patch'));
chd2  = child(~strcmpi(type, 'patch'));
h.actiAxis.Children = [chd2; chd1];

% range set
if yrange(2) > yrange(1) % to avoid nan
    h.actiAxis.YLim = yrange;
end
h.actiAxis.XLim    = [0 length(this.Point)];
h.shallowAxis.XLim = [0 length(this.Point)];

ytick = h.actiAxis.YTick;
ytick(ytick < 0) = [];
ytick = [yrange(1) + ptH*1.5 yrange(1) + ptH*4.5 ytick];
h.actiAxis.YTick = ytick;

yticklabel = h.actiAxis.YTickLabel;
yticklabel(1:2) = {'\color{blue}Sleep', '\color{cyan}Nap'};
h.actiAxis.YTickLabel = yticklabel;

zoom('reset');

% display time
if h.hostApp.timeSet
    h.actiAxis.Box        = 'off';
    h.shallowAxis.Visible = 'on';
    
    peerXTick = h.actiAxis.XTick;
    xTick     = this.TimeInfo.StartDate + seconds(this.Epoch).*(peerXTick - peerXTick(1));
    h.shallowAxis.XTick      = peerXTick;
    h.shallowAxis.XTickLabel = datestr(xTick, 'dd-mmm-yyyy HH:MM');
    h.shallowAxis.XTickLabelRotation = 10;
    
    xlabel(h.shallowAxis, 'Time');
else
    h.shallowAxis.Visible = 'off';
    h.actiAxis.Box        = 'on';
end
end