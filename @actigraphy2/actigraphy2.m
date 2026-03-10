%ACTIGRAPHY2
% 
% Descriptions tba
% 
%   $Author:    Peng Li, Ph.D.
%   $Date:      Jan 01, 2022
%   $Modif.:    Feb 19, 2026
%                   Add a hidden property for storing some decoration stuff
%                   And add interactibility for easier integration to
%                       EZACTI3
%               Feb 20, 2026
%                   Allow trigger other functions when gap is selected or
%                       deleted to enable proper interactions in EZACTI3
%               Feb 27, 2026
%                   Enable invisible instance to allow report generator
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2019 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef actigraphy2 < handle
    properties (Access = public)
        actigraphyFig
        actiAxis
        shallowAxis

        % Callback properties for gap interactions
        % They should function handles defined else where
        GapDeletedCallback = []   % Triggered after a gap is deleted
        GapSelectedCallback = []  % Triggered when selected gap changes (index or [])
    end
    
    properties (Access = public, Hidden = true)
        hostApp
        Decoration = struct('Gap', struct('PatchHandles', [], 'TextHandles', [], 'Label', {'off'}, 'SelectedIndex', [], 'ContextMenu', []), ...
            'Sleep', struct('PatchHandles', [], 'TextHandles', [], 'Label', {'off'}), ...
            'Diary', struct('PatchHandles', [], 'TextHandles', [], 'Label', {'on'}), ...
            'YLim', [], 'YAdjust', []);
    end
    
    %% construction and deletion
    methods (Access = public)
        function app = actigraphy2(varargin)
            % parse inputs
            if nargin == 0
                hostApp = [];
                nameValueArgs = {};
            elseif ischar(varargin{1}) || isstring(varargin{1})
                % Called as actigraphy2('Hidden', true) or with other name-value pairs
                hostApp = [];
                nameValueArgs = varargin;
            else
                % Called as actigraphy2(this) or actigraphy2(this, 'Hidden', true)
                hostApp = varargin{1};
                nameValueArgs = varargin(2:end);
            end

            app.hostApp = hostApp;

            p = inputParser;
            addParameter(p, 'Visible', true, @islogical);
            parse(p, nameValueArgs{:});

            pos = CenterFig(1.4/2, 1.4/2, 'norm');
            app.actigraphyFig = figure('Color', 'w', ...
                'Units', 'norm', ...
                'Position', pos, ...
                'Name', 'Actigraphy', ...
                'NumberTitle', 'off', ...
                'Visible', p.Results.Visible);
            
            app.actigraphyFig.MenuBar = 'none';
            app.actigraphyFig.Tag     = 'actigraphyFig';
            
            app.actiAxis = axes(app.actigraphyFig, ...
                'Units', 'normalized', ...
                'Position', [.07 .1 .86 .79], ...
                'ActivePositionProperty', 'position', ...
                'Box', 'off', ...
                'TickDir', 'out', ...
                'FontSize', 8);
            
            app.shallowAxis = axes(app.actigraphyFig, ...
                'Units', 'normalized', ...
                'Position', [.07 .85 .86 .04], ...
                'ActivePositionProperty', 'position', ...
                'XAxisLocation', 'top', ...
                'Box', 'off', ...
                'YTick', '', ...
                'TickDir', 'out', ...
                'FontSize', 8);
            
            linkaxes([app.shallowAxis, app.actiAxis], 'x');

            app.shallowAxis.Color  = 'none';
            app.shallowAxis.XColor = 'k';
            
            app.actiAxis.Layer    = 'top';
            app.actiAxis.XColor   = 'k';
            app.actiAxis.YColor   = 'k';
            
            % customized axis toolbar postcallback
            zoomToggle = zoom(app.actigraphyFig);
            zoomToggle.ActionPostCallBack = {@postCallbackFcn, app};
            
            panToggle  = pan(app.actigraphyFig);
            panToggle.ActionPostCallback  = {@postCallbackFcn, app};
            
            cursorToggle = datacursormode(app.actigraphyFig);
            cursorToggle.UpdateFcn = {@updateFcn, app};
            
            app.actiAxis.Toolbar.Visible    = 'on';
            app.shallowAxis.Toolbar.Visible = 'off';
        end
        
        function delete(app)
            delete(app.actigraphyFig);
        end
    end

    %% interaction
    methods
        function highlightGapByIndex(this, index)
            if isempty(index) || index < 1 || index > length(this.Decoration.Gap.PatchHandles)
                index = [];
            end

            if isvalid(this.Decoration.Gap.PatchHandles)
                set(this.Decoration.Gap.PatchHandles, 'FaceColor', 'm', 'EdgeColor', 'm', 'FaceAlpha', 0.1);
            end

            if ~isempty(index)
                set(this.Decoration.Gap.PatchHandles(index), 'FaceColor', 'r', 'EdgeColor', 'r', 'FaceAlpha', 0.5);
            end

            % store and trigger callback if selection changed
            if ~isequal(this.Decoration.Gap.SelectedIndex, index)
                this.Decoration.Gap.SelectedIndex = index;
                if ~isempty(this.GapSelectedCallback)
                    this.GapSelectedCallback(index);
                end
            end
        end
        
        function highlightGapPatch(this, src, evt)
            if evt.Button ~= 1  % Only highlight on left click
                return;
            end
            index = find(this.Decoration.Gap.PatchHandles == src);
            if ~isempty(index)
                this.highlightGapByIndex(index);
            end
        end
        
        function deleteGapCallback(this, src, evt)
            patchHandle = gco;

            index = find(this.Decoration.Gap.PatchHandles == patchHandle);
            if ~isempty(index)
                this.deleteSingleGap(index);

                % update hostApp's Gap so that the caller can have the
                % right data
                this.hostApp.Gap(index, :) = [];

                % Trigger deletion callback (passes deleted index)
                if ~isempty(this.GapDeletedCallback)
                    this.GapDeletedCallback(index);
                end
            end
        end
        
        function deleteSingleGap(this, index)
            if index < 1 || index > length(this.Decoration.Gap.PatchHandles)
                return;
            end
            delete(this.Decoration.Gap.PatchHandles(index));
            this.Decoration.Gap.PatchHandles(index) = [];
            
            if ~isempty(this.Decoration.Gap.TextHandles) && length(this.Decoration.Gap.TextHandles) >= index
                delete(this.Decoration.Gap.TextHandles(index));
                this.Decoration.Gap.TextHandles(index) = [];
            end
            
            % Adjust selected index if needed
            if this.Decoration.Gap.SelectedIndex == index
                this.Decoration.Gap.SelectedIndex = [];
            elseif this.Decoration.Gap.SelectedIndex > index
                this.Decoration.Gap.SelectedIndex = this.Decoration.Gap.SelectedIndex - 1;
            end
        end
    end
end

function postCallbackFcn(obj, event, app)
if ~isempty(app.hostApp)
    if app.hostApp.timeSet
        peerXTick = app.actiAxis.XTick;
        xTick     = app.hostApp.TimeInfo.StartDate + seconds(app.hostApp.Epoch).*(peerXTick - app.hostApp.Point(1));
        app.shallowAxis.XTick = peerXTick;
        app.shallowAxis.XTickLabel = string(xTick, 'dd-MMM-yyyy HH:mm');
        app.shallowAxis.XTickLabelRotation = 10;
    end
end
end

function txt = updateFcn(obj, event, app)
pos = get(event, 'Position');

if ~isempty(app.hostApp)
    if app.hostApp.timeSet
        txt = {['Index: ', num2str(pos(1))], ...
            ['Time: ', char(string(app.hostApp.TimeInfo.StartDate + seconds(app.hostApp.Epoch).*(pos(1) - app.hostApp.Point(1)), 'dd-MMM-yyyy HH:mm:ss'))], ['Amplitude: ', num2str(pos(2))]};
    else
        txt = {['Index: ', num2str(pos(1))], ['Amplitude: ', num2str(pos(2))]};
    end
end
end