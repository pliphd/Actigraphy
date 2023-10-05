function this = fit(this)
% FIT Fit a cosinor object based on LSE
% 
%   This can be done through minimizing the residual squared error
%       to solve normal equations -- RSS's first order derivatives w.r.t. each
%       parameter are zero
%       notation in Ref. [1] (check COSINOR)
%           y = M + Acos(wt+theta)
%           y = M + Acos(theta)cos(wt) - Asin(theta)sin(wt)
%           y = M + beta*x + gamma * z
% 
%           S = [N       sum(x)       sum(z)      ; ...
%                sum(x)  sum(x .^ 2)  sum(x .* z) ; ...
%                sum(z)  sum(x .* z)  sum(z .^ 2)];
%           d = [sum(y); sum(y .* x); sum(y .* z)];
%           uhat = S \ d;
% 
%           uhat is in the following order:
%               uhat = [M; beta; gamma]
%                       M:     mesor
%                       beta:  Acos(theta)
%                       gamma: -Asin(theta)
%   Or we can simply use the REGRESS function to solve this problem
% 
% see also CI, PLOT, COSINOR
% 
% $Author:  Peng Li
%               Brigham and Women's Hospital
%               Harvard Medical School
% $Date:    Dec 13, 2021
% $Modif.:  Nov 10, 2022
%               add verbose
% 

y = this.Data;
y(this.Quality ~= 1) = nan;

t = this.Time(:);                         % in sec

% by default, t is w.r.t. start of recording
% shift t based on actual StartDateTime
if ~isnat(this.StartDateTime)
    offsets = 3600*(24-hours(this.StartDateTime - ...
        datetime(year(this.StartDateTime), month(this.StartDateTime), day(this.StartDateTime))));
    t = t - offsets;
end

f = 1./(this.CycleLengthInHour(:)'*3600); % in Hz

n = numel(t);

% model
x = cos(2*pi .* (t * f));
z = sin(2*pi .* (t * f));

% multiple regression
X = [x z ones(length(y), 1)];
[b, bint, r, rint, stats] = regress(y(:), X, this.alpha);

% b in the order of 
% beta
% gamma
% M

% MESOR and its CI
this.Mesor   = b(end);
this.MesorCI = bint(end, :);

% Components
bComp    = reshape(b(1:end-1), [], 2);
betahat  = bComp(:, 1);
gammahat = bComp(:, 2);
betaCI   = bint(1:numel(betahat), :);
gammaCI  = bint(numel(betahat)+1:end-1, :);

theta = atan2d(gammahat, betahat);         % atan2d gives range [-180, 180]
theta(theta < 0) = theta(theta < 0) + 360; % move negative theta to [180, 360]
theta = -theta;                            % gamma is -sin(theta) or sin(-theta)

this.Amplitude = sqrt(betahat.^2 + gammahat.^2);
this.Acrophase = theta;

% fitted
Comp = (ones(n, 1)*this.Amplitude(:)') .* ...
    cos(2*pi .* (t * f) + ones(n, 1)*theta(:)'./180.*pi);
Y    = sum(Comp, 2) + b(end);

this.DataFitted = Y;

% feed class objects
this.betahat  = betahat;
this.gammahat = gammahat;
this.betaCI   = betaCI;
this.gammaCI  = gammaCI;
this.x        = x;
this.z        = z;
this.RSS      = sum(r.^2, 'omitnan');
this.R2       = stats(1);
this.pValue   = stats(3);

% verbose
expr    = ['Y = ' sprintf('%.2f', b(end))];
for iC   = 1:length(this.CycleLengthInHour)
    AC   = sqrt(bComp(iC, 1)^2 + bComp(iC, 2)^2);
    
    if theta(iC) < 0
        pm = ' - ';
    else
        pm = ' + ';
    end

    expr = [expr ' + ' sprintf('%.2f', AC) '*cos(w(' num2str(iC) ')t' pm sprintf('%.2f', abs(theta(iC))) '°)'];
end

this.Verbose = expr;