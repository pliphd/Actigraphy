% Actigraphy Toolbox Demonstration
% 
% $Author:  Peng Li
% $Date:    Mar 09, 2026
% 
clc; close all; clear;

y = load('./test/case_5_20140319100100_epoch15.txt');
y = y(:, 1);

% construct the acti object
% note that acti is a value class subclassed from timeseries 
% every instance just stores a copy
% assignment is needed to update the objecvt, e.g., a = a.gapDet;
a = acti(y, 'Epoch', 15, 'StartTime', datetime('20140319100100', 'Format', 'yyyyMMddHHmmss'));

%% plot
h = a.plot;

%% gap auto detection
% default parameter: consecutive runs of zero > 60 min; merge two gaps if <
% 60 min apart.
a = a.gapDet;

% visualize gap
refreshGaps(a, h);

%% sleep
a.SleepInfo = struct('StartTime', '21:00', 'EndTime', '07:00', ...
    'ModeParameter', struct('P', 0.001, 'V', [106 54 58 76 230 74 67], 'C', 0, 'T', 40, ...
        'Prim', struct('zeta', 15, 'zeta_a', 2, 'zeta_r', 30, 'alpha', 8, 'hs', 8, 'Lp', 50)), ...
    'Method', 'Cole-Kripke');
a.SleepInfo.Option = 'Estimate';

a = a.sleepDet;

% visualize sleep
refreshPrimarySleep(a, h);
refreshSleep(a, h);

%% cosinor
a.CosinorInfo = struct('HarmonicsInHour', 24, 'MinimumLengthInDays', 2, 'CIAlpha', 0.05);
% HarmonicsInHour allows vector input to indicate ultradian or infradian
%   rhythms. E.g.: [24, 12, 9]
a = a.cosinorActi;

% visualize cosinor fit
refreshCircadian(a, h);

%% emd
a.EMDInfo = struct('TargetComponent', 24, 'MinimumLengthInDays', 5, 'UserData', []);
a = a.emd;
refreshCircadian(a, h);

%% m10l5
a = a.m10l5Analysis;

%% is iv
a.ISIVInfo = struct('TimeScaleInMin', 60, 'PeriodInHour', 24, 'FixedCycles', 5);
% both TimeScaleInMin and PeriodInHour allow vector input but in different
%   ways. If one wants to calculate IS/IV at multiple timescales, use
%   MATLAB vector syntax to indicate what timescales (e.g., 10:10:100). If
%   one wants to estimate the best period (based on IS/periodogram -
%   essentially they are the same), use [22, 24] to indicate the search
%   range
a = a.isivAnalysis;

%% report
exportReport(a, [], 'Filename', 'case_5_20140319100100_epoch15');