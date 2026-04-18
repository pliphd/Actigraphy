function refreshSleep(this, actigraphy)
% REFRESHSLEEP Update sleep elements from ACTIGRAPHY
%
% $Author:  Peng Li
% $Date:    Feb 19, 2026
% $Modif.:  Feb 20, 2026
%               Facilitate lagecy plot (patches only)
%           Apr 16, 2026
%               Added gray-out patches for intermediate partial/abnormal nights
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

    % Gray out intermediate partial/abnormal nights
    if isfield(this.SleepSummary, 'Meta') && isfield(this.SleepSummary.Meta, 'is_partial_night')
        partial_flags = this.SleepSummary.Meta.is_partial_night;
        onoff_idx = this.SleepSummary.Meta.onoff; % Contains adjusted onset/offset pairs

        for iN = 1:length(partial_flags)
            % If this specific night was flagged as partial or abnormal
            if partial_flags(iN)
                pStart = onoff_idx(iN, 1);
                pEnd   = onoff_idx(iN, 2);

                % Only draw if we have valid integer indices for start/end
                if ~isnan(pStart) && ~isnan(pEnd)
                    patch('Parent', ax, ...
                        'XData', [pStart pStart pEnd pEnd], ...
                        'YData', [yrange(1)+3*ptH yrange(1)+4*ptH yrange(1)+4*ptH yrange(1)+3*ptH], ...
                        'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.8 0.8 0.8], 'Tag', 'ExcludedPatch');
                end
            end
        end
    end
end

% switch layers
uistack(findobj(ax, 'Type', 'patch'), 'bottom');