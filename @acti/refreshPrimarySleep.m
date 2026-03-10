function refreshPrimarySleep(this, actigraphy)
% REFRESHPRIMARYSLEEP Update primary sleep elements from ACTIGRAPHY
% 
% $Author:  Peng Li
% $Date:    Feb 29, 2026
% 

ax = actigraphy.actiAxis;
ptH = actigraphy.Decoration.YAdjust;

delete(findobj(ax, 'Tag', 'PrimaryLine'));
delete(findobj(ax, 'Tag', 'PrimaryText'));

if ~isempty(this.SleepWindow)
    hPrim = plot(ax, this.Point, this.SleepWindow .* ptH - ptH, ...
        'Color', 'b', 'Tag', 'PrimaryLine');
    hPrimText = text(ax, this.SleepSummary.ValidIndex(1), ...
        -1.5*ptH, 'Primary Sleep Window', 'Color', 'b', ...
        'FontSize', 6, 'Tag', 'PrimaryText');
end