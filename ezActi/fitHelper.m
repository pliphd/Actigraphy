% Fit Helper
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%                   Division of Sleep Medicine, Brigham & Women's Hospital
%                   Division of Sleep Medicine, Harvard Medical School
%   $Date:    Dec 26, 2019
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2019 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef fitHelper < handle
    properties (Access = private)
        Panel
        
        fitIfLessThanText
        fitIfLessThanEdit
        pointText
        
        fitMethodText
        fitMethodDropdown
        
        fitWindowLengthText
        fitWindowLengthEdit
        pointText2
        
        fitSaveCheckbox
        
        goButton
    end
    
    properties (Access = public)
        wizardFigure
        go = 0
        
        fitIfLessThan
        fitMethod = 'Centered mean'
        fitWindowLength
        
        fitSave = 1
    end
    
    methods (Access = public)
        function app = fitHelper(varargin)
            createComponents(app);
            if nargin == 1
                hostApp = varargin{1};
                app.fitIfLessThanEdit.Value = num2str(hostApp.gapImputationCrit);
                app.fitIfLessThan = hostApp.gapImputationCrit;
                
                app.fitWindowLengthEdit.Value = num2str(hostApp.gapImputationWindow);
                app.fitWindowLength = hostApp.gapImputationWindow;
                
                app.fitMethodDropdown.Value = hostApp.gapImputationMethod;
                app.fitMethod = hostApp.gapImputationMethod;
                
                app.fitSaveCheckbox.Value = hostApp.gapImputationSave;
                app.fitSave = hostApp.gapImputationSave;
            end
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            Pos = CenterFig(200, 300, 'pixels');
            app.wizardFigure = uifigure('Color', 'w', 'Units', 'pixels', 'Position', Pos, ...
                'Name', 'Data imputation configuration', ...
                'NumberTitle', 'off', 'Resize', 'off');
            app.Panel = uipanel(app.wizardFigure, 'Position', [8 8 186 286], ...
                'BackgroundColor', 'w');
            
            app.fitIfLessThanEdit = uieditfield(app.Panel, ...
                'Position', [10 235 50 20], 'HorizontalAlignment', 'left', ...
                'ValueChangedFcn', @(source, event) fitIfLessThanEditCallback(app, source, event));
            app.fitIfLessThanText = uilabel(app.Panel, ...
                'Position', [10 260 200 20], 'Text', 'Impute if less than:', 'HorizontalAlignment', 'left', 'BackgroundColor', 'w');
            app.pointText = uilabel(app.Panel, ...
                'Position', [70 235 60 20], 'Text', 'points', 'HorizontalAlignment', 'left', 'BackgroundColor', 'w');
            
            app.fitWindowLengthEdit = uieditfield(app.Panel, ...
                'Position', [10 170 50 20], 'HorizontalAlignment', 'left', ...
                'ValueChangedFcn', @(source, event) fitWindowLengthEditCallback(app, source, event));
            app.fitWindowLengthText = uilabel(app.Panel, ...
                'Position', [10 195 200 20], 'Text', 'Window length:', 'HorizontalAlignment', 'left', 'BackgroundColor', 'w');
            app.pointText2 = uilabel(app.Panel, ...
                'Position', [70 170 60 20], 'Text', 'points', 'HorizontalAlignment', 'left', 'BackgroundColor', 'w');
            
            app.fitMethodText = uilabel(app.Panel, ...
                'Position', [10 130 200 20], 'Text', 'Impute method:', 'HorizontalAlignment', 'left', 'BackgroundColor', 'w');
            app.fitMethodDropdown = uidropdown(app.Panel, ...
                'Position', [10 105 120 20], 'Items', {'Centered mean', 'Linear interp'}, 'Value', 'Centered mean', ...
                'ValueChangedFcn', @(source, event) fitMethodDropdownCallback(app, source, event));
            
            app.fitSaveCheckbox = uicheckbox(app.Panel, ...
                'Position', [10 70 200 20], 'Text', 'Save imputed data?', ...
                'ValueChangedFcn', @(source, event) fitSaveCheckboxCallback(app, source, event));
            
            % confirm
            app.goButton = uibutton(app.Panel, 'Text', 'Go', ...
                'Position', [130 5 50 20], 'ButtonPushedFcn', @(source, event) goButtonCallback(app, source, event));
        end
    end
    
    methods (Access = private)
        
        function app = fitIfLessThanEditCallback(app, source, event)
            app.fitIfLessThan = str2double(source.Value);
        end
        
        function app = fitWindowLengthEditCallback(app, source, event)
            app.fitWindowLength = str2double(source.Value);
        end
        
        function app = fitMethodDropdownCallback(app, source, event)
            app.fitMethod = source.Value;
        end
        
        function app = fitSaveCheckboxCallback(app, source, event)
            app.fitSave = source.Value;
        end
        
        function app = goButtonCallback(app, source, event)
            if ~isempty(app.fitIfLessThan) && ~isempty(app.fitWindowLength) && ~isempty(app.fitMethod)
                app.go = 1;
            end
            closereq;
        end
    end
end