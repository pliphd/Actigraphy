function [Y, pValue, Rsquare, Component, varargout] = CosAna(y, tsec, FitFreq)
%COSANA Cosinor fitting
% 
% Inputs:
%           y          --- data to be fitted
%           tsec       --- time axis in seconds
%           FitFreq    --- target frequency (in hours), use vector for
%                        multipe components, e.g., [24 12]
% Outputs:
%           Y          --- fitting results (same length as y)
%           pValue     --- significant level
%           Rsquare    --- the R2 statistic
%           Component  --- a structure that contains following fields
%                           AC:      ampilitude of each component
%                           theta:   phase of each component
%                           const:   constant component
%                           Expr:    fitting results expression
%                           FitFreq: same as input FitFreq, correponds to
%                                    each w variable in the Expr
%           Verbose    --- additional output for command display
% 
% Ref. Naitoh P, Englund CE, Ryman DH. Circadian rhythms determined by
%      cosine curve fitting: Analysis of continuous work and sleep-loss
%      data. Behavior Research Methods, Instruments, & Coomputers. 1985,
%      17: 630-641.
% 
% $Author:  Peng Li
%               Brigham and Women's Hospital
%               Harvard Medical School
%               pli9@bwh.harvard.edu
% $Date:    Jul. 6, 2017
% $Modif.:  Dec 27, 2019
%               add verbose output
% 


% model
CosComp = cos(2*pi .* (tsec(:) * (1./(FitFreq(:)'*3600))));
SinComp = sin(2*pi .* (tsec(:) * (1./(FitFreq(:)'*3600))));

% multiple regression
X = [CosComp SinComp ones(length(y), 1)];
[b, ~, ~, ~, stats] = regress(y(:), X);

pValue  = stats(3);
Rsquare = stats(1);

% parse expression
bComp = reshape(b(1:end-1), [], 2);
theta = atand(bComp(:, 2)./bComp(:, 1));
theta((theta > 0) & (bComp(:, 2) < 0)) = theta((theta > 0) & (bComp(:, 2) < 0)) + 180;
theta((theta < 0) & (bComp(:, 2) > 0)) = theta((theta < 0) & (bComp(:, 2) > 0)) + 180;

Expr    = ['Y = ' sprintf('%.2f', b(end))];
for iC   = 1:length(FitFreq)
    AC   = sqrt(bComp(iC, 1)^2 + bComp(iC, 2)^2);
    Expr = [Expr ' + ' sprintf('%.2f', AC) 'cos(w(' num2str(iC) ')t - ' sprintf('%.2f', theta(iC)) '°)'];
end

if nargout == 5
    verbose = sprintf('%s\n%s\n\n%s\n', 'Cosinor analysis results:', Expr, 'Components:');
    for iC  = 1:length(FitFreq)
        verbose = [verbose sprintf('%s\n', ['   w(' num2str(iC) '): ' num2str(FitFreq(iC)) ' hours'])];
    end
    varargout{1} = verbose;
else
    % console verbose
    fprintf('%s\n', 'Cosinor analysis results:');
    fprintf('%s\n\n', Expr);
    fprintf('%s\n', 'Components:');
    for iC   = 1:length(FitFreq)
        disp(['   w(' num2str(iC) '): ' num2str(FitFreq(iC)) ' hours']);
    end
    fprintf('\n');
end

AC   = sqrt(bComp(:, 1).^2 + bComp(:, 2).^2);
Comp = (ones(length(tsec), 1)*AC(:)') .* cos(2*pi .* (tsec(:) * (1./(FitFreq(:)'*3600))) - ones(length(tsec), 1)*theta(:)'./180.*pi);
Y    = sum(Comp, 2) + b(end);

Component.AC       = AC;
Component.theta    = theta;
Component.const    = b(end);
Component.Expr     = Expr;
Component.FitFreq  = FitFreq;