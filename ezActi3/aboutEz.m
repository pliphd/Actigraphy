% About
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%   $Date:    May 16, 2018
%   $Modif.:  Nov 15, 2022
%             Oct 15, 2025
%               simply and adjust layout
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2016 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef aboutEz < handle
    properties (Access = private)
        AboutEZFigure
        icanAxes
        logButton
        verLabel
        rightLabel
        ackLabel
    end
    
    methods (Access = public)
        function app = aboutEz(varargin)
            createComponents(app);
            
            if nargin == 0
                icon2Read = 'EZEntropy.png';
                app.AboutEZFigure.Name = 'About EZ Entropy';
            elseif nargin >= 2
                app.AboutEZFigure.Name = varargin{1};
                icon2Read = varargin{2};
            end
            
            [im, ~, imalpha] = imread(icon2Read);
            image(im, 'Parent', app.icanAxes, 'AlphaData', imalpha);
            app.icanAxes.XLim = [1 200];
            app.icanAxes.YLim = [1 160];
            app.icanAxes.XTick = [];
            app.icanAxes.YTick = [];
            app.icanAxes.XColor = 'none';
            app.icanAxes.YColor = 'none';
            app.icanAxes.Toolbar.Visible = 'off';
            
            if nargin == 3
                app.verLabel.Text = varargin{3};
            end
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            Pos = CenterFig(428, 240, 'pixels');
            app.AboutEZFigure = uifigure('Color', 'w', 'Units', 'pixels', 'Position', Pos, ...
                'Name', 'About', ...
                'NumberTitle', 'off', 'Resize', 'off');

            % using gridlayout
            gFigure = uigridlayout(app.AboutEZFigure, 'BackgroundColor', 'w');
            gFigure.RowHeight   = repmat({'1x'}, 1, 14);
            gFigure.ColumnWidth = repmat({'1x'}, 1, 4);
            
            app.icanAxes = uiaxes(gFigure, ...
                'BackgroundColor', 'w');
            app.icanAxes.Layout.Row    = [1 11];
            app.icanAxes.Layout.Column = [1 2];
            
            app.logButton = uibutton(gFigure, 'Text', 'Develop log', ...
                'BackgroundColor', 'w', 'ButtonPushedFcn', @(source, event) logButtonPushedFcn(app, source, event));
            app.logButton.Layout.Row    = [13 14];
            app.logButton.Layout.Column = 2;
            
            app.verLabel = uilabel(gFigure, 'BackgroundColor', 'w', ...
                'Text', {'Version: 1.1.0104'; 'Jan 4, 2024'; 'Licence: developer'});
            app.verLabel.Layout.Row    = [1 2];
            app.verLabel.Layout.Column = [3 4];
            
            app.rightLabel = uilabel(gFigure, 'BackgroundColor', 'w', ...
                'Text', {'© 2016- '; '© Peng Li'; 'A product of the E-Z series.'; ''; 'Developer: Peng Li, Ph.D.'});
            app.rightLabel.Layout.Row    = [3 8];
            app.rightLabel.Layout.Column = [3 4];
            
            app.ackLabel = uilabel(gFigure, 'BackgroundColor', 'w', ...
                'Text', {'Acknowledgment:'; 'MATLAB is registered trademarks'; 'of The MathWorks, Inc.'; ''; 'A deep sense of gratitude to my'; 'wife, my son, and my daughter.'}, ...
                'VerticalAlignment', 'bottom');
            app.ackLabel.Layout.Row    = [9 14];
            app.ackLabel.Layout.Column = [3 4];
        end
    end
    
    methods (Access = private)
        function app = logButtonPushedFcn(app, source, event)
            
        end
    end
end