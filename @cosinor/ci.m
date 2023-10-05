function this = ci(this)
%CI statistical inference
%
% Note:
%   Only works when one component is fitted.
%   For multiple components fit, math hasn't been worked out
%
% see also: FIT, PLOT, COSINOR
%
% $Author:  Peng Li
%               Brigham and Women's Hospital
%               Harvard Medical School
% $Date:    Dec 13, 2021
% $Modif.:  Nov 10, 2022
%               add verbose
%

if ~isscalar(this.CycleLengthInHour)
    this.AmplitudeCI = nan(numel(this.Amplitude), 2);
    this.AcrophaseCI = this.AmplitudeCI;
else
    n = numel(this.Time) - sum(isnan(this.Data));

    X = 1/n * sum((this.x - mean(this.x)).^2);
    Z = 1/n * sum((this.z - mean(this.z)).^2);
    T = 1/n * sum((this.x - mean(this.x)) .* (this.z - mean(this.z)));

    sigma2 = this.RSS / (n-3);

    % define error ellipse
    % X(beta-betahat)^2 + 2T(beta-betahat)(gamma-gammahat) + Z(gamma-gammahat)^
    % - 2/n*sigma2*finv(1-this.alpha, 2, n-3)
    %
    % do some algebra to make it
    % A*gamma^2 + 2*B*gamma*beta + C*beta^2 + 2*D*gamma + 2*E*beta + F = 0
    % gamma -- x
    % beta  -- y
    %
    A = Z;
    B = T;
    C = X;
    D = -Z*this.gammahat - T*this.betahat;
    E = -X*this.betahat  - T*this.gammahat;
    F = X*this.betahat^2 + Z*this.gammahat^2 + 2*T*this.betahat*this.gammahat - 2/n*sigma2*finv(1-this.alpha, 2, n-3);

    % matrix representation of the quadratic term
    %               [A B] [gamma]
    % [gamma, beta] |   | |     |
    %               [B A] [beta ]
    % say theta is the rotation angle of the ellipse (NOTE, this is not the
    % acrophase this.theta)
    % new axis is [x, y] so that the ellipse major and minor axis is parallel
    % to axis
    %
    % [gamma]   [cos(theta) -sin(theta)] [x]
    % |     | = |                      | | |
    % [beta ]   [sin(theta)  cos(theta)] [y]
    %
    % or
    %
    % [x]   [cos(theta)  sin(theta)] [gamma]
    % | | = |                      | |     |
    % [y]   [-sin(theta) cos(theta)] [beta ]
    %
    % plug these in, and get the equation of x and y
    % the coeficient of x*y should be zero (so that no rotation)
    %
    % with this, we can calculate now the rotation angle, which is given by
    % theta = 1/2 * atan(2*B/(A-C))
    %
    % and the major and minor axes are
    %
    % a = sqrt(x01^2 + (y01^2 * (C-B*tan(theta)) - F) / (A + B*tan(theta)))
    % b = sqrt(y01^2 + (x01^2 * (A+B*tan(theta)) - F) / (C - B*tan(theta)))
    %
    % [x01, y01] are the center of the ellipse after rotation
    %

    theta = 1/2 * atan2(2*B, A-C); % atan2 results in [-pi, pi]

    x0  = this.gammahat;
    y0  = this.betahat;
    x01 =  cos(theta)*x0 + sin(theta)*y0;
    y01 = -sin(theta)*x0 + cos(theta)*y0;

    a   = sqrt(x01^2 + (y01^2 * (C-B*tan(theta)) - F) / (A + B*tan(theta)));
    b   = sqrt(y01^2 + (x01^2 * (A+B*tan(theta)) - F) / (C - B*tan(theta)));

    % then we can write down the standard function
    t = linspace(0, 2*pi, 1000);
    x = a*cos(t);
    y = b*sin(t);

    Ex = x*cos(theta) - y*sin(theta) + x0;
    Ey = x*sin(theta) + y*cos(theta) + y0;

    this.ErrorEllipse = [Ex(:) Ey(:)];

    % estimate the error
    allAmp = sqrt(Ex.^2 + Ey.^2);

    % if (0,0) is within the ellipse, do nothing
    % plug (0,0) into the ellipse function, only F leaves, others are all zero
    if F < 0
        this.AmplitudeCI = [nan max(allAmp)];
        this.AcrophaseCI = [nan nan];
        return;
    end

    this.AmplitudeCI = [min(allAmp) max(allAmp)];

    allPhase = atan2d(Ex, Ey); % atan2d gives range [-180, 180]

    % when allPhase has elements close to zero
    % need to use original allPhase between [-180, 180] to determine CI
    % in case messing up after moving to [0 360] since the region crosses zero
    % degree
    if any(ismembertol(allPhase, 0, .01))
        p_lower = min(allPhase);
        if p_lower < 0, p_lower = p_lower + 360; end, p_lower = -p_lower;
        p_upper = max(allPhase);
        if p_upper < 0, p_upper = p_upper + 360; end, p_upper = -p_upper;
    else
        allPhase(allPhase < 0) = allPhase(allPhase < 0) + 360;
        allPhase = -allPhase;
        p_lower  = min(allPhase);
        p_upper  = max(allPhase);
    end

    this.AcrophaseCI = [p_lower, p_upper];
end

% verbose
verbose = sprintf('%s\n%s\n\n', 'Cosinor analysis results:', this.Verbose);

verbose = [verbose sprintf('mesor:\t\t%.2f (%.2f, %.2f)\n\n', this.Mesor, this.MesorCI(1), this.MesorCI(2))];

for iC  = 1:length(this.CycleLengthInHour)
    verbose = [verbose sprintf('cycle:\t\t%d\namplitude:\t%.2f (%.2f, %.2f)\nphase:\t\t%.2f (%.2f, %.2f)\n\n', ...
        this.CycleLengthInHour(iC), this.Amplitude(iC), this.AmplitudeCI(iC, 1), this.AmplitudeCI(iC, 2), this.Acrophase(iC), this.AcrophaseCI(iC, 1), this.AcrophaseCI(iC, 2))];
end

this.Verbose = verbose;