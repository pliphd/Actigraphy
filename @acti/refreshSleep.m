function refreshSleep(this, actigraphy)
% REFRESHSLEEP Update sleep elements from ACTIGRAPHY
% 
% $Author:  Peng Li
% $Date:    Feb 19, 2026
% $Modif.:  Feb 20, 2026
%               Facilitate lagecy plot (patches only)
% 

ax = actigraphy.actiAxis;
ptH = actigraphy.Decoration.YAdjust;
yrange = actigraphy.Decoration.YLim;

delete(findobj(ax, 'Tag', 'SleepPatch'));
delete(findobj(ax, 'Tag', 'OnsetMarker'));
delete(findobj(ax, 'Tag', 'OffsetMarker'));
delete(findobj(ax, 'Tag', 'ExcludedPatch'));

if ~isempty(this.Sleep)
    hSleep = gobjects(size(this.Sleep, 1), 1);
    for iG = size(this.Sleep, 1):-1:1
        hSleep(iG) = patch('Parent', ax, ...
            'XData', [this.Sleep(iG, 1) this.Sleep(iG, 1) this.Sleep(iG, 2) this.Sleep(iG, 2)], ...
            'YData', [yrange(1)+4*ptH yrange(1)+5*ptH yrange(1)+5*ptH yrange(1)+4*ptH], ...
            'FaceColor', 'b', 'EdgeColor', 'b', 'Tag', 'SleepPatch');
    end
    actigraphy.Decoration.Sleep.PatchHandles = hSleep;

    % if PrimaryOnset is not a field of this.SleepSummary, it's most likely
    % from a legacy re-load of sleep results
    if ~isfield(this.SleepSummary, 'PrimaryOnset')
        return;
    end

    % mark onset and offset
    for iG = 1:numel(this.SleepSummary.PrimaryOnset)
        plot(ax, ...
            [this.SleepSummary.PrimaryOnset(iG) this.SleepSummary.PrimaryOnset(iG)], ...
            [yrange(1)+3*ptH yrange(1)+4*ptH], ...
            '-^', 'Color', [0.7 0 1], 'MarkerIndices', 2, 'MarkerSize', 2, ...
            'MarkerFaceColor', [0.7 0 1], 'Tag', 'OnsetMarker');
    end

    for iG = 1:numel(this.SleepSummary.PrimaryOffset)
        plot(ax, ...
            [this.SleepSummary.PrimaryOffset(iG) this.SleepSummary.PrimaryOffset(iG)], ...
            [yrange(1)+3*ptH yrange(1)+4*ptH], ...
            'r-v', 'MarkerIndices', 1, 'MarkerSize', 2, ...
            'MarkerFaceColor', 'r', 'Tag', 'OffsetMarker');
    end

    % marker out beginning or ending segments that are excluded in summary
    patch('Parent', ax, ...
        'XData', [1 1 this.SleepSummary.ValidIndex(1) this.SleepSummary.ValidIndex(1)], ...
        'YData', [yrange(1)+3*ptH yrange(1)+4*ptH yrange(1)+4*ptH yrange(1)+3*ptH], ...
        'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.8 0.8 0.8], 'Tag', 'ExcludedPatch');
    patch('Parent', ax, ...
        'XData', [this.SleepSummary.ValidIndex(2) this.SleepSummary.ValidIndex(2) length(this.Point) length(this.Point)], ...
        'YData', [yrange(1)+3*ptH yrange(1)+4*ptH yrange(1)+4*ptH yrange(1)+3*ptH], ...
        'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.8 0.8 0.8], 'Tag', 'ExcludedPatch');
end

% switch layers
uistack(findobj(ax, 'Type', 'patch'), 'bottom');