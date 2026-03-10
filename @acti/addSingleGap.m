function this = addSingleGap(this, actigraphy, singleGap)
% ADDSINGLEGAP Adds a new gap to ACTIGRAPHY and return the updated .Gap
%   property
% 
% $Author:  Peng Li
% $Date:    Feb 19, 2026
% $Modif.:  Feb 20, 2026
%               Add internal verification of SINGLEGAP validity
%           Mar 10, 2026
%               Refine verification steps
% 

ax = actigraphy.actiAxis;
yrange = actigraphy.Decoration.YLim;

% check for overlaps with existing gaps
this.message.type = 'success';
this.message.content = '';
if ~isempty(this.Gap)
    for iG = 1:size(this.Gap, 1)
        existingGap = this.Gap(iG, :);
        if ~(singleGap(2) < existingGap(1) || singleGap(1) > existingGap(2))
            this.message.type = 'r';
            this.message.content = sprintf('The new gap [%d %d] overlaps with existing gap [%d %d]. Not adding.', ...
                singleGap(1), singleGap(2), existingGap(1), existingGap(2));
            return;
        end
    end
end

if singleGap(1) > this.Point(end)
    this.message.type = 'r';
    this.message.content = sprintf('The new gap [%d %d] is beyond the data length. Not adding.', ...
        singleGap(1), singleGap(2));
    return;
end
if singleGap(1) < 1
    this.message.type = 'warn';
    this.message.content = sprintf('Start index needs to be at least 1. Input %d was revised to 1.', ...
        singleGap(1));
    singleGap(1) = 1;
end
if singleGap(2) > this.Point(end)
    this.message.type = 'warn';
    this.message.content = sprintf('End index should not be larger than data length. Input %d was revised to %d.', ...
        singleGap(2), this.Point(end));
    singleGap(2) = this.Point(end);
end

% no overlap, proceed
% in case new gap sits somewhere in the middle of other gaps (not exactly
% in the end), although the delete of visualization items are correct, the
% delete of Gap will be a problem since the index will mess up due to
% automatic sort within set.Gap
% use idx to recover this
[newGap, idx] = sortrows([this.Gap; singleGap]);
this.Gap = newGap;

% proporate to actigraphy so that some operations within actigraphy can
% have the right data of acti
actigraphy.hostApp = this;

iG = size(this.Gap, 1);

% add interactability (if first time gap detection, no ContextMenu
% generated from refreshGaps yet
if isempty(actigraphy.Decoration.Gap.ContextMenu) || ~isvalid(actigraphy.Decoration.Gap.ContextMenu)
    actigraphy.Decoration.Gap.ContextMenu = uicontextmenu('Parent', ancestor(ax, 'figure'));
    uimenu(actigraphy.Decoration.Gap.ContextMenu, 'Label', 'Delete Gap', 'Callback', @actigraphy.deleteGapCallback);
end

hGap = patch('Parent', ax, ...
    'XData', [singleGap(1) singleGap(1) singleGap(2) singleGap(2)], ...
    'YData', [yrange(1) yrange(2) yrange(2) yrange(1)], ...
    'FaceColor', 'm', 'EdgeColor', 'm', 'FaceAlpha', 0.1, ...
    'Tag', 'GapPatch');
set(hGap, 'ButtonDownFcn', @(src, evt) actigraphy.highlightGapPatch(src, evt));
set(hGap, 'ContextMenu', actigraphy.Decoration.Gap.ContextMenu);

switch actigraphy.Decoration.Gap.Label
    case 'on'
        hGapText = text(ax, singleGap(1), ...
            yrange(2) - ((iG-1)./size(singleGap, 1))*diff(yrange), ...
            ['Gap: # ' num2str(iG)], 'Color', 'm', ...
            'FontSize', 6, 'Tag', 'GapText');
end

newPatchHandles = [actigraphy.Decoration.Gap.PatchHandles; hGap];
actigraphy.Decoration.Gap.PatchHandles = newPatchHandles(idx);

switch actigraphy.Decoration.Gap.Label
    case 'on'
        newTextHandles = [actigraphy.Decoration.Gap.Texthandles; hGapText];
        actigraphy.Decoration.Gap.Texthandles = newTextHandles(idx);
end

this.message.content = [this.message.content sprintf('The new gap [%d %d] was added.', ...
    singleGap(1), singleGap(2))];