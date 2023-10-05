function this = plot(this, varargin)
%PLOT plot error ellipse on a clock axis
% 
% see also: FIT, CI, COSINOR
% 
% $Author:  Peng Li
%               Brigham and Women's Hospital
%               Harvard Medical School
% $Date:    Dec 13, 2021
% 

% only works for one component fit
if ~isscalar(this.CycleLengthInHour)
    return;
end

% axes
if nargin == 2
    if isa(varargin{1}, 'matlab.graphics.axis.Axes')
        h  = varargin{1};
    else
        hf = figure('Color', 'w');
        h  = axes(hf, 'Units', 'normalized', 'Position', [.1 .1 .8 .8]);
    end
else
    hf = figure('Color', 'w');
    h  = axes(hf, 'Units', 'normalized', 'Position', [.1 .1 .8 .8]);
end
h.NextPlot = 'add';

%% background clock
% plot inner circle
t  = linspace(0, 2*pi, 1000);

ri = 1.5*this.AmplitudeCI(2);
x  = ri*cos(t);
y  = ri*sin(t);

plot(h, x, y, 'k', 'LineWidth', 1);

% plot outer circle
ro = 1.8*this.AmplitudeCI(2);
x  = ro*cos(t);
y  = ro*sin(t);

plot(h, x, y, 'k', 'LineWidth', 1);

% mark time and degrees
timeVector   = datestr(datetime('00:00', 'InputFormat', 'HH:mm'):hours(3):datetime('21:00', 'InputFormat', 'HH:mm'), 'HH:MM');
degreeVector = 0:-45:-315;
rT = 1.6*this.AmplitudeCI(2);
rD = 1.9*this.AmplitudeCI(2);
for iT = 1:numel(degreeVector)
    text(h, rT*sin(-degreeVector(iT)/180*pi), rT*cos(-degreeVector(iT)/180*pi), timeVector(iT, :), ...
        'Rotation', degreeVector(iT), ...
        'HorizontalAlignment', 'center');
    
    text(h, rD*sin(-degreeVector(iT)/180*pi), rD*cos(-degreeVector(iT)/180*pi), num2str(degreeVector(iT))+"^{\circ}", ...
        'Rotation', degreeVector(iT), ...
        'HorizontalAlignment', 'center');
end

% plot ticks
% long ticks 1.4-1.5, 1.7-1.8 r, per 45 degrees
ri2 = 1.4*this.AmplitudeCI(2);
ro2 = 1.7*this.AmplitudeCI(2);
for iM = 1:numel(degreeVector)
    plot(h, [ri2*sin(-degreeVector(iM)/180*pi) ri*sin(-degreeVector(iM)/180*pi)], ...
        [ri2*cos(-degreeVector(iM)/180*pi) ri*cos(-degreeVector(iM)/180*pi)], ...
        'k', 'LineWidth', 1);
    plot(h, [ro2*sin(-degreeVector(iM)/180*pi) ro*sin(-degreeVector(iM)/180*pi)], ...
        [ro2*cos(-degreeVector(iM)/180*pi) ro*cos(-degreeVector(iM)/180*pi)], ...
        'k', 'LineWidth', 1);
end

% short ticks 1.45-1.5 1.75-1.8 r, per 15 degrees
minorDegreeVector = 0:-15:-345;
ri2 = 1.45*this.AmplitudeCI(2);
ro2 = 1.75*this.AmplitudeCI(2);
for iM = 1:numel(minorDegreeVector)
    plot(h, [ri2*sin(-minorDegreeVector(iM)/180*pi) ri*sin(-minorDegreeVector(iM)/180*pi)], ...
        [ri2*cos(-minorDegreeVector(iM)/180*pi) ri*cos(-minorDegreeVector(iM)/180*pi)], ...
        'k');
    plot(h, [ro2*sin(-minorDegreeVector(iM)/180*pi) ro*sin(-minorDegreeVector(iM)/180*pi)], ...
        [ro2*cos(-minorDegreeVector(iM)/180*pi) ro*cos(-minorDegreeVector(iM)/180*pi)], ...
        'k');
end

% plot (0, 0)
plot(h, 0, 0, 'x', 'MarkerSize', 5, 'Color', 'k');

%% results specific modifications
% show indicator lines to better match the arrow to clock ticks
plot(h, [0 0], [0 ri], 'k--');
plot(h, [0 ri*sin(-this.Acrophase/180*pi)],  [0 ri*cos(-this.Acrophase/180*pi)], 'k--');

% add ticks on indicator lines
atick = 0:this.Amplitude/2:ri;
for iA = 1:numel(atick)
    plot(h, [0 ri/20], [atick(iA) atick(iA)], 'k');
    text(h, -ri/40, atick(iA), sprintf('%.2f', atick(iA)), 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
end

% plot ellipse
plot(h, this.ErrorEllipse(:, 1), this.ErrorEllipse(:, 2), 'Color', 'b');

% mark estimated Amplitude and Acrophase
quiver(h, 0, 0, this.gammahat, this.betahat, 'b-', 'LineWidth', 1, 'AutoScale', 'off', 'MaxHeadSize', .5);

% plot a curve to help read amplitude from amplitude ticks
t = linspace(0, -this.Acrophase, 100);
plot(h, this.Amplitude*sin(t/180*pi), this.Amplitude*cos(t/180*pi), 'k--');

% generate text message
tphi = "\phi = " + sprintf('%.2f', this.Acrophase);
tamp = "A = " + sprintf('%.2f', this.Amplitude);

% show confidence region
if ~isnan(this.AmplitudeCI(1))
    t = linspace(this.AcrophaseCI(1), this.AcrophaseCI(2), 500);
    x = ri*sin(-t/180*pi);
    y = ri*cos(-t/180*pi);
    fill(h, [0 x 0], [0 y 0], [.9 .9 .9]);
    hc = h.Children;
    h.Children = [hc(2:end); hc(1)];
    
    tphi = tphi + " (" + sprintf('%.2f', this.AcrophaseCI(1)) + ", " + sprintf('%.2f', this.AcrophaseCI(2)) +")";
    tamp = tamp + " (" + sprintf('%.2f', this.AmplitudeCI(1)) + ", " + sprintf('%.2f', this.AmplitudeCI(2)) +")";
end

% remove axes
h.XColor = 'none';
h.YColor = 'none';

% equal ratio
axis(h, 'equal');