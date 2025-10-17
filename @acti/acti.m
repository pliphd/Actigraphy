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
    % 
    
    properties (SetAccess = immutable)
        Epoch
        Point
    end
    
    properties (Dependent = true)
        Gap
        Sleep
        SleepSummary
        ISIVSummary
        M10L5Summary
        CosinorSummary
    end
    properties (SetAccess = protected, Hidden = true)
        Gap_
        Sleep_
        SleepSummary_
        ISIVSummary_
        M10L5Summary_
        CosinorSummary_
    end
    
    properties
        SleepInfo = struct('StartTime', '', ...
            'EndTime', '', ...
            'Method', {'Cole-Kripke'}, ...
            'ModeParameter', struct('P', [], 'V', [], 'C', [], 'T', []), ...
            'Option', {'None'})
        
        ISIVInfo = struct('TimeScaleInMin', [], 'PeriodInHour', [], 'FixedCycles', [])
        
        CosinorInfo = struct('HarmonicsInHour', [], 'MinimumLengthInDays', [], 'CIAlpha', 0.05, 'UserData', []);

        QCimpression = struct('pass', nan, 'message', '');
    end
    
    properties (Dependent = true, Hidden = true)
        GapSeries
        SleepSeries
    end
    properties (SetAccess = protected, Hidden = true)
        GapSeries_
        SleepSeries_
    end
    
    % properties for tolerating other apps
    properties (Hidden = true)
        timeSet
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
        
        function this = set.SleepSummary(this, val)
            this.SleepSummary_ = val;
        end
        function val = get.SleepSummary(this)
            val = this.SleepSummary_;
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
    end
    
    %% methods -- declaration only
    methods
        % pre-processing
        this = qc(this);

        % processing
        this = gapDet(this);
        this = sleepDet(this);
        this = isivAnalysis(this);
        this = m10l5Analysis(this);
        this = cosinorAnalysis(this);
        this = cosinorActi(this);
        
        % visualization
        h = plot(this, varargin);
        h = plotActogram(this, varargin);
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