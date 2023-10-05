%ACTOGRAM
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%   $Date:    Jan 01, 2022
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2019 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef actogram < handle
    properties (Access = public)
        actigraphyFig
        actiAxis
    end
    
    properties (Access = public, Hidden = true)
        hostApp
    end
    
    %% construction and deletion
    methods (Access = public)
        function app = actogram(varargin)
            if nargin == 1
                app.hostApp = varargin{1};
            else
                app.hostApp = [];
            end
            
            pos = CenterFig(.8/2, 1.3/2, 'norm');
            app.actigraphyFig = figure('Color', 'w', ...
                'Units', 'norm', ...
                'Position', pos, ...
                'Name', 'Actogram', ...
                'NumberTitle', 'off');
            
            app.actigraphyFig.MenuBar = 'none';
            app.actigraphyFig.Tag     = 'actogramFig';
            
            app.actiAxis = axes(app.actigraphyFig, ...
                'Units', 'normalized', ...
                'Position', [.14 .1 .81 .85], ...
                'ActivePositionProperty', 'position', ...
                'Box', 'off', ...
                'TickDir', 'out', ...
                'FontSize', 8);
            
            app.actiAxis.Layer    = 'top';
            app.actiAxis.XColor   = 'k';
            app.actiAxis.YColor   = 'k';
            
%             % customized axis toolbar postcallback
%             zoomToggle = zoom(app.actigraphyFig);
%             zoomToggle.ActionPostCallBack = {@postCallbackFcn, app};
%             
%             panToggle  = pan(app.actigraphyFig);
%             panToggle.ActionPostCallback  = {@postCallbackFcn, app};
%             
%             cursorToggle = datacursormode(app.actigraphyFig);
%             cursorToggle.UpdateFcn = {@updateFcn, app};
%             
            app.actiAxis.Toolbar.Visible    = 'on';
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
        xTick     = app.hostApp.TimeInfo.StartDate + seconds(app.hostApp.Epoch).*(peerXTick - app.hostApp.Point(1));
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
            ['Time: ', datestr(app.hostApp.TimeInfo.StartDate + seconds(app.hostApp.Epoch).*(pos(1) - app.hostApp.Point(1)), 'dd-mmm-yyyy HH:MM:ss')], ['Amplitude: ', num2str(pos(2))]};
    else
        txt = {['Index: ', num2str(pos(1))], ['Amplitude: ', num2str(pos(2))]};
    end
end
end