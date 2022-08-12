% config
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%                   Division of Sleep Medicine, Brigham & Women's Hospital
%                   Division of Sleep Medicine, Harvard Medical School
%   $Date:    April 07, 2020
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2020 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef dfaConfig < handle
    properties (Access = private)
        Panel
        
        typeText
        typeDrop
        
        orderText
        orderEdit
        
        minText
        minEdit
        
        windowText
        windowEdit
        windowUnit
        
        regionText
        regionTable
        
        addButton
        runButton
        autoButton
        closeButton
        
        savePanel
        figCheck
        numCheck
        
        plotApp
    end
    
    properties (Access = public)
        wizardFigure
        hostApp
        returned = 0
        
        analysisType = 'DFA';
        order        = 2;
        minWindows   = 6;
        window       = [];
        fitRegion    = [];
        
        saveFig      = 1;
        saveNum      = 1;
    end
    
    methods (Access = public)
        function app = dfaConfig(varargin)
            createComponents(app);
            
            if nargin >= 1
                app.hostApp = varargin{1};
            end
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            Pos = CenterFig(200, 300, 'pixels');
            app.wizardFigure = uifigure('Color', 'w', 'Units', 'pixels', 'Position', Pos, ...
                'Name', 'DFA configuration', ...
                'Tag', 'DFAConf', ...
                'NumberTitle', 'off', 'Resize', 'off');
            app.Panel = uipanel(app.wizardFigure, 'Position', [8 8 184 284], ...
                'BackgroundColor', 'w');
            
            % define components
            app.typeText = uilabel(app.Panel, ...
                'Position', [5 260 85 20], 'Text', 'Analysis type:', ...
                'HorizontalAlignment', 'right', 'BackgroundColor', 'w');
            app.typeDrop = uidropdown(app.Panel, ...
                'Position', [96 260 80 20], ...
                'Items', {'DFA', 'Amplitude'}, 'Value', 'DFA', ...
                'ValueChangedFcn', @(source, event) typeDropCallback(app, source, event));
            
            app.orderText = uilabel(app.Panel, ...
                'Position', [5 230 85 20], 'Text', 'Order:', ...
                'HorizontalAlignment', 'right', 'BackgroundColor', 'w');
            app.orderEdit = uieditfield(app.Panel, ...
                'Position', [96 230 80 20], ...
                'Value', '2', ...
                'ValueChangedFcn', @(source, event) orderEditCallback(app, source, event));
            
            app.minText = uilabel(app.Panel, ...
                'Position', [5 200 85 20], 'Text', 'Min. Windows:', ...
                'HorizontalAlignment', 'right', 'BackgroundColor', 'w');
            app.minEdit = uieditfield(app.Panel, ...
                'Position', [96 200 80 20], ...
                'Value', '6', ...
                'ValueChangedFcn', @(source, event) minEditCallback(app, source, event));
            
            app.windowText = uilabel(app.Panel, ...
                'Position', [5 170 85 20], 'Text', 'Slide window:', ...
                'HorizontalAlignment', 'right', 'BackgroundColor', 'w');
            app.minEdit = uieditfield(app.Panel, ...
                'Position', [96 170 40 20], ...
                'Value', '', ...
                'ValueChangedFcn', @(source, event) windowEditCallback(app, source, event));
            app.windowUnit = uilabel(app.Panel, ...
                'Position', [142 170 85 20], 'Text', 'hour', ...
                'HorizontalAlignment', 'left', 'BackgroundColor', 'w');
            
            app.regionText  = uilabel(app.Panel, ...
                'Position', [5 140 120 20], 'Text', 'Fit regions (in min):', ...
                'HorizontalAlignment', 'left', 'BackgroundColor', 'w');
            app.regionTable = uitable(app.Panel, ...
                'Position', [5 30 90 110], 'ColumnName', {'Start', 'End'}, ...
                'ColumnEditable', true(1, 2), ...
                'ColumnWidth', {45, 45}, ...
                'Data', nan(1, 2), ...
                'RowName', '', ...
                'CellEditCallback', @(source, event) regionTableEditCallback(app, source, event));
            
            % confirm
            app.addButton   = uibutton(app.Panel, 'Text', 'Add', ...
                'Position', [105 120 50 20], 'ButtonPushedFcn', @(source, event) addButtonCallback(app, source, event));
            app.runButton   = uibutton(app.Panel, 'Text', 'Run', ...
                'Position', [9 5 50 20], 'ButtonPushedFcn', @(source, event) runButtonCallback(app, source, event));
            app.autoButton  = uibutton(app.Panel, 'Text', 'Auto', ...
                'Position', [67 5 50 20], 'ButtonPushedFcn', @(source, event) autoButtonCallback(app, source, event));
            app.closeButton = uibutton(app.Panel, 'Text', 'Close', ...
                'Position', [125 5 50 20], 'ButtonPushedFcn', @(source, event) closeButtonCallback(app, source, event));
            
            app.savePanel = uipanel(app.Panel, 'Position', [105 30 71 80], ...
                'BackgroundColor', 'w', 'Title', 'Save');
            app.figCheck  = uicheckbox(app.savePanel, 'Position', [5 35 50 15], ...
                'Text', 'Fig', 'Value', 1, ...
                'ValueChangedFcn', @(source, event) figCheckCallback(app, source, event));
            app.numCheck  = uicheckbox(app.savePanel, 'Position', [5 15 50 15], ...
                'Text', 'Num', 'Value', 1, ...
                'ValueChangedFcn', @(source, event) numCheckCallback(app, source, event));
        end
    end
    
    methods (Access = private)
        function app = autoButtonCallback(app, source, event)
            while app.hostApp.startIndex <= length(app.hostApp.fileList)
                app.runButtonCallback;
                drawnow;
            end
            
        end
        
        function app = runButtonCallback(app, source, event)
            % send message to host app
            if ~app.hostApp.dataDefined
                return;
            end
            
            app.hostApp.loadData;
            
            if app.hostApp.startIndex > length(app.hostApp.fileList)
                return;
            end
            
            app.hostApp.loadGap;
            
            % time series
            if app.hostApp.timeSet
                t = datenum(app.hostApp.startTime) + (app.hostApp.x-1)*app.hostApp.epoch/(24*3600);
            else
                t = (app.hostApp.x-1)*app.hostApp.epoch/(24*3600);
            end
            pts = physiologicaltimeseries(app.hostApp.dataImputed, t);
            pts.Quality = gap2Series(app.hostApp.gap.data, length(t));
            
            pts.UserData = struct('Epoch', app.hostApp.epoch);
            
            pts.Name = app.hostApp.currentFileName(1:end-4);
            
            % dfa object
            theDFA       = mydfa;
                theDFA.pts   = pts;
                theDFA.order = app.order;
                theDFA.minNumMotif  = app.minWindows;
                theDFA.windowLength = app.window;
            
                theDFA.dfa
                
                theDFA.fitRegion    = app.regionTable.Data;
                theDFA.fitRegion(any(isnan(theDFA.fitRegion), 2), :) = [];
                theDFA.fit;
            
            % show and write figure
            resetDisplay(app);
            
            if app.saveFig
                theDFA.plot(app.plotApp, 'drift', 1, 'outdir', fullfile(app.hostApp.filePath, 'FigResults'));
            else
                theDFA.plot(app.plotApp, 'drift', 1);
            end
            
            % save numerical results
            if app.saveNum
                theDFA.save('outdir', fullfile(app.hostApp.filePath, 'NumResults'), 'option', 'all');
            else
                theDFA.save('outdir', fullfile(app.hostApp.filePath, 'NumResults'), 'option', 'fit');
            end
            
            % move on
            app.hostApp.startIndex = app.hostApp.startIndex + 1;
        end
        
        function app = typeDropCallback(app, source, event)
            app.analysisType = source.Value;
        end
        
        function app = orderEditCallback(app, source, event)
            app.order = str2double(source.Value);
        end
        
        function app = minEditCallback(app, source, event)
            app.minWindows = str2double(source.Value);
        end
        
        function app = windowEditCallback(app, source, event)
            app.window = str2double(source.Value);
            if isnan(app.window)
                app.window = [];
            end
        end
        
        function app = figCheckCallback(app, source, event)
            app.saveFig = source.Value;
        end
        
        function app = numCheckCallback(app, source, event)
            app.saveNum = source.Value;
        end
        
        function app = regionTableEditCallback(app, source, event)
            indices = event.Indices;
            newData = event.NewData;
            
            if ~isempty(newData)
                if isnan(newData) % delete a gap
                    data = app.regionTable.Data;
                    data(indices(1), :) = [];
                    app.regionTable.Data = data;
                else
                    % do nothing
                end
            end
        end
        
        function app = addButtonCallback(app, source, event)
            app.regionTable.Data = [app.regionTable.Data; nan(1, 2)];
        end
        
        function app = closeButtonCallback(app, source, event)
            app.returned = 1;
            closereq;
        end
    end
end

function resetDisplay(app)
if isa(app.plotApp, 'dfaPlot')
    if isempty(findobj('Tag', 'dfaPlotFig'))
        app.plotApp = dfaPlot(app);
    else
        cla(app.plotApp.actiAxis);
        cla(app.plotApp.dfaAxis);
    end
else
    if ~isempty(findobj('Tag', 'dfaPlotFig'))
        delete(findobj('Tag', 'dfaPlotFig'));
    end
    app.plotApp = dfaPlot(app);
end
end