function refreshDiary(this, actigraphy)
% REFRESHDIARY Update diary elements from ACTIGRAPHY
% 
% $Author:  Peng Li
% $Date:    Feb 29, 2026
% 

ax = actigraphy.actiAxis;
ptH = actigraphy.Decoration.YAdjust;
yrange = actigraphy.Decoration.YLim;

delete(findobj(ax, 'Tag', 'DiaryPatch'));
delete(findobj(ax, 'Tag', 'DiaryText'));

if ~isempty(this.Diary)
    hDiary = gobjects(size(this.Diary, 1), 1);
    hDiaryText = gobjects(size(this.Diary, 1), 1);

    for iG = size(this.Diary, 1):-1:1
        hDiary(iG) = patch('Parent', ax, ...
            'XData', [this.Diary(iG, 1) this.Diary(iG, 1) this.Diary(iG, 2) this.Diary(iG, 2)], ...
            'YData', [yrange(1)+1*ptH yrange(1)+2*ptH yrange(1)+2*ptH yrange(1)+1*ptH], ...
            'FaceColor', 'c', 'EdgeColor', 'c', 'Tag', 'DiaryPatch');

        switch actigraphy.Decoration.Diary.Label
            case 'on'
                hDiaryText(iG) = text(ax, this.Diary(iG, 1), ...
                    yrange(1) + 0.5*ptH, ...
                    this.DiaryInfo.Type{iG}, 'Color', 'c', ...
                    'FontSize', 6, 'Tag', 'DiaryText');
        end
    end
    actigraphy.Decoration.Diary.PatchHandles = hDiary;
    switch actigraphy.Decoration.Diary.Label
        case 'on'
            actigraphy.Decoration.Diary.TextHandles = hDiaryTest;
    end
end

uistack(findobj(ax, 'Type', 'patch'), 'bottom');