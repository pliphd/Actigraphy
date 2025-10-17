% Import Wizard 2
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%   $Date:    Dec 23, 2019
%   $Modif.:  Dec 02, 2021
%               version 2
%                   interface major reorders
%                   add time parser here and remove module from main
%                       interface
%             May 17, 2023
%               Option parser--parse predefined separators bug
%             Oct 17, 2025
%               update to ver. 3. remove Nap, add Raw Data setting
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2019 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef ImportWizard3 < handle
    properties (Access = private)
        % main interface
        TabGroup
        ImportTab
        ImportOptionsTab
        ConfigTab
        RawTab
        
        % 1. Import Tab
        UpButton
        OpenButton
        Tree
        
        FileOverViewText
        FileOverViewList
        
        AllInButton
        InButton
        OutButton
        AllOutButton
        
        SelectedFileText
        SelectedFileList
        
        % 2. Import Options Tab
        % 2.1 Run mode
        RunModeText
        RunModeDropdown
        ImportExistedCheckbox
        ImportExistedFileExtensionEditor
        ImportExistedFileExtensionEditorLabel
        
        % 2.2 Gap
        ImportGapText
        ImportGapCheckbox
        ImportGapFileExtensionEditor
        ImportGapFileExtensionEditorLabel
        
        % 3. Config Tab
        % 3.-1 plot options
        VisualizeOptionsText
        ActigraphyCheckbox
        ActogramCheckbox
        ClockCheckbox
        
        % 3.0 save options
        SaveOptionsText
        DetailedResultsCheckbox
        SummaryReportsCheckbox
        FiguresCheckbox
        FigureExtDropdown
        FigureExtLabel
        
        % 3.1 Time parser
        TimeParserText
        TimeParserDropdown
        
        TimeParserAllSameEditor
        TimeParserAllSameEditorLabel
        
        TimeParserFormatLabel
        TimeParserFormatEditor
        
        TimeParserCheckButton
        TimeParserIndicatorLabel
        TimeParserIndicatorEdit
        TimeParserMessageResults
        
        % 3.2 Epoch parser
        EpochParserText
        EpochParserDropdown
        
        EpochParserAllSameEditor
        EpochParserAllSameEditorLabel
        
        EpochParserDatetimeFieldEditor
        EpochParserDatetimeFieldLabel
        
        EpochParserCheckButton
        EpochParserIndicatorLabel
        EpochParserIndicatorEdit
        EpochParserMessageResults
        
        % 3.3 Decoder
        DecoderText
        DecoderSeperatorLabel
        DecoderSeperatorUnderscoreCheckbox
        DecoderSeperatorPeriodCheckbox
        DecoderSeperatorHyphenCheckbox
        DecoderSeperatorUserCheckbox
        DecoderSeperatorUserEditor
        SeparatorDetailLabel
        SeparatorDetail

        % 4. Raw Tab
        AdvancedText
        NonMovingThresholdEditor
        NonMovingThresholdEditorLabel
        NonMovingDurationEditor
        NonMovingDurationEditorLabel
        BackgroundNoiseThresholdEditor
        BackgroundNoiseThresholdEditorLabel
        PlotCalibrationCheckbox
        PlotAccPlusCountsCheckbox
        
        % 5. bottom
        SampleFilenameLabel
        
        ConfirmButton
        CancelButton
    end
    
    properties (Access = private)
        % data related
        topFolder
        files
        selectedFilesIndex
        selectedFilesIndex_
        removeFilesIndex
        
        % configuration related
        filenameSeparatorPool = num2cell('_.-');
        filenameSeparator = {'_'};
        
        % fire parent
        fire = ''
    end
    
    properties (Access = public)
        WizardFigure
        
        % data related
        dataFolder
        selectedFiles
        
        % structured
        configStruct = struct('RunMode', {'Gap'}, ...
            'ExistedFlag', 0, ...
            'ExistedExtension', {''}, ...
            'Gap', 0, ...
            'GapExtension', {''}, ...
            'Actogram', 0, ...
            'PolarClock', 0, ...
            'SummaryReport', 0, ...
            'Figures', 0, ...
            'FigureExt', '.jgp', ...
            'TimeParserMode', {'None'}, ...
            'TimeParserProperties', ...
                struct('SameDateTime', '', ...
                'DateTimeFileLocation', '', ...
                'DatetimeInd', 1, ...
                'DatetimeFormat', 'yyyyMMddHHmmss'), ...
            'EpochParserMode', {'None'}, ...
            'EpochParserProperties', ...
                struct('SameEpoch', 15, ...
                'EpochFileLocation', '', ...
                'EpochInd', 1), ...
            'FileNameSeparator', '_', ...
            'RawSetting', ...
                struct('NonMovingThreshold', 0.01, ...
                'NonMovingDuration', 10, ...
                'BackgroundNoise', 0.02, ...
                'PlotCalibration', 1, ...
                'PlotAccCounts', 1))
        
        % global flag
        imported = 0
    end
    
    methods (Access = public)
        function app = ImportWizard3(varargin)
            createComponents(app);
            
            % first arg should be the menu title who fires this call
            if nargin >= 1
                switch varargin{1}
                    case '&Import Wizard'
                        app.fire = 'Import';
                    case '&Option'
                        app.fire = 'Option';
                        app.TabGroup.SelectedTab = app.ConfigTab;
                        
                        % in this case, configuration set previously should
                        % be fed here
                        % these inputs should follow the first arg
                        app = app.loadConfig(varargin{2}, varargin{3});
                    case 'Advanced'
                        app.fire = 'Raw';
                        app.TabGroup.SelectedTab = app.RawTab;
                        app = app.loadRawConfig(varargin{2}, varargin{3});
                end
            end
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            % center window
            pos = CenterFig(647, 400, 'pixels');
            
            app.WizardFigure = uifigure('Color', 'w', ...
                'Units', 'pixels', 'Position', pos, 'Resize', 'off', ...
                'Name', 'Import Wizard', ...
                'NumberTitle', 'off');
            
            gFigure = uigridlayout(app.WizardFigure);
            gFigure.RowHeight   = repmat({'1x'}, 1, 10);
            gFigure.ColumnWidth = repmat({'1x'}, 1, 7);
            
            app.TabGroup  = uitabgroup(gFigure, ...
                'TabLocation', 'top');
            app.TabGroup.Layout.Row    = [1 length(gFigure.RowHeight)-1];
            app.TabGroup.Layout.Column = [1 7];
            app.TabGroup.SelectionChangedFcn = @(source, event) tabGroupValueChg(app, source, event);
            
            % tab 1
            app.ImportTab  = uitab(app.TabGroup, 'Title', 'Import');
            
            % tab 2
            app.ImportOptionsTab  = uitab(app.TabGroup, 'Title', 'Import Options');
            
            % tab 3
            app.ConfigTab = uitab(app.TabGroup, 'Title', 'Configuration');

            % tab 4
            app.RawTab = uitab(app.TabGroup, 'Title', 'Raw Data');
            
            %% layout Tab 1: Import
            gImport = uigridlayout(app.ImportTab);
            gImport.RowHeight   = repmat({'1x'}, 1, 10);
            gImport.ColumnWidth = repmat({'1x'}, 1, 16);
            
            % +++++++++++++++++++++++ 1. tree node ++++++++++++++++++++++++
            app.UpButton = uibutton(gImport, 'Tooltip', 'up one level', ...
                'Text', '');
            app.UpButton.Icon = 'folder_dir_up.png';
            app.UpButton.ButtonPushedFcn = @(source, event) upDirButtonClicked(app, source, event);
            app.UpButton.Layout.Row    = 1;
            app.UpButton.Layout.Column = 1;
            
            app.OpenButton = uibutton(gImport, 'Tooltip', 'select a folder', ...
                'Text', '');
            app.OpenButton.Icon = 'folder_open.png';
            app.OpenButton.ButtonPushedFcn = @(source, event) openButtonClicked(app, source, event);
            app.OpenButton.Layout.Row    = 1;
            app.OpenButton.Layout.Column = 2;
            
            app.Tree = uitree(gImport);
            app.Tree.Layout.Row    = [2 numel(gImport.RowHeight)];
            app.Tree.Layout.Column = [1 5];
            
            % default = current working directory
            app.topFolder = cd;
            dirNode(app.Tree, cd);
            
            % select the top layer by default
            app.Tree.SelectedNodes = app.Tree.Children(1);
            app.Tree.Children(1).Icon = 'folderOpened.gif';
            
            % add callback
            app.Tree.SelectionChangedFcn = @(source, event) nodeChange(app, source, event);
            app.Tree.NodeExpandedFcn     = @(source, event) nodeExpand(app, source, event);
            
            % +++++++++++++++++++++++ 2. file overview ++++++++++++++++++++
            app.FileOverViewText = uilabel(gImport, ...
                'Text', 'Files in Folder', 'HorizontalAlignment', 'left');
            app.FileOverViewText.Layout.Row    = 1;
            app.FileOverViewText.Layout.Column = app.Tree.Layout.Column + 5;
            
            app.FileOverViewList = uilistbox(gImport, 'Items', {}, 'Value', {}, ...
                'MultiSelect', 'on');
            app.FileOverViewList.Layout.Row    = [2 numel(gImport.RowHeight)];
            app.FileOverViewList.Layout.Column = app.Tree.Layout.Column + 5;
            app.FileOverViewList.ValueChangedFcn = @(source, event) fileSelected(app, source, event);

            % 20221117 
            % open once cd to show current files in cd
            % otherwise if start with current data folder, nothing will be
            % shown in FIleOverViewList
            app.dataFolder = cd;
            app.openFolder;
            
            % +++++++++++++++++++++++ 3. file selected ++++++++++++++++++++
            app.SelectedFileText = uilabel(gImport, ...
                'Text', 'Selected Files to Import', 'HorizontalAlignment', 'left');
            app.SelectedFileText.Layout.Row    = 1;
            app.SelectedFileText.Layout.Column = app.Tree.Layout.Column + 11;
            
            app.SelectedFileList = uilistbox(gImport, 'Items', {}, 'Value', {}, ...
                'MultiSelect', 'on');
            app.SelectedFileList.Layout.Row    = [2 numel(gImport.RowHeight)];
            app.SelectedFileList.Layout.Column = app.Tree.Layout.Column + 11;
            app.SelectedFileList.ValueChangedFcn = @(source, event) fileToRemove(app, source, event);
            
            % +++++++++++++++++++++++ 4. move buttons ++++++++++++++++++++
            app.AllInButton = uibutton(gImport, 'Tooltip', 'add all', ...
                'Text', '');
            app.AllInButton.Icon = 'arrow_rightarrow_doublestem_16.png';
            app.AllInButton.IconAlignment = 'center';
            app.AllInButton.Layout.Row    = 4;
            app.AllInButton.Layout.Column = 11;
            app.AllInButton.ButtonPushedFcn = @(source, event) allInClicked(app, source, event);
            
            app.InButton = uibutton(gImport, 'Tooltip', 'add selected', ...
                'Text', '');
            app.InButton.Icon = 'arrow_hookrightarrow_16.png';
            app.InButton.IconAlignment = 'center';
            app.InButton.Layout.Row    = 5;
            app.InButton.Layout.Column = 11;
            app.InButton.ButtonPushedFcn = @(source, event) inClicked(app, source, event);
            
            app.OutButton = uibutton(gImport, 'Tooltip', 'remove selected', ...
                'Text', '');
            app.OutButton.Icon = 'arrow_hookleftarrow_16.png';
            app.OutButton.IconAlignment = 'center';
            app.OutButton.Layout.Row    = 6;
            app.OutButton.Layout.Column = 11;
            app.OutButton.ButtonPushedFcn = @(source, event) outClicked(app, source, event);
            
            app.AllOutButton = uibutton(gImport, 'Tooltip', 'remove all', ...
                'Text', '');
            app.AllOutButton.Icon = 'arrow_leftarrow_doublestem_16.png';
            app.AllOutButton.IconAlignment = 'center';
            app.AllOutButton.Layout.Row    = 7;
            app.AllOutButton.Layout.Column = 11;
            app.AllOutButton.ButtonPushedFcn = @(source, event) allOutClicked(app, source, event);
            
            %% layout Tab 2: Import Options
            gImportOptions = uigridlayout(app.ImportOptionsTab);
            gImportOptions.RowHeight   = repmat({'1x'}, 1, 10);
            gImportOptions.ColumnWidth = repmat({'1x'}, 1, 10);
            
            % +++++++++++++++++++++++ 1. run mode +++++++++++++++++++++++++
            app.RunModeText = uilabel(gImportOptions, ...
                'Text', 'Run Mode', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.RunModeText.Layout.Row    = 1;
            app.RunModeText.Layout.Column = [1 3];
            
            app.RunModeDropdown = uidropdown(gImportOptions, 'Items', {'Gap', 'Circadian', 'Sleep', 'Raw'}, ...
                'ItemsData', 1:4, 'Value', 1);
            app.RunModeDropdown.Layout.Row    = 2;
            app.RunModeDropdown.Layout.Column = [1 3];
            app.RunModeDropdown.ValueChangedFcn = @(source, event) runModeChanged(app, source, event);
            
            app.ImportExistedCheckbox = uicheckbox(gImportOptions, 'Text', 'Import Existed Results');
            app.ImportExistedCheckbox.Layout.Row    = 3;
            app.ImportExistedCheckbox.Layout.Column = [1 3];
            app.ImportExistedCheckbox.ValueChangedFcn = @(source, event) importResults(app, source, event);
            
            app.ImportExistedFileExtensionEditor = uieditfield(gImportOptions, 'text');
            app.ImportExistedFileExtensionEditor.Layout.Row    = 4;
            app.ImportExistedFileExtensionEditor.Layout.Column = 3;
            app.ImportExistedFileExtensionEditor.Enable = 'off';
            app.ImportExistedFileExtensionEditor.ValueChangedFcn = @(source, event) resultsExtChanged(app, source, event);
            
            app.ImportExistedFileExtensionEditorLabel = uilabel(gImportOptions, 'Text', 'File extension:', 'HorizontalAlignment', 'left');
            app.ImportExistedFileExtensionEditorLabel.Layout.Row    = 4;
            app.ImportExistedFileExtensionEditorLabel.Layout.Column = [1 2];
            app.ImportExistedFileExtensionEditorLabel.Enable = 'off';
            
            % +++++++++++++++++++++++ 2. gap info +++++++++++++++++++++++++
            app.ImportGapText = uilabel(gImportOptions, ...
                'Text', 'Gap', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.ImportGapText.Layout.Row    = 5;
            app.ImportGapText.Layout.Column = [1 3];
            
            app.ImportGapCheckbox = uicheckbox(gImportOptions, 'Text', 'Import Existed Gap Files');
            app.ImportGapCheckbox.Layout.Row    = 6;
            app.ImportGapCheckbox.Layout.Column = [1 3];
            app.ImportGapCheckbox.Enable = 'off';
            app.ImportGapCheckbox.ValueChangedFcn = @(source, event) importGap(app, source, event);
            
            app.ImportGapFileExtensionEditor = uieditfield(gImportOptions, 'text');
            app.ImportGapFileExtensionEditor.Layout.Row    = 7;
            app.ImportGapFileExtensionEditor.Layout.Column = 3;
            app.ImportGapFileExtensionEditor.Enable = 'off';
            app.ImportGapFileExtensionEditor.ValueChangedFcn = @(source, event) gapExtChanged(app, source, event);
            
            app.ImportGapFileExtensionEditorLabel = uilabel(gImportOptions, 'Text', 'File extension:', 'HorizontalAlignment', 'left');
            app.ImportGapFileExtensionEditorLabel.Layout.Row    = 7;
            app.ImportGapFileExtensionEditorLabel.Layout.Column = [1 2];
            app.ImportGapFileExtensionEditorLabel.Enable = 'off';
            
            %% layout Tab 3: Configuration
            gConfig = uigridlayout(app.ConfigTab);
            gConfig.RowHeight   = repmat({'1x'}, 1, 10);
            gConfig.ColumnWidth = repmat({'1x'}, 1, 10);
            
            % +++++++++++++++++++++++ -1. plot options ++++++++++++++++++++
            app.VisualizeOptionsText = uilabel(gConfig, ...
                'Text', 'Visualization', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.VisualizeOptionsText.Layout.Row    = 1;
            app.VisualizeOptionsText.Layout.Column = [1 3];
            
            app.ActigraphyCheckbox = uicheckbox(gConfig, 'Text', 'Actigraphy', 'Value', 1);
            app.ActigraphyCheckbox.Layout.Row    = 2;
            app.ActigraphyCheckbox.Layout.Column = [1 3];
            app.ActigraphyCheckbox.Enable = 'off';
            
            app.ActogramCheckbox = uicheckbox(gConfig, 'Text', 'Actogram', 'Value', 0);
            app.ActogramCheckbox.Layout.Row    = 3;
            app.ActogramCheckbox.Layout.Column = [1 3];
            app.ActogramCheckbox.ValueChangedFcn = @(source, event) generalConfigCheckboxChanged(app, source, event);
            app.ActogramCheckbox.UserData = 'actogram';
            
            app.ClockCheckbox = uicheckbox(gConfig, 'Text', 'Circadian polar plot');
            app.ClockCheckbox.Layout.Row    = 4;
            app.ClockCheckbox.Layout.Column = [1 3];
            app.ClockCheckbox.ValueChangedFcn = @(source, event) generalConfigCheckboxChanged(app, source, event);
            app.ClockCheckbox.UserData = 'clock';
            
            % +++++++++++++++++++++++ 0. save options +++++++++++++++++++++
            app.SaveOptionsText = uilabel(gConfig, ...
                'Text', 'Save', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.SaveOptionsText.Layout.Row    = 6;
            app.SaveOptionsText.Layout.Column = [1 3];
            
            app.DetailedResultsCheckbox = uicheckbox(gConfig, 'Text', 'Individual results', 'Value', 1);
            app.DetailedResultsCheckbox.Layout.Row    = 7;
            app.DetailedResultsCheckbox.Layout.Column = [1 3];
            app.DetailedResultsCheckbox.Enable = 'off';
            
            app.SummaryReportsCheckbox = uicheckbox(gConfig, 'Text', 'Summary reports', 'Value', 0);
            app.SummaryReportsCheckbox.Layout.Row    = 8;
            app.SummaryReportsCheckbox.Layout.Column = [1 3];
            app.SummaryReportsCheckbox.ValueChangedFcn = @(source, event) generalConfigCheckboxChanged(app, source, event);
            app.SummaryReportsCheckbox.UserData = 'summary';
            
            app.FiguresCheckbox = uicheckbox(gConfig, 'Text', 'Figures');
            app.FiguresCheckbox.Layout.Row    = 9;
            app.FiguresCheckbox.Layout.Column = [1 3];
            app.FiguresCheckbox.ValueChangedFcn = @(source, event) generalConfigCheckboxChanged(app, source, event);
            app.FiguresCheckbox.UserData = 'figure';
            
            app.FigureExtDropdown = uidropdown(gConfig, 'Items', {'.emf', '.eps', '.jpg', '.pdf', '.png', '.tiff'});
            app.FigureExtDropdown.Value         = '.jpg';
            app.FigureExtDropdown.Layout.Row    = 10;
            app.FigureExtDropdown.Layout.Column = [2 3];
            app.FigureExtDropdown.ValueChangedFcn = @(source, event) figureExtDropdownChg(app, source, event);
            app.FigureExtDropdown.Enable = 'off';
            
            app.FigureExtLabel = uilabel(gConfig, 'Text', 'Format', 'HorizontalAlignment', 'left');
            app.FigureExtLabel.Layout.Row    = 10;
            app.FigureExtLabel.Layout.Column = 1;
            app.FigureExtLabel.Enable = 'off';
            
            % +++++++++++++++++++++++ 1. time parser ++++++++++++++++++++++
            app.TimeParserText = uilabel(gConfig, ...
                'Text', 'Date and Time', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.TimeParserText.Layout.Row    = 1;
            app.TimeParserText.Layout.Column = [4 7];
            
            app.TimeParserDropdown = uidropdown(gConfig, 'Items', {'None', 'All Same', 'From File', 'From Filename ezDecoder'});
            app.TimeParserDropdown.Layout.Row    = 2;
            app.TimeParserDropdown.Layout.Column = [4 7];
            app.TimeParserDropdown.ValueChangedFcn = @(source, event) datetimeOrEpochParserChg(app, source, event);
            app.TimeParserDropdown.UserData = 'time';
            
            app.TimeParserAllSameEditor = uieditfield(gConfig, 'text', 'Tooltip', 'using HH:mm:ss format, e.g.: 19:00:00');
            app.TimeParserAllSameEditor.Layout.Row    = 3;
            app.TimeParserAllSameEditor.Layout.Column = [6 7];
            app.TimeParserAllSameEditor.Visible = 'off';
            app.TimeParserAllSameEditor.ValueChangedFcn = @(source, event) datetimeOrEpochAllSameChg(app, source, event);
            app.TimeParserAllSameEditor.UserData = 'time';
            
            app.TimeParserAllSameEditorLabel = uilabel(gConfig, 'Text', 'Start time:', 'HorizontalAlignment', 'left');
            app.TimeParserAllSameEditorLabel.Layout.Row    = 3;
            app.TimeParserAllSameEditorLabel.Layout.Column = [4 5];
            app.TimeParserAllSameEditorLabel.Visible = 'off';
            
            app.TimeParserIndicatorLabel = uilabel(gConfig, 'Text', 'Which field is for date/time:');
            app.TimeParserIndicatorLabel.Layout.Row    = 3;
            app.TimeParserIndicatorLabel.Layout.Column = [4 6];
            app.TimeParserIndicatorLabel.Visible = 'off';
            
            app.TimeParserIndicatorEdit = uieditfield(gConfig, 'numeric', 'Value', 1);
            app.TimeParserIndicatorEdit.Layout.Row    = 3;
            app.TimeParserIndicatorEdit.Layout.Column = 7;
            app.TimeParserIndicatorEdit.Visible = 'off';
            app.TimeParserIndicatorEdit.ValueChangedFcn = @(source, event) datetimeOrEpochFieldChg(app, source, event);
            app.TimeParserIndicatorEdit.UserData = 'time';
            
            app.TimeParserFormatLabel = uilabel(gConfig, 'Text', 'Date/time format:');
            app.TimeParserFormatLabel.Layout.Row    = 4;
            app.TimeParserFormatLabel.Layout.Column = [4 5];
            app.TimeParserFormatLabel.Visible = 'off';
            
            app.TimeParserFormatEditor = uieditfield(gConfig, 'Tooltip', 'using standard date/time format, e.g.: yyyyMMddHHmmss');
            app.TimeParserFormatEditor.Value         = 'yyyyMMddHHmmss';
            app.TimeParserFormatEditor.Layout.Row    = 4;
            app.TimeParserFormatEditor.Layout.Column = [6 7];
            app.TimeParserFormatEditor.Visible = 'off';
            app.TimeParserFormatEditor.ValueChangedFcn = @(source, event) datetimeFormatChanged(app, source, event);
        
            app.TimeParserCheckButton = uibutton(gConfig, 'Text', 'T', ...
                'Icon', 'test_app_16.png');
            app.TimeParserCheckButton.IconAlignment = 'left';
            app.TimeParserCheckButton.Layout.Row    = 5;
            app.TimeParserCheckButton.Layout.Column = 7;
            app.TimeParserCheckButton.Visible = 'off';
            app.TimeParserCheckButton.ButtonPushedFcn = @(source, event) testDatetimeOrEpochParser(app, source, event);
            app.TimeParserCheckButton.UserData = 'time';
            
            app.TimeParserMessageResults = uilabel(gConfig, 'Text', '');
            app.TimeParserMessageResults.Layout.Row    = 5;
            app.TimeParserMessageResults.Layout.Column = [4 6];
            app.TimeParserMessageResults.Visible = 'off';
            
            % +++++++++++++++++++++++ 2. epoch parser +++++++++++++++++++++
            rowOffset = 5;
            
            app.EpochParserText = uilabel(gConfig, ...
                'Text', 'Epoch', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.EpochParserText.Layout.Row    = 1 + rowOffset;
            app.EpochParserText.Layout.Column = [4 7];
            
            app.EpochParserDropdown = uidropdown(gConfig, 'Items', {'None', 'All Same', 'From File', 'From Filename ezDecoder'});
            app.EpochParserDropdown.Layout.Row    = 2 + rowOffset;
            app.EpochParserDropdown.Layout.Column = [4 7];
            app.EpochParserDropdown.ValueChangedFcn = @(source, event) datetimeOrEpochParserChg(app, source, event);
            app.EpochParserDropdown.UserData = 'epoch';
            
            app.EpochParserAllSameEditor = uieditfield(gConfig, 'numeric', 'Tooltip', 'only a single number allowed');
            app.EpochParserAllSameEditor.Value         = 15;
            app.EpochParserAllSameEditor.Layout.Row    = 3 + rowOffset;
            app.EpochParserAllSameEditor.Layout.Column = [6 7];
            app.EpochParserAllSameEditor.Visible = 'off';
            app.EpochParserAllSameEditor.ValueChangedFcn = @(source, event) datetimeOrEpochAllSameChg(app, source, event);
            app.EpochParserAllSameEditor.UserData = 'epoch';
            
            app.EpochParserAllSameEditorLabel = uilabel(gConfig, 'Text', 'Epoch length:', 'HorizontalAlignment', 'left');
            app.EpochParserAllSameEditorLabel.Layout.Row    = 3 + rowOffset;
            app.EpochParserAllSameEditorLabel.Layout.Column = [4 5];
            app.EpochParserAllSameEditorLabel.Visible = 'off';
            
            app.EpochParserIndicatorLabel = uilabel(gConfig, 'Text', 'Which field is for epoch:');
            app.EpochParserIndicatorLabel.Layout.Row    = 3 + rowOffset;
            app.EpochParserIndicatorLabel.Layout.Column = [4 6];
            app.EpochParserIndicatorLabel.Visible = 'off';
            
            app.EpochParserIndicatorEdit = uieditfield(gConfig, 'numeric', 'Value', 1);
            app.EpochParserIndicatorEdit.Layout.Row    = 3 + rowOffset;
            app.EpochParserIndicatorEdit.Layout.Column = 7;
            app.EpochParserIndicatorEdit.Visible = 'off';
            app.EpochParserIndicatorEdit.ValueChangedFcn = @(source, event) datetimeOrEpochFieldChg(app, source, event);
            app.EpochParserIndicatorEdit.UserData = 'epoch';
        
            app.EpochParserCheckButton = uibutton(gConfig, 'Text', 'T', ...
                'Icon', 'test_app_16.png');
            app.EpochParserCheckButton.IconAlignment = 'left';
            app.EpochParserCheckButton.Layout.Row    = 4 + rowOffset;
            app.EpochParserCheckButton.Layout.Column = 7;
            app.EpochParserCheckButton.Visible = 'off';
            app.EpochParserCheckButton.ButtonPushedFcn = @(source, event) testDatetimeOrEpochParser(app, source, event);
            app.EpochParserCheckButton.UserData = 'epoch';
            
            app.EpochParserMessageResults = uilabel(gConfig, 'Text', '');
            app.EpochParserMessageResults.Layout.Row    = 4 + rowOffset;
            app.EpochParserMessageResults.Layout.Column = [4 6];
            app.EpochParserMessageResults.Visible = 'off';
            
            % +++++++++++++++++++++++ 3. ezDecoder ++++++++++++++++++++++
            app.DecoderText = uilabel(gConfig, ...
                'Text', 'Filename ezDecoder', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.DecoderText.Layout.Row    = 1;
            app.DecoderText.Layout.Column = [8 numel(gConfig.ColumnWidth)];
            app.DecoderText.Visible       = 'off';
            
            app.DecoderSeperatorLabel = uilabel(gConfig, 'Text', 'Filename separation symbols:', 'HorizontalAlignment', 'left');
            app.DecoderSeperatorLabel.Layout.Row    = 2;
            app.DecoderSeperatorLabel.Layout.Column = [8 numel(gConfig.ColumnWidth)];
            app.DecoderSeperatorLabel.Visible = 'off';
            
            app.DecoderSeperatorUnderscoreCheckbox = uicheckbox(gConfig, 'Text', 'Underscore (''_'')', 'Value', 1);
            app.DecoderSeperatorUnderscoreCheckbox.Layout.Row    = 3;
            app.DecoderSeperatorUnderscoreCheckbox.Layout.Column = [8 9];
            app.DecoderSeperatorUnderscoreCheckbox.Visible = 'off';
            app.DecoderSeperatorUnderscoreCheckbox.ValueChangedFcn = @(source, event) separatorChanged(app, source, event);
            
            app.DecoderSeperatorPeriodCheckbox = uicheckbox(gConfig, 'Text', 'Period (''.'')', 'Value', 0);
            app.DecoderSeperatorPeriodCheckbox.Layout.Row    = 4;
            app.DecoderSeperatorPeriodCheckbox.Layout.Column = [8 9];
            app.DecoderSeperatorPeriodCheckbox.Visible = 'off';
            app.DecoderSeperatorPeriodCheckbox.ValueChangedFcn = @(source, event) separatorChanged(app, source, event);
            
            app.DecoderSeperatorHyphenCheckbox = uicheckbox(gConfig, 'Text', 'Hyphen (''-'')');
            app.DecoderSeperatorHyphenCheckbox.Layout.Row    = 5;
            app.DecoderSeperatorHyphenCheckbox.Layout.Column = [8 9];
            app.DecoderSeperatorHyphenCheckbox.Visible = 'off';
            app.DecoderSeperatorHyphenCheckbox.ValueChangedFcn = @(source, event) separatorChanged(app, source, event);
            
            app.DecoderSeperatorUserCheckbox = uicheckbox(gConfig, 'Text', 'User defined:');
            app.DecoderSeperatorUserCheckbox.Layout.Row    = 6;
            app.DecoderSeperatorUserCheckbox.Layout.Column = [8 9];
            app.DecoderSeperatorUserCheckbox.Visible = 'off';
            app.DecoderSeperatorUserCheckbox.ValueChangedFcn = @(source, event) userDefinedSeparator(app, source, event);
            
            app.DecoderSeperatorUserEditor = uieditfield(gConfig, 'text');
            app.DecoderSeperatorUserEditor.Layout.Row    = 7;
            app.DecoderSeperatorUserEditor.Layout.Column = [8 9];
            app.DecoderSeperatorUserEditor.Tooltip = 'type in additional separators, e.g.: ,+%';
            app.DecoderSeperatorUserEditor.Visible = 'off';
            app.DecoderSeperatorUserEditor.Enable  = 'off';
            app.DecoderSeperatorUserEditor.ValueChangedFcn = @(source, event) userDefinedSeparatorEdited(app, source, event);
            
            app.SeparatorDetailLabel = uilabel(gConfig, 'Text', 'Defined separator(s):');
            app.SeparatorDetailLabel.Layout.Row    = 8;
            app.SeparatorDetailLabel.Layout.Column = [8 9];
            app.SeparatorDetailLabel.Visible = 'off';
            
            app.SeparatorDetail = uilabel(gConfig, 'Text', '_');
            app.SeparatorDetail.Layout.Row    = 8;
            app.SeparatorDetail.Layout.Column = 10;
            app.SeparatorDetail.Visible = 'off';

            %% layout Tab 4: Raw Settings
            gRawOptions = uigridlayout(app.RawTab);
            gRawOptions.RowHeight   = repmat({'1x'}, 1, 10);
            gRawOptions.ColumnWidth = repmat({'1x'}, 1, 10);
            
            % +++++++++++++++++++++++ 1. advanced +++++++++++++++++++++++++
            app.AdvancedText = uilabel(gRawOptions, ...
                'Text', 'Advanced Settings', 'HorizontalAlignment', 'left', ...
                'BackgroundColor', [.75 .75 .75]);
            app.AdvancedText.Layout.Row    = 1;
            app.AdvancedText.Layout.Column = [1 4];

            app.NonMovingThresholdEditor = uieditfield(gRawOptions, 'text', 'HorizontalAlignment', 'right');
            app.NonMovingThresholdEditor.Value = '0.01';
            app.NonMovingThresholdEditor.Layout.Row    = 2;
            app.NonMovingThresholdEditor.Layout.Column = 4;
            app.NonMovingThresholdEditor.ValueChangedFcn = @(source, event) nonMovingThreChanged(app, source, event);
            
            app.NonMovingThresholdEditorLabel = uilabel(gRawOptions, 'Text', 'Non Moving Threshold (g):', 'HorizontalAlignment', 'left');
            app.NonMovingThresholdEditorLabel.Layout.Row    = 2;
            app.NonMovingThresholdEditorLabel.Layout.Column = [1 3];

            app.NonMovingDurationEditor = uieditfield(gRawOptions, 'text', 'HorizontalAlignment', 'right');
            app.NonMovingDurationEditor.Value = '10';
            app.NonMovingDurationEditor.Layout.Row    = 3;
            app.NonMovingDurationEditor.Layout.Column = 4;
            app.NonMovingDurationEditor.ValueChangedFcn = @(source, event) nonMovingDurationChanged(app, source, event);
            
            app.NonMovingDurationEditorLabel = uilabel(gRawOptions, 'Text', 'Non Moving Duration (sec):', 'HorizontalAlignment', 'left');
            app.NonMovingDurationEditorLabel.Layout.Row    = 3;
            app.NonMovingDurationEditorLabel.Layout.Column = [1 3];

            app.BackgroundNoiseThresholdEditor = uieditfield(gRawOptions, 'text', 'HorizontalAlignment', 'right');
            app.BackgroundNoiseThresholdEditor.Value = '0.02';
            app.BackgroundNoiseThresholdEditor.Layout.Row    = 4;
            app.BackgroundNoiseThresholdEditor.Layout.Column = 4;
            app.BackgroundNoiseThresholdEditor.ValueChangedFcn = @(source, event) bkgNoiseChanged(app, source, event);
            
            app.BackgroundNoiseThresholdEditorLabel = uilabel(gRawOptions, 'Text', 'Background Noise Thre. (g):', 'HorizontalAlignment', 'left');
            app.BackgroundNoiseThresholdEditorLabel.Layout.Row    = 4;
            app.BackgroundNoiseThresholdEditorLabel.Layout.Column = [1 3];
            
            app.PlotCalibrationCheckbox = uicheckbox(gRawOptions, 'Text', 'Show Calibration Plot');
            app.PlotCalibrationCheckbox.Value = 1;
            app.PlotCalibrationCheckbox.Layout.Row    = 5;
            app.PlotCalibrationCheckbox.Layout.Column = [1 4];
            app.PlotCalibrationCheckbox.ValueChangedFcn = @(source, event) calibrationCheckChg(app, source, event);
            
            app.PlotAccPlusCountsCheckbox = uicheckbox(gRawOptions, 'Text', 'Plot Accelerometer and Counts');
            app.PlotAccPlusCountsCheckbox.Value = 1;
            app.PlotAccPlusCountsCheckbox.Layout.Row    = 6;
            app.PlotAccPlusCountsCheckbox.Layout.Column = [1 4];
            app.PlotAccPlusCountsCheckbox.ValueChangedFcn = @(source, event) accCountsCheckChg(app, source, event);
            
            %% bottom message and buttons
            app.SampleFilenameLabel = uilabel(gFigure, 'Text', 'Sample filename: ', 'HorizontalAlignment', 'left');
            app.SampleFilenameLabel.Layout.Row    = numel(gFigure.RowHeight);
            app.SampleFilenameLabel.Layout.Column = [1 5];
            app.SampleFilenameLabel.Visible = 'off';
            
            % confirm button
            app.ConfirmButton = uibutton(gFigure, 'Text', 'Confirm', ...
                'ButtonPushedFcn', @(source, event) importButtonCallback(app, source, event));
            app.ConfirmButton.Layout.Row    = numel(gFigure.RowHeight);
            app.ConfirmButton.Layout.Column = numel(gFigure.ColumnWidth)-1;
            app.ConfirmButton.Icon          = 'confirm_16.png';
            
            % cancel button
            app.CancelButton = uibutton(gFigure, 'Text', 'Cancel', ...
                'ButtonPushedFcn', @(source, event) cancelButtonCallback(app, source, event));
            app.CancelButton.Layout.Row    = numel(gFigure.RowHeight);
            app.CancelButton.Layout.Column = numel(gFigure.ColumnWidth);
            app.CancelButton.Icon          = 'cancel.png';
        end
    end
    
    methods (Access = private)
        function app = tabGroupValueChg(app, source, event)
            switch app.fire
                case {'Option', 'Raw'}
                    if strcmp(event.NewValue.Title, 'Import') || strcmp(event.NewValue.Title, 'Import Options')
                        source.SelectedTab = event.OldValue;
                    end
            end

            % when run mode is Raw, disable Configuration Tab for now
            switch app.configStruct.RunMode
                case 'Raw'
                    if strcmp(event.NewValue.Title, 'Configuration')
                        source.SelectedTab = event.OldValue;
                    end
                otherwise
                    if strcmp(event.NewValue.Title, 'Raw Data')
                        source.SelectedTab = event.OldValue;
                    end
            end
        end
        
        function app = nodeChange(app, source, event)
            selectedNodes = app.Tree.SelectedNodes;
            selectedNodes.Icon = 'folderOpened.gif';
            event.PreviousSelectedNodes.Icon = 'folderClosed.gif';
            app.dataFolder = selectedNodes.NodeData.Path;
            app.openFolder;
        end
        
        function app = nodeExpand(app, source, event)
            node = event.Node;
            intoFolder(node.NodeData.ChildNodes, node.NodeData.SubFolders, 0);
        end
        
        function app = upDirButtonClicked(app, source, event)
            app.Tree.collapse;
            allNodes = app.Tree.Children;
            allNodes.delete;
            
            app.topFolder = fileparts(app.topFolder);
            
            % create tree
            dirNode(app.Tree, app.topFolder);
            
            % select the top layer by default
            app.Tree.SelectedNodes = app.Tree.Children(1);
            app.Tree.Children(1).Icon = 'folderOpened.gif';
            
            app.dataFolder = app.Tree.SelectedNodes.NodeData.Path;
            
            % call open
            app.openFolder;
        end
        
        function app = openButtonClicked(app, source, event)
            app.topFolder = uigetdir('.', 'Choose a folder that contains all data recordings ...');
            if app.topFolder == 0
                return;
            end
            
            % create tree (delete existing tree nodes if needed)
            app.Tree.collapse;
            allNodes = app.Tree.Children;
            allNodes.delete;
            
            dirNode(app.Tree, app.topFolder);
            
            % select the top layer by default
            app.Tree.SelectedNodes = app.Tree.Children(1);
            app.Tree.Children(1).Icon = 'folderOpened.gif';
            
            app.dataFolder = app.Tree.SelectedNodes.NodeData.Path;
            
            % call open
            app.openFolder;
        end
        
        function app = fileSelected(app, source, event)
            app.selectedFilesIndex = event.Value;
        end
        
        function app = fileToRemove(app, source, event)
            app.removeFilesIndex = event.Value;
        end
        
        function app = inClicked(app, source, event)
            [~, ~, indr] = intersect(app.selectedFilesIndex_, app.selectedFilesIndex);
            newAdded = app.selectedFilesIndex;
            newAdded(indr) = [];
            
            if ~isempty(newAdded)
                app.selectedFiles = [app.selectedFiles; app.files(newAdded)];
                app.SelectedFileList.Items = [app.SelectedFileList.Items, app.files(newAdded)'];
                app.SelectedFileList.ItemsData = 1:numel(app.SelectedFileList.Items);
                app.selectedFilesIndex_ = [app.selectedFilesIndex_, newAdded];
            end
            
            if isempty(app.FileOverViewList.Items)
                app.FileOverViewList.Value = {};
            else
                app.FileOverViewList.Value = [];
            end
            
            % feed sample file
            if ~isempty(app.selectedFiles)
                app.SampleFilenameLabel.Visible = 'on';
                app.SampleFilenameLabel.Text = 'Sample filename: ' + string(app.selectedFiles{1});
            else
                app.SampleFilenameLabel.Visible = 'off';
                app.SampleFilenameLabel.Text    = 'Sample filename: ';
            end
        end
        
        function app = allInClicked(app, source, event)
            app.selectedFiles              = app.files;
            app.selectedFilesIndex_        = 1:numel(app.files);
            app.SelectedFileList.Items     = app.files;
            app.SelectedFileList.ItemsData = 1:numel(app.files);
            app.FileOverViewList.Value     = {};
            
            % feed sample file
            if ~isempty(app.selectedFiles)
                app.SampleFilenameLabel.Visible = 'on';
                app.SampleFilenameLabel.Text = 'Sample filename: ' + string(app.selectedFiles{1});
            else
                app.SampleFilenameLabel.Visible = 'off';
                app.SampleFilenameLabel.Text    = 'Sample filename: ';
            end
        end
        
        function app = outClicked(app, source, event)
            app.selectedFilesIndex_(app.removeFilesIndex) = [];
            app.selectedFiles(app.removeFilesIndex) = [];
            app.SelectedFileList.Items(app.removeFilesIndex) = [];
            app.SelectedFileList.Value = {};
            
            app.removeFilesIndex = [];
            
            % feed sample file
            if ~isempty(app.selectedFiles)
                app.SampleFilenameLabel.Visible = 'on';
                app.SampleFilenameLabel.Text = 'Sample filename: ' + string(app.selectedFiles{1});
            else
                app.SampleFilenameLabel.Visible = 'off';
                app.SampleFilenameLabel.Text    = 'Sample filename: ';
            end
        end
        
        function app = allOutClicked(app, source, event)
            app.selectedFilesIndex_    = [];
            app.selectedFiles          = [];
            app.SelectedFileList.Items = {};
            app.SelectedFileList.Value = {};
            
            % feed sample file
            if ~isempty(app.selectedFiles)
                app.SampleFilenameLabel.Visible = 'on';
                app.SampleFilenameLabel.Text = 'Sample filename: ' + string(app.selectedFiles{1});
            else
                app.SampleFilenameLabel.Visible = 'off';
                app.SampleFilenameLabel.Text    = 'Sample filename: ';
            end
        end
        
        function app = runModeChanged(app, source, event)
            switch event.Value
                case 1 % gap
                    app.ImportGapCheckbox.Enable     = 'off';
                    app.ImportExistedCheckbox.Enable = 'on';
                case {2, 3} % circadian, sleep
                    app.ImportGapCheckbox.Enable     = 'on';
                    app.ImportExistedCheckbox.Enable = 'on';
                case 4 % raw
                    app.ImportGapCheckbox.Enable     = 'off';
                    app.ImportExistedCheckbox.Enable = 'off';
            end
            app.configStruct.RunMode = source.Items{event.Value};
            
            % reset existing results to unchecked
            app.ImportExistedCheckbox.Value = 0;
            app.ImportExistedFileExtensionEditor.Enable = 'off';
            app.ImportExistedFileExtensionEditorLabel.Enable = 'off';
            app.ImportExistedFileExtensionEditor.Value = '';
            
            app.configStruct.ExistedFlag = 0;
            app.configStruct.ExistedExtension  = '';
        end
        
        function app = importResults(app, source, event)
            switch event.Value
                case 1
                    app.ImportExistedFileExtensionEditor.Enable = 'on';
                    app.ImportExistedFileExtensionEditorLabel.Enable = 'on';
                    app.ImportExistedFileExtensionEditor.Value = "."+lower(app.configStruct.RunMode);
                    app.configStruct.ExistedExtension = "."+lower(app.configStruct.RunMode);
                case 0
                    app.ImportExistedFileExtensionEditor.Enable = 'off';
                    app.ImportExistedFileExtensionEditorLabel.Enable = 'off';
                    app.ImportExistedFileExtensionEditor.Value = '';
                    app.configStruct.ExistedExtension = '';
            end
            
            app.configStruct.ExistedFlag = event.Value;
        end
        
        function app = resultsExtChanged(app, source, event)
            app.configStruct.ExistedExtension = event.Value;
        end
        
        function app = importGap(app, source, event)
            switch event.Value
                case 1
                    app.ImportGapFileExtensionEditor.Enable = 'on';
                    app.ImportGapFileExtensionEditorLabel.Enable = 'on';
                    app.ImportGapFileExtensionEditor.Value = ".gap";
                    app.configStruct.GapExtension = ".gap";
                case 0
                    app.ImportGapFileExtensionEditor.Enable = 'off';
                    app.ImportGapFileExtensionEditorLabel.Enable = 'off';
                    app.ImportGapFileExtensionEditor.Value = '';
                    app.configStruct.GapExtension = '';
            end
            
            app.configStruct.Gap = event.Value;
        end
        
        function app = gapExtChanged(app, source, event)
            app.configStruct.GapExtension = event.Value;
        end
        
        function app = generalConfigCheckboxChanged(app, source, event)
            switch source.UserData
                case 'actogram'
                    app.configStruct.Actogram = event.Value;
                case 'clock'
                    app.configStruct.PolarClock = event.Value;
                case 'summary'
                    app.configStruct.SummaryReport = event.Value;
                case 'figure'
                    app.configStruct.Figures = event.Value;
                    if event.Value
                        app.FigureExtDropdown.Enable = 'on';
                        app.FigureExtLabel.Enable = 'on';
                    else
                        app.FigureExtDropdown.Enable = 'off';
                        app.FigureExtLabel.Enable = 'off';
                    end
            end
        end
        
        function app = figureExtDropdownChg(app, source, event)
            app.configStruct.FigureExt = event.Value;
        end
        
        function app = datetimeOrEpochParserChg(app, source, event)
            timeOrEpoch = source.UserData;
            eventValue  = event.Value;
            app = controlConfigVisibility(app, timeOrEpoch, eventValue);
        end
        
        function app = datetimeOrEpochAllSameChg(app, source, event)
            switch source.UserData
                case 'time'
                    app.configStruct.TimeParserProperties.SameDateTime = event.Value;
                case 'epoch'
                    app.configStruct.EpochParserProperties.SameEpoch   = event.Value;
            end
        end
        
        function app = separatorChanged(app, source, event)
            switch source.Text
                case 'Underscore (''_'')'
                    temp = '_';
                case 'Period (''.'')'
                    temp = '.';
                case 'Hyphen (''-'')'
                    temp = '-';
            end
            
            if event.Value
                app.filenameSeparator = [app.filenameSeparator {temp}];
            else
                ind = contains(app.filenameSeparator, temp);
                app.filenameSeparator(ind) = [];
            end
            
            if isempty(app.filenameSeparator)
                app.SeparatorDetail.Text  = 'NO separators!';
                app.SeparatorDetail.FontColor = [1 140/255 0];
            else
                app.SeparatorDetail.Text = cell2mat(app.filenameSeparator);
                app.SeparatorDetail.FontColor = 'k';
            end
            
            app.configStruct.FileNameSeparator = app.filenameSeparator;
        end
        
        function app = userDefinedSeparator(app, source, event)
            switch event.Value
                case 1
                    app.DecoderSeperatorUserEditor.Enable = 'on';
                case 0
                    app.DecoderSeperatorUserEditor.Enable = 'off';
            end
        end
        
        function app = userDefinedSeparatorEdited(app, source, event)
            strin  = event.Value;
            strSep = num2cell(strin);
            if isempty(strSep)
                % separator should match the checkboxes
                app.filenameSeparator = app.filenameSeparatorPool( ...
                    [app.DecoderSeperatorUnderscoreCheckbox.Value, app.DecoderSeperatorPeriodCheckbox.Value, app.DecoderSeperatorHyphenCheckbox.Value]);
            else
                app.filenameSeparator = [app.filenameSeparator strSep];
            end
            
            if isempty(app.filenameSeparator)
                app.SeparatorDetail.Text  = 'NO separators!';
                app.SeparatorDetail.FontColor = [1 140/255 0];
            else
                app.SeparatorDetail.Text = cell2mat(app.filenameSeparator);
                app.SeparatorDetail.FontColor = 'k';
            end
            
            app.configStruct.FileNameSeparator = app.filenameSeparator;
        end
        
        function app = datetimeOrEpochFieldChg(app, source, event)
            switch source.UserData
                case 'time'
                    app.configStruct.TimeParserProperties.DatetimeInd = event.Value;
                case 'epoch'
                    app.configStruct.EpochParserProperties.EpochInd = event.Value;
            end
        end
        
        function app = datetimeFormatChanged(app, source, event)
            app.configStruct.TimeParserProperties.DatetimeFormat = event.Value;
        end
        
        function app = testDatetimeOrEpochParser(app, source, event)
            switch source.UserData
                case 'time'
                    h = app.TimeParserMessageResults;
                case 'epoch'
                    h = app.EpochParserMessageResults;
            end
            
            if isempty(app.selectedFiles)
                h.Text = 'NO files selected yet';
                h.FontColor = [1 140/255 0];
                return;
            end
            
            nameparts = strsplit(app.selectedFiles{1}, app.filenameSeparator);
            switch source.UserData
                case 'time'
                    try
                        dtparts = nameparts{app.configStruct.TimeParserProperties.DatetimeInd};
                        dt      = datetime(dtparts, 'InputFormat', app.configStruct.TimeParserProperties.DatetimeFormat);
                        h.Text = datestr(dt);
                        h.FontColor = 'k';
                    catch
                        h.Text = 'CANNOT decode filename';
                        h.FontColor = [1 140/255 0];
                    end
                case 'epoch'
                    try
                        dtparts = nameparts{app.configStruct.EpochParserProperties.EpochInd};
                        dt      = regexp(dtparts, '\d*', 'match');
                        h.Text  = num2str(eval(dt{1}));
                        h.FontColor = 'k';
                    catch
                        h.Text = 'CANNOT decode filename';
                        h.FontColor = [1 140/255 0];
                    end
            end
        end

        function app = nonMovingThreChanged(app, source, event)
            app.configStruct.RawSetting.NonMovingThreshold = str2double(event.Value);
        end

        function app = nonMovingDurationChanged(app, source, event)
            app.configStruct.RawSetting.NonMovingDuration = str2double(event.Value);
        end

        function app = bkgNoiseChanged(app, source, event)
            app.configStruct.RawSetting.BackgroundNoise = str2double(event.Value);
        end

        function app = calibrationCheckChg(app, source, event)
            app.configStruct.RawSetting.PlotCalibration = event.Value;
        end

        function app = accCountsCheckChg(app, source, event)
            app.configStruct.RawSetting.PlotAccCounts = event.Value;
        end
        
        function app = importButtonCallback(app, source, event)
            if ~isempty(app.selectedFiles)
                app.imported = 1;
            end
            closereq;
        end
        
        function app = cancelButtonCallback(app, source, event)
            app.imported = 0;
            closereq;
        end
    end
    
    %% dependencies
    methods
        function app = openFolder(app)
            allfiles  = dir(fullfile(app.dataFolder, "*.*"));
            allfiles([allfiles.isdir] == 1) = [];
            blindfile = dir(fullfile(app.dataFolder, ".*")); % to blind out back up files that usually start with .
            blindfile([blindfile.isdir] == 1) = [];
            [~, indl] = intersect({allfiles.name}, {blindfile.name});
            allfiles(indl) = [];
            
            if numel(allfiles) == 0
                app.FileOverViewList.Items = {};
                app.files = [];
                
                return;
            elseif numel(allfiles) == 1
                app.files = {struct2table(allfiles).name};
            else
                app.files = struct2table(allfiles).name;
            end
            
            app.FileOverViewList.Items = app.files;
            app.FileOverViewList.ItemsData = 1:length(app.files);
            app.FileOverViewList.Value = 1;
            
            % clear selection
            app.selectedFiles          = [];
            app.SelectedFileList.Items = {};
            app.SelectedFileList.Value = {};
            app.selectedFilesIndex     = 1; % match the default selected item
            app.selectedFilesIndex_    = [];
        end
        
        function app = loadConfig(app, configStruct, selectedFiles)
            app.configStruct  = configStruct;
            app.selectedFiles = selectedFiles;
            
            if ~isempty(selectedFiles)
                app.SampleFilenameLabel.Text = "Sample filename: " + selectedFiles{1};
                app.SampleFilenameLabel.Visible = 'on';
            end
            
            % set uicontrols based on configStruct
            if contains(configStruct.TimeParserMode, 'ezDecoder')
                app = step2(app, configStruct);
                app = step1(app, configStruct);
            else
                app = step1(app, configStruct);
                app = step2(app, configStruct);
            end

            % 11/11/2022
            % visualization and save checks
            app.ActogramCheckbox.Value       = configStruct.Actogram;
            app.ClockCheckbox.Value          = configStruct.PolarClock;
            app.SummaryReportsCheckbox.Value = configStruct.SummaryReport;
            app.FiguresCheckbox.Value        = configStruct.Figures;
            
            function app = step1(app, configStruct)
                app.TimeParserDropdown.Value = configStruct.TimeParserMode;
                switch configStruct.TimeParserMode
                    case 'All Same'
                        app.TimeParserAllSameEditor.Value = configStruct.TimeParserProperties.SameDateTime;
                    case 'From Filename ezDecoder'
                        sep  = configStruct.FileNameSeparator;
                        app  = popCheckers(app, sep);
                        
                        app.TimeParserIndicatorEdit.Value = configStruct.TimeParserProperties.DatetimeInd;
                        app.TimeParserFormatEditor.Value  = configStruct.TimeParserProperties.DatetimeFormat;
                end
                app = controlConfigVisibility(app, 'time', configStruct.TimeParserMode);
            end
            
            function app = step2(app, configStruct)
                app.EpochParserDropdown.Value = configStruct.EpochParserMode;
                switch configStruct.EpochParserMode
                    case 'All Same'
                        app.EpochParserAllSameEditor.Value = configStruct.EpochParserProperties.SameEpoch;
                    case 'From Filename ezDecoder'
                        sep  = configStruct.FileNameSeparator;
                        app  = popCheckers(app, sep);
                        
                        app.EpochParserIndicatorEdit.Value = config.EpochParserProperties.EpochInd;
                end
                app = controlConfigVisibility(app, 'epoch', configStruct.EpochParserMode);
            end
            
            function app = popCheckers(app, sep)
                sep_ = sep;
                ind  = strcmp(sep, '_');
                if any(ind)
                    app.DecoderSeperatorUnderscoreCheckbox.Value = 1;
                    sep(ind) = [];
                end
                
                ind  = strcmp(sep, '.');
                if any(ind)
                    app.DecoderSeperatorPeriodCheckbox.Value = 1;
                    sep(ind) = [];
                end
                
                ind  = strcmp(sep, '-');
                if any(ind)
                    app.DecoderSeperatorHyphenCheckbox.Value = 1;
                    sep(ind) = [];
                end
                
                if ~isempty(sep)
                    app.DecoderSeperatorUserCheckbox.Value = 1;
                    app.DecoderSeperatorUserEditor.Enable = 'on';
                    app.DecoderSeperatorUserEditor.Value = sep;
                end
                
                % in case sep_ stored before is not a cell
                if ~iscell(sep_)
                    sep_ = {sep_};
                end
                app.SeparatorDetailLabel.Text = "Defined separator(s): " + strcat(sep_{:});
            end
        end

        function app = loadRawConfig(app, configStruct, selectedFiles)
            app.configStruct  = configStruct;
            app.selectedFiles = selectedFiles;

            app.NonMovingThresholdEditor.Value       = num2str(configStruct.RawSetting.NonMovingThreshold);
            app.NonMovingDurationEditor.Value        = num2str(configStruct.RawSetting.NonMovingDuration);
            app.BackgroundNoiseThresholdEditor.Value = num2str(configStruct.RawSetting.BackgroundNoise);
            app.PlotCalibrationCheckbox.Value        = configStruct.RawSetting.PlotCalibration;
            app.PlotAccPlusCountsCheckbox.Value      = configStruct.RawSetting.PlotAccCounts;
        end
        
        function app = controlConfigVisibility(app, timeOrEpoch, eventValue)
            % container
            timeAllSame = [app.TimeParserAllSameEditor, ...
                app.TimeParserAllSameEditorLabel];
            timeDecoder = [app.TimeParserIndicatorLabel, ...
                app.TimeParserIndicatorEdit, ...
                app.TimeParserFormatLabel, ...
                app.TimeParserFormatEditor, ...
                app.TimeParserMessageResults, ...
                app.TimeParserCheckButton];
            decoder = [app.DecoderText, ...
                app.DecoderSeperatorLabel, ...
                app.DecoderSeperatorUnderscoreCheckbox, ...
                app.DecoderSeperatorPeriodCheckbox, ...
                app.DecoderSeperatorHyphenCheckbox, ...
                app.DecoderSeperatorUserCheckbox, ...
                app.DecoderSeperatorUserEditor, ...
                app.SeparatorDetailLabel, ...
                app.SeparatorDetail];
            epochAllSame = [app.EpochParserAllSameEditor, ...
                app.EpochParserAllSameEditorLabel];
            epochDecoder = [app.EpochParserIndicatorLabel, ...
                app.EpochParserIndicatorEdit, ...
                app.EpochParserMessageResults, ...
                app.EpochParserCheckButton];
            
            switch timeOrEpoch
                case 'time'
                    switch eventValue
                        case 'None'
                            set([timeAllSame, timeDecoder, decoder], 'Visible', 'off');
                        case 'All Same'
                            set(timeAllSame, 'Visible', 'on');
                            set([timeDecoder, decoder], 'Visible', 'off');
                        case 'From File'
                            set([timeAllSame, timeDecoder, decoder], 'Visible', 'off');
                        case 'From Filename ezDecoder'
                            set(timeAllSame, 'Visible', 'off');
                            set([timeDecoder, decoder], 'Visible', 'on');
                    end
                    app.configStruct.TimeParserMode = eventValue;
                case 'epoch'
                    switch eventValue
                        case 'None'
                            set([epochAllSame, epochDecoder, decoder], 'Visible', 'off');
                        case 'All Same'
                            set(epochAllSame, 'Visible', 'on');
                            set([epochDecoder, decoder], 'Visible', 'off');
                        case 'From File'
                            set([epochAllSame, epochDecoder, decoder], 'Visible', 'off');
                        case 'From Filename ezDecoder'
                            set(epochAllSame, 'Visible', 'off');
                            set([epochDecoder, decoder], 'Visible', 'on');
                    end
                    app.configStruct.EpochParserMode = eventValue;
            end
        end
    end
end