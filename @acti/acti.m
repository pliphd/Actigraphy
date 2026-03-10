classdef acti < timeseries
    %ACTI create actigraphy objects
    %
    % R = ACTI(DATA, 'Epoch', epochVal) returns an ACTI object
    %     containing the data in DATA. EPOCHVAL determines how many seconds
    %     one point stands for. Note that the EPOCH property is immutable.
    % R = ACTI(..., 'StartTime', startTime) returns
    %     an ACTI object containing the data in DATA and time in TIME. TIME
    %     is relative to the absolute start time defined by STARTTIME which
    %     has been hard-coded to accept only datetime inputs. The unit for
    %     TIME is always seconds
    %
    % $Author:  Peng Li
    % $Modif.:  Jan 04, 2024
    %               Add T in the ModeParameter field to support Actiware
    %                   sleep detection;
    %               Add Method field in SleepInfo property.
    %           Oct 15, 2025
    %               Add Option in SleepInfo struct to facilitate different
    %                   detection options especially when detecting nap.
    %           Dec 08, 2025
    %               Add Diary as an additional Property to enable
    %                   operations on sleep diary
    %               Diary should be a segment matrix like Sleep
    %           Dec 09, 2025
    %               Add PlotOption to customize plot
    %           Feb 15, 2026
    %               Add PrimarySleep and primarySleepSense to estimate
    %                   primary sleep window
    %           Feb 19, 2026
    %               Update plot logic to better integrate to ezActi
    %               Add new properties in ACTIGRAPHY2 to store visualization elements
    %                   and thus quickly retired the PlotOption here
    %           Feb 20, 2026
    %               Add a Circadian property to keep consistency with Gap
    %                   and Sleep. Circadian property only stores circadian
    %                   fitted data
    %           Mar 09, 2026
    %               Add an 'analysis' struct to mark what analysis has been
    %                   done
    %               Add emd method
    % 
    
    properties (SetAccess = immutable)
        Epoch
        Point
    end
    
    properties (Dependent = true)
        Gap
        GapSummary

        Sleep
        SleepSummary

        Diary

        Circadian

        ISIVSummary
        M10L5Summary
        CosinorSummary
        EMDSummary
    end
    properties (SetAccess = protected, Hidden = true)
        Gap_
        GapSummary_

        Sleep_
        SleepSummary_

        Diary_

        Circadian_

        ISIVSummary_
        M10L5Summary_
        CosinorSummary_
        EMDSummary_
    end
    
    properties
        GapInfo      = struct('Parameter', ...
            struct('Threshold', 1, 'ThresholdUnit', {'Min'}, 'MinimumDurationInMin', 60, 'MergeIfShorterThanInMin', 60));

        SleepInfo    = struct('StartTime', '', ...
            'EndTime', '', ...
            'Option', {'Fixed'}, ...        % Available: Estimate, Fixed, Diary
            ...                             % When Option = 'Estimate' or 'Diary', StartTime and EndTime will be overwritten
            'Method', {'Cole-Kripke'}, ...  % Available: Cole-Kripke, Actiware
            'ModeParameter', struct('P', [], 'V', [], 'C', [], ...  % P, V, C correspond to Cole-Kripke
                'T', [], ...                                        % T corresponds to Actiware
                'Prim', struct('zeta', 15, 'zeta_a', 2, 'zeta_r', 30, 'alpha', 8, 'hs', 8, 'Lp', 50)))

        DiaryInfo    = struct('Type', '');
        
        ISIVInfo     = struct('TimeScaleInMin', [], 'PeriodInHour', [], 'FixedCycles', [])
        
        CosinorInfo  = struct('HarmonicsInHour', [], 'MinimumLengthInDays', [], 'CIAlpha', 0.05, 'UserData', []);

        EMDInfo  = struct('TargetComponent', [], 'MinimumLengthInDays', [], 'UserData', []);

        QCimpression = struct('pass', nan, 'message', '');
    end
    
    properties (Dependent = true, Hidden = true)
        GapSeries
        SleepSeries
        SleepWindow
    end
    properties (SetAccess = protected, Hidden = true)
        GapSeries_
        SleepSeries_
        SleepWindow_
    end
    
    % properties for tolerating other apps
    properties (Hidden = true)
        timeSet
        message  = struct('type', {''}, 'content', {''})
        analysis = struct('gap', 0, 'sleep', 0, 'cosinor', 0, 'isiv', 0, 'm10l5', 0, 'emd', 0)
    end
    
    %% construct
    methods
        function this = acti(varargin)
            % parse inputs
            [epoch, startTime, allArg] = parse(varargin{:});
            
            % constructor
            this@timeseries(allArg{:});
            
            % immutable
            this.Epoch = epoch;
            this.Point = (1:length(this.Data))';
            
            % redefine TIME property
            this.Time  = (0:length(this.Data)-1) .* epoch;
            this.TimeInfo.StartDate = startTime;
            if ~isempty(startTime) && ~isnat(startTime)
                this.timeSet = 1;
            end
            
            % quality
            if isempty(this.Quality)
                this.Quality = ones(size(this.Data));
            end
            this.GapSeries = ~this.Quality;
            this.Gap       = detConstantOne(this.GapSeries);
        end
    end
    
    %% methods -- set and get
    methods
        function this = set.Gap(this, val)
            this.Gap_ = val;
            this = this.setGapSeries;
        end
        function val = get.Gap(this)
            val = this.Gap_;
        end
        function this = setGapSeries(this)
            gapSeries = ~gap2Series(this.Gap, numel(this.Data));
            if ~isequal(this.GapSeries, gapSeries)
                this.GapSeries = gapSeries;
            end
        end
        
        function this = set.GapSeries(this, val)
            this.GapSeries_ = val;
            this = this.setGap;
        end
        function val = get.GapSeries(this)
            val = this.GapSeries_;
        end
        function this = setGap(this)
            gap = detConstantOne(this.GapSeries);
            if ~isequal(this.Gap, gap)
                this.Gap = gap;
            end
        end
        
        function this = set.Sleep(this, val)
            this.Sleep_ = val;
        end
        function val = get.Sleep(this)
            val = this.Sleep_;
        end
        
        function this = set.SleepSeries(this, val)
            this.SleepSeries_ = val;
        end
        function val = get.SleepSeries(this)
            val = this.SleepSeries_;
        end

        function this = set.SleepWindow(this, val)
            this.SleepWindow_ = val;
        end
        function val = get.SleepWindow(this)
            val = this.SleepWindow_;
        end
        
        function this = set.SleepSummary(this, val)
            this.SleepSummary_ = val;
        end
        function val = get.SleepSummary(this)
            val = this.SleepSummary_;
        end

        function this = set.GapSummary(this, val)
            this.GapSummary_ = val;
        end
        function val = get.GapSummary(this)
            val = this.GapSummary_;
        end

        function this = set.Diary(this, val)
            this.Diary_ = val;
        end
        function val = get.Diary(this)
            val = this.Diary_;
        end

        function this = set.Circadian(this, val)
            this.Circadian_ = val;
        end
        function val = get.Circadian(this)
            val = this.Circadian_;
        end
        
        function this = set.ISIVSummary(this, val)
            this.ISIVSummary_ = val;
        end
        function val = get.ISIVSummary(this)
            val = this.ISIVSummary_;
        end
        
        function this = set.M10L5Summary(this, val)
            this.M10L5Summary_ = val;
        end
        function val = get.M10L5Summary(this)
            val = this.M10L5Summary_;
        end
        
        function this = set.CosinorSummary(this, val)
            this.CosinorSummary_ = val;
        end
        function val = get.CosinorSummary(this)
            val = this.CosinorSummary_;
        end

        function this = set.EMDSummary(this, val)
            this.EMDSummary_ = val;
        end
        function val = get.EMDSummary(this)
            val = this.EMDSummary_;
        end
    end
    
    %% methods -- declaration only
    methods
        % pre-processing
        this = qc(this);

        % processing
        this = gapDet(this);
        this = sleepDet(this);
        this = primarySleepSense(this);
        this = isivAnalysis(this);
        this = m10l5Analysis(this);
        % this = cosinorAnalysis(this); % retired
        this = cosinorActi(this);
        this = emd(this);
        
        % visualization
        h = plot(this, varargin);
        h = plotActogram(this, varargin);

        % generate report
        this = exportReport(this, outputFile, varargin)
        exportSinglePageReport(this, outputFile, varargin) % layout needs to be improved
    end

    methods (Hidden = true)
        refreshGaps(this, actigraphy);
        this = addSingleGap(this, actigraphy, singleGap);

        refreshSleep(this, actigraphy);
        refreshPrimarySleep(this, actigraphy);
        refreshDiary(this, actigraphy);
        refreshCircadian(this, actigraphy);
    end
end

%% local functions
function [epoch, startTime, allArg] = parse(varargin)
allArg = varargin;

% the first arg should be the signal
if isa(allArg{1}, 'double') && isvector(allArg{1})
    allArg{1} = allArg{1}(:);
else
    error('construction:properties:value not allowed (The first input should be a double vector that represents the actigraphy signal');
end

% epoch is necessary for an ACTI object
argEpoch = find(strcmpi(allArg, 'epoch'));
if ~isempty(argEpoch)
    epoch = allArg{argEpoch + 1};
    allArg([argEpoch, argEpoch+1]) = [];
else
    error('construction:properties:missing properties (Epoch needs to be defined in construction)');
end

if ~isempty(allArg)
    argStart = find(strcmpi(allArg, 'starttime'));
    if ~isempty(argStart)
        startTime = allArg{argStart + 1};
        if ~isa(startTime, 'datetime')
            error('construction:properties:value not allowed (StartTime is hard-coded to be a datetime)');
        end
        
        allArg([argStart, argStart+1]) = [];
    else
        startTime = [];
    end
end
end