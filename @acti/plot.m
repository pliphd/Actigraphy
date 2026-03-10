function h = plot(this, varargin)
%PLOT plot an ACTI object
% 
% $Author:  Peng Li
% $Date:    Dec 02, 2020
% $Modif.:  Dec 08, 2025
%               Add Diary section.
%               Remove Nap as essentially it should be included in Sleep
%           Feb 15, 2026
%               Enable showing primary sleep window estimation if available
%           Feb 19, 2026
%               Call refresh* functions
%           Feb 27, 2026
%               Improve input parser to allow more parameters
% 

% input parser
if nargin > 1 && isa(varargin{1}, 'actigraphy2')
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
    h = actigraphy2(this, 'Visible', p.Results.Visible);
else
    h = providedHandle;
    h.hostApp = this;
    cla(h.actiAxis);
end

% show range
yrange = [min(this.Data(:, end)) max(this.Data(:, end))];
yrange = [yrange(1) - .2*diff(yrange), yrange(2) + .2*diff(yrange)];
ptH    = diff(yrange)/50;
h.Decoration.YLim = yrange;
h.Decoration.YAdjust = ptH;

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

% refresh dynamic elements
this.refreshGaps(h);
this.refreshPrimarySleep(h);
this.refreshSleep(h);
this.refreshDiary(h);
this.refreshCircadian(h);

% switch layers
uistack(findobj(h.actiAxis, 'Type', 'patch'), 'bottom');

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

% reset exponent to 0 in case the following change removes the exponent
% label
h.actiAxis.YAxis.Exponent = 0;

yticklabel = h.actiAxis.YTickLabel;
yticklabel(1:2) = {'\color{cyan}Diary', '\color{blue}Sleep'};
h.actiAxis.YTickLabel = yticklabel;

zoom('reset');

% display time
if h.hostApp.timeSet
    h.actiAxis.Box        = 'off';
    h.shallowAxis.Visible = 'on';
    
    peerXTick = h.actiAxis.XTick;
    xTick     = this.TimeInfo.StartDate + seconds(this.Epoch).*(peerXTick - peerXTick(1));
    h.shallowAxis.XTick      = peerXTick;
    h.shallowAxis.XTickLabel = string(xTick, 'MMM dd, yyyy HH:mm');
    h.shallowAxis.XTickLabelRotation = 10;
    
    xlabel(h.shallowAxis, 'Time');
else
    h.shallowAxis.Visible = 'off';
    h.actiAxis.Box        = 'on';
end

% enable floaters
axtoolbar(h.actiAxis, {'export', 'zoomin', 'zoomout', 'restoreview', 'pan', 'datacursor'});
h.shallowAxis.Toolbar.Visible = 'off';
h.actiAxis.Toolbar.Visible    = 'on';
end