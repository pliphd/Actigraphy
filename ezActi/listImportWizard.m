% Import Wizard
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%                   Division of Sleep Medicine, Brigham & Women's Hospital
%                   Division of Sleep Medicine, Harvard Medical School
%   $Date:    Dec 23, 2019
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2019 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef listImportWizard < handle
    properties (Access = private)
        Panel
        showlistEdit
        chooselistButton
        fileList
        
        datapathEdit
        datapathButton
        
        importButton
        
        tabGroup
        epiTab
        epiCheckbox
        epiEdit
        epiText
        
        gapTab
        gapCheckbox
        gapEdit
        gapText
        
        epochEdit
        epochText
        unitText
    end
    
    properties (Access = public)
        wizardFigure
        imported = 0
        
        DataPath
        FileList
        
        epoch
        
        epiSuffix   = '.gap'
        epiImported = 0;
        
        gapSuffix   = '.gap'
        gapImported = 0
    end
    
    methods (Access = public)
        function app = listImportWizard
            createComponents(app);
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            Pos = CenterFig(534, 300, 'pixels');
            app.wizardFigure = uifigure('Color', 'w', 'Units', 'pixels', 'Position', Pos, ...
                'Name', 'Data import wizard', ...
                'NumberTitle', 'off', 'Resize', 'off');
            app.Panel = uipanel(app.wizardFigure, 'Position', [8 8 520 286], ...
                'BackgroundColor', 'w');
            
            % define file list
            app.showlistEdit = uieditfield(app.Panel, 'text', ...
                'Position', [40 250 475 20], 'HorizontalAlignment', 'left', ...
                'Value', 'Choose a list file ...');
            app.chooselistButton = uibutton(app.Panel, ...
                'Position', [5 250 30 20], 'Text', '...', 'ButtonPushedFcn', @(source, event) ListButtonCallback(app, source, event));
            
            % list file names
            app.fileList = uilistbox(app.Panel, 'Position', [5 5 250 235], 'Items', {}, 'Value', {});
            
            % data path
            app.datapathEdit = uieditfield(app.Panel, ...
                'Position', [350 115 165 20], 'HorizontalAlignment', 'left');
            app.datapathButton = uibutton(app.Panel, 'Text', 'Data folder', ...
                'Position', [260 115 80 20], 'ButtonPushedFcn', @(source, event) DatapathButtonCallback(app, source, event));
            
            % episode choice
            app.tabGroup = uitabgroup(app.Panel, 'Position', [260 150 255 89]);
            
            app.epiTab   = uitab(app.tabGroup, 'Title', 'episode', 'BackgroundColor', 'w');
            app.epiCheckbox = uicheckbox(app.epiTab, ...
                'Position', [10 35 80 15], 'Text', 'Allow', ...
                'ValueChangedFcn', @(source, event) epiCheckboxCallback(app, source, event));
            app.epiEdit = uieditfield(app.epiTab, ...
                'Position', [90 10 155 20], 'HorizontalAlignment', 'left', 'Enable', 'off', 'Value', '.gap', 'ValueChangedFcn', @(source, event) epiEditCallback(app, source, event));
            app.epiText = uilabel(app.epiTab, ...
                'Position', [20 10 65 20], 'Text', 'epi suffix:', 'HorizontalAlignment', 'right', 'Enable', 'off', 'BackgroundColor', 'w');
            
            app.gapTab   = uitab(app.tabGroup, 'Title', 'gap', 'BackgroundColor', 'w');
            app.gapCheckbox = uicheckbox(app.gapTab, ...
                'Position', [10 35 80 15], 'Text', 'Allow', ...
                'ValueChangedFcn', @(source, event) gapCheckboxCallback(app, source, event));
            app.gapEdit = uieditfield(app.gapTab, ...
                'Position', [90 10 155 20], 'HorizontalAlignment', 'left', 'Enable', 'off', 'Value', '.gap', 'ValueChangedFcn', @(source, event) gapEditCallback(app, source, event));
            app.gapText = uilabel(app.gapTab, ...
                'Position', [20 10 65 20], 'Text', 'gap suffix:', 'HorizontalAlignment', 'right', 'Enable', 'off', 'BackgroundColor', 'w');
            
            % epoch
            app.epochEdit = uieditfield(app.Panel, ...
                'Position', [350 90 25 20], 'HorizontalAlignment', 'right', 'Value', '', 'ValueChangedFcn', @(source, event) EpochEditCallback(app, source, event));
            app.epochText = uilabel(app.Panel, ...
                'Position', [300 90 40 20], 'Text', 'epoch:', 'HorizontalAlignment', 'right', 'BackgroundColor', 'w');
            app.unitText  = uilabel(app.Panel, ...
                'Position', [380 90 155 20], 'HorizontalAlignment', 'left', 'Text', 'sec');
            
            % confirm
            app.importButton = uibutton(app.Panel, 'Text', 'Import', ...
                'Position', [465 5 50 20], 'ButtonPushedFcn', @(source, event) ImportButtonCallback(app, source, event));
        end
    end
    
    methods (Access = private)
        function app = ListButtonCallback(app, source, event)
            [filename, pathname] = uigetfile('*.txt', 'Choose a file that lists data records ...');
            
            if filename == 0
                return;
            end
            
            listpath = fullfile(pathname, filename);
            app.showlistEdit.Value = listpath;
            
            fid     = fopen(listpath, 'r');
            allList = textscan(fid, '%s', 'Delimiter', '\n');
            fclose(fid);
            
            app.FileList = allList{1};
            app.fileList.Items = app.FileList;
        end
        
        function app = DatapathButtonCallback(app, source, event)
            app.DataPath = uigetdir('.', 'Choose a folder that contains all data recordings ...');
            if app.DataPath == 0
                return;
            end
            app.datapathEdit.Value = app.DataPath;
        end
        
        function app = EpochEditCallback(app, source, event)
            app.epoch = source.Value;
        end
        
        function app = epiCheckboxCallback(app, source, event)
            if app.epiCheckbox.Value == 1
                app.epiEdit.Enable = 'on';
                app.epiText.Enable = 'on';
                app.epiImported    = 1;
            else
                app.epiEdit.Enable = 'off';
                app.epiText.Enable = 'off';
                app.epiImported    = 0;
            end
        end
        
        function app = epiEditCallback(app, source, event)
            app.epiSuffix   = source.Value;
            app.epiImported = 1;
        end
        
        function app = gapCheckboxCallback(app, source, event)
            if app.gapCheckbox.Value == 1
                app.gapEdit.Enable = 'on';
                app.gapText.Enable = 'on';
                app.gapImported    = 1;
            else
                app.gapEdit.Enable = 'off';
                app.gapText.Enable = 'off';
                app.gapImported    = 0;
            end
        end
        
        function app = gapEditCallback(app, source, event)
            app.gapSuffix   = source.Value;
            app.gapImported = 1;
        end
        
        function app = ImportButtonCallback(app, source, event)
            if ~isempty(app.fileList.Items) && ~isempty(app.datapathEdit.Value) && ~isempty(app.epochEdit.Value)
                app.imported = 1;
            end
            closereq;
        end
    end
end