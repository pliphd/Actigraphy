% About
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%   $Date:    May 16, 2018
%   $Modif.:  Nov 15, 2022
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2016 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef aboutEzActi < handle
    properties (Access = private)
        AboutEZFigure
        icanAxes
        logButton
        verLabel
        rightLabel
        ackLabel
    end
    
    methods (Access = public)
        function app = aboutEzActi(varargin)
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
                'Name', 'About EZ Entropy', ...
                'NumberTitle', 'off', 'Resize', 'off');
            
            app.icanAxes = uiaxes(app.AboutEZFigure, 'Position', [5 60 200 160], ...
                'BackgroundColor', 'w');
            
            app.logButton = uibutton(app.AboutEZFigure, 'Position', [100 20 105 20], 'Text', 'Develop log', ...
                'BackgroundColor', 'w', 'ButtonPushedFcn', @(source, event) logButtonPushedFcn(app, source, event));
            
            app.verLabel = uilabel(app.AboutEZFigure, 'Position', [220 180 200 45], 'BackgroundColor', 'w', ...
                'Text', {'Version: 1.0.0517'; 'May 17, 2023'; 'Licence: developer'});
            
            app.rightLabel = uilabel(app.AboutEZFigure, 'Position', [220 120 200 45], 'BackgroundColor', 'w', ...
                'Text', {'© 2016-2023 Peng Li'; 'A product of the E-Z series.'; 'Developer: Peng Li, Ph.D.'});
            
            app.ackLabel = uilabel(app.AboutEZFigure, 'Position', [220 20 200 85], 'BackgroundColor', 'w', ...
                'Text', {'Acknowledgment:'; 'MATLAB is registered trademarks'; 'of The MathWorks, Inc.'; ''; 'A deep sense of gratitude to my'; 'wife, my son, and my daughter.'});
        end
    end
    
    methods (Access = private)
        function app = logButtonPushedFcn(app, source, event)
            
        end
    end
end