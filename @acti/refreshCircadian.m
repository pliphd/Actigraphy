function refreshCircadian(this, actigraphy)
% REFRESHCIRCADIAN Update circadian results from ACTIGRAPHY
% 
% $Author:  Peng Li
% $Date:    Feb 20, 2026
% 

ax = actigraphy.actiAxis;
ptH = actigraphy.Decoration.YAdjust;

delete(findobj(ax, 'Tag', 'Cosine'));

if ~isempty(this.Circadian)
    hPrim = plot(ax, this.Point, this.Circadian, ...
        'Color', 'r', 'LineWidth', 2, 'Tag', 'Cosine');
end