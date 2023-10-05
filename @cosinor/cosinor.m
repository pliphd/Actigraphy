classdef cosinor < timeseries
    % COSINOR define class for cosinor analysis
    % 
    %   C = COSINOR(DATA, TIME) creates a COSINOR object to fit the default
    %       cycle length (24 hour). TIME should be in seconds relative to
    %       'StartDateTime'. If 'StartDateTime' is not specificed, the
    %       default reference 0 is start of recording.
    %   C = COSINOR(DATA, TIME, PARAM1, VAL1) specifies one or more of the
    %       following name/value pairs:
    %           'CycleLengthInHour'         Cycle length(s) to be fitted.
    %                                       Allows scalar and vector
    %                                       inputs.
    %           'StartDateTime'             To explicitly give the start
    %                                       time info as a datetime object.
    %
    % Ref. 
    %  [1] Nelson W, Tong YL, Lee JK, Halberg F. Methods for
    %      cosinor-rhythmometry. Chronobiologia. 1979, 6: 305-23.
    %  [2] Naitoh P, Englund CE, Ryman DH. Circadian rhythms determined by
    %      cosine curve fitting: Analysis of continuous work and sleep-loss
    %      data. Behavior Research Methods, Instruments, & Coomputers. 1985,
    %      17: 630-641.
    %  [3] Cornelissen G. Cosinor-based rhythmometry. Theoretical Biol Med
    %      Model. 2014, 11: 16.
    %
    % $Author:  Peng Li
    %               Brigham and Women's Hospital
    %               Harvard Medical School
    % $Date:    Dec 11, 2021
    % $Modif.:  Nov 10, 2022
    %               add R2 and pValue properties
    %
    
    % inputs
    properties
        CycleLengthInHour
        StartDateTime
    end
    
    % optional inputs
    properties (Hidden = true)
        alpha
    end
    
    % outputs
    properties
        DataFitted
        Summary
    end
    
    % hidden outputs: components detals
    properties (Hidden = true)
        Verbose
        
        Mesor
        MesorCI
        
        Amplitude
        AmplitudeCI
        
        Acrophase
        AcrophaseCI
    end
    
    % hidden intermediate
    % check ref. [1] for notations
    properties (Hidden = true)
        betahat
        betaCI
        gammahat
        gammaCI
        x
        z
        X
        Z
        T
        RSS
        ErrorEllipse
        R2
        pValue
    end
    
    methods
        function this = cosinor(varargin)
            [cycleLengthInHour, alpha, startdatetime, allArg] = parse(varargin{:});
            
            % constructor
            this@timeseries(allArg{:});
            
            % added properties
            this.CycleLengthInHour = cycleLengthInHour;
            this.alpha             = alpha;
            this.StartDateTime     = startdatetime;
        end
    end
    
    % declaration only
    methods
        this = fit(this);
        this = ci(this);
        this = plot(this, varargin);
    end
end

%% local
function [cycleLengthInHour, alpha, startdatetime, allArg] = parse(varargin)
allArg = varargin;
if nargin >= 2
    argLength = find(strcmpi(allArg, 'cyclelengthinhour'));
    if ~isempty(argLength)
        cycleLengthInHour = allArg{argLength + 1};
        allArg([argLength, argLength+1]) = [];
    else
        cycleLengthInHour = 24;
    end
    
    argAlpha = find(strcmpi(allArg, 'alpha'));
    if ~isempty(argAlpha)
        alpha = allArg{argAlpha + 1};
        if ~(isscalar(alpha) && isnumeric(alpha))
            error('construction:properties:value not allowed (alpha should be a single numeric input)');
        end
        
        allArg([argAlpha, argAlpha+1]) = [];
    else
        alpha = 0.05;
    end
    
    argStart = find(strcmpi(allArg, 'startdatetime'));
    if ~isempty(argStart)
        startdatetime = allArg{argStart + 1};
        
        if ~isa(startdatetime, 'datetime')
            error('construction:properties:value not allowed (StartDateTime should be a datetime scalar)');
        end
        
        allArg([argStart, argStart+1]) = [];
    else
        startdatetime = NaT;
    end
end
end