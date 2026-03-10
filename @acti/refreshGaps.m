function refreshGaps(this, actigraphy)
% REFRESHGAPS Update gap patches from ACTIGRAPHY
% 
% $Author:  Peng Li
% $Date:    Feb 29, 2026
% 

ax = actigraphy.actiAxis;
yrange = actigraphy.Decoration.YLim;

delete(findobj(ax, 'Tag', 'GapPatch'));
delete(findobj(ax, 'Tag', 'GapText'));

if ~isempty(this.Gap)
    hGap     = gobjects(size(this.Gap, 1), 1);
    hGapText = gobjects(size(this.Gap, 1), 1);

    % add interactability
    if isempty(actigraphy.Decoration.Gap.ContextMenu) || ~isvalid(actigraphy.Decoration.Gap.ContextMenu)
        actigraphy.Decoration.Gap.ContextMenu = uicontextmenu('Parent', ancestor(ax, 'figure'));
        uimenu(actigraphy.Decoration.Gap.ContextMenu, 'Label', 'Delete Gap', 'Callback', @actigraphy.deleteGapCallback);
    end

    for iG = size(this.Gap, 1):-1:1
        hGap(iG) = patch('Parent', ax, ...
            'XData', [this.Gap(iG, 1) this.Gap(iG, 1) this.Gap(iG, 2) this.Gap(iG, 2)], ...
            'YData', [yrange(1) yrange(2) yrange(2) yrange(1)], ...
            'FaceColor', 'm', 'EdgeColor', 'm', 'FaceAlpha', 0.1, ...
            'Tag', 'GapPatch');
        set(hGap(iG), 'ButtonDownFcn', @(src, evt) actigraphy.highlightGapPatch(src, evt));
        set(hGap(iG), 'ContextMenu', actigraphy.Decoration.Gap.ContextMenu);

        switch actigraphy.Decoration.Gap.Label
            case 'on'
                hGapText(iG) = text(ax, this.Gap(iG, 1), ...
                    yrange(2) - ((iG-1)./size(this.Gap, 1))*diff(yrange), ...
                    ['Gap: # ' num2str(iG)], 'Color', 'm', ...
                    'FontSize', 6, 'Tag', 'GapText');
        end
    end

    actigraphy.Decoration.Gap.PatchHandles = hGap;
    switch actigraphy.Decoration.Gap.Label
        case 'on'
            actigraphy.Decoration.Gap.Texthandles = hGapText;
    end
end

uistack(findobj(ax, 'Type', 'patch'), 'bottom');