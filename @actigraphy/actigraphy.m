%ACTIGRAPHY
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%   $Date:    Dec 23, 2019
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2019 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef actigraphy < handle
    properties (Access = public)
        actigraphyFig
        actiAxis
        shallowAxis
    end
    
    properties (Access = public, Hidden = true)
        hostApp
    end
    
    %% construction and deletion
    methods (Access = public)
        function app = actigraphy(varargin)
            if nargin == 1
                app.hostApp = varargin{1};
            else
                app.hostApp = [];
            end
            
            pos = CenterFig(1.4/2, 1.4/2, 'norm');
            app.actigraphyFig = figure('Color', 'w', 'Units', 'norm', 'Position', pos, 'Name', 'Actigraphy', 'NumberTitle', 'off');
            app.actigraphyFig.MenuBar = 'none';
            app.actigraphyFig.Tag     = 'actigraphyFig';
            
            app.actiAxis      = axes(app.actigraphyFig, 'Units', 'normalized', 'Position', [.07 .1 .86 .8],  'ActivePositionProperty', 'position', ...
                'Box', 'off', 'TickDir', 'out');
            app.shallowAxis   = axes(app.actigraphyFig, 'Units', 'normalized', 'Position', [.07 .85 .86 .05], 'ActivePositionProperty', 'position', ...
                'XAxisLocation', 'top', 'Box', 'off', 'YTick', '', 'TickDir', 'out');
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
        end
        
        function delete(app)
            delete(app.actigraphyFig);
        end
    end
end

function postCallbackFcn(obj, event, app)
if ~isempty(app.hostApp)
    if app.hostApp.timeSet
        peerXTick = app.actiAxis.XTick;
        xTick     = app.hostApp.startTime + seconds(app.hostApp.epoch).*peerXTick - app.hostApp.x(1).*seconds(app.hostApp.epoch);
        app.shallowAxis.XTick = peerXTick;
        app.shallowAxis.XTickLabel = datestr(xTick, 'dd-mmm-yyyy HH:MM');
        app.shallowAxis.XTickLabelRotation = 10;
    end
end
end

function txt = updateFcn(obj, event, app)
pos = get(event, 'Position');

if ~isempty(app.hostApp)
    if app.hostApp.timeSet
        txt = {['Index: ', num2str(pos(1))], ...
            ['Time: ', datestr(app.hostApp.startTime + seconds(app.hostApp.epoch).*pos(1) - app.hostApp.x(1).*seconds(app.hostApp.epoch), 'dd-mmm-yyyy HH:MM:ss')], ['Amplitude: ', num2str(pos(2))]};
    else
        txt = {['Index: ', num2str(pos(1))], ['Amplitude: ', num2str(pos(2))]};
    end
end
end