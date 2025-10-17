function [para, verbose, success] = optiCalib(accIn, varargin)
%OPTICALIB optimize calibration parameters for auto-calibrate 3-D
%accelerometer signals
% 
% INPUTS
%   ACCIN:              3-D accelerometer data, unit g, N by 3 matrix
%   
%   optional
%   MAXITER             maximum number of interations, default 100
%   TOL                 tolerance for error, default 1e-3
% 
% OUTPUTS
%   PARA:               Parameters for calibration
%                           2 by 3 matrix
%                           ---------------
%                           offset_i
%                           scale_i
% 
%                           i = x, y, z
% 
%   VERBOSE:            Message
%   SUCCESS:            1 or 0 (not success)
% 
% $Author:  Peng Li, Ph.D.
% $Date:    Mar 14, 2025
% 

p = inputParser;
    
% optional paramters
addOptional(p, 'maxIter', 100,  @isnumeric);
addOptional(p, 'tol',     1e-3, @isnumeric);
addOptional(p, 'plot',    1,    @isnumeric);

% parse inputs
parse(p, varargin{:});
p = p.Results;

% default output
para    = [0 0 0; 1 1 1];
verbose = '\n';
success = 0;

% get rid of missing data
accIn(any(isnan(accIn), 2), :) = [];

% error check, stringent
% technically, the max of absolute values along each axis should be close
% to 1g, eitherwise, consider sensor problems
if sum(max(abs(accIn), [], 1) > 0.5) < 3
    verbose = [verbose sprintf('Sensor check:\n\tThere are potential sensor errors, unless data was collected with no movement at all.\n')];
    return;
else
    verbose = [verbose sprintf('Sensor check:\n\tPassed!\n')];
end

% data too short
if size(accIn, 1) < 10
    verbose = [verbose sprintf('Quality check:\n\tData is too short for performing calibration.\n')];
    return;
else
    verbose = [verbose sprintf('Quality check:\n\tPassed!\n')];
end

% optimization
iTer = 0;
while iTer < p.maxIter
    % model
    % Aout_i = offset_i + scale_i * Ain_i
    % i = 1, 2, 3 for X, Y, Z
    % 
    aOut     = para(1, :) + para(2, :) .* accIn;
    aOutNorm = aOut ./ sqrt(sum(aOut .^ 2, 2));

    % back up scale for computing tol
    prevScale = para(2, :);

    % fit a linear model along each axis to optimize offset_i and scale_i
    for iD = 1:size(aOut, 2)
        % linear regression (faster than built-in function)
        x = aOut(:, iD);
        Y = aOutNorm(:, iD);
        V = [ones(length(x), 1) x];       % Vandermonde matrix [1 x x^2 ...] linear fit so up to order 1
        [Q, R] = qr(V, 0);
        P      = R \ (transpose(Q) * Y);  % equivalent to (V \ Y)

        para(1, iD) = para(1, iD) + P(1);
        para(2, iD) = para(2, iD) * P(2);
    end

    % convergence evaluation
    if sum(abs(para(2, :) - prevScale)) < p.tol
        verbose = [verbose sprintf('Convergence:\n\tReached convergence after %d iterations!\n', iTer)];
        success = 1;

        if p.plot
            accOut = calibAcc(accIn, para);
            hf = figure(Color='w', Name='Raw Data Visualization: Accelerometer 3-D Calibration');
            ha = axes(hf, Units='normalized', Position=[.1, .1, .8, .8]);
            plot3(ha, accIn(:, 1),  accIn(:, 2),  accIn(:, 3),  'LineStyle', 'none', 'marker', '.');
            hold on;
            plot3(ha, accOut(:, 1), accOut(:, 2), accOut(:, 3), 'LineStyle', 'none', 'marker', '.', 'Color', 'r');
            axis(ha, 'square');

            xlabel('X'); ylabel('Y'); zlabel('Z');

            ha.XLim = [-1.1 1.1];
            ha.YLim = ha.XLim; ha.ZLim = ha.XLim;

            ha.XTick = -1:.5:1;
            ha.YTick = ha.XTick; ha.ZTick = ha.XTick;

            legend(ha, {'Before calibration', 'After calibration'}, 'Location', 'best');
            title('Calibration sphere based on non-moving segments');
        end

        return;
    end

    iTer = iTer + 1;
end

% if convergence not reached
verbose = [verbose sprintf('Warning:\n\tConvergence not reached after maximum (%d) interations.\n', p.maxIter)];