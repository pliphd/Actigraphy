function this = isivAnalysis(this)
%ISIVANALYSIS Perform nonparametric ISIV analysis on an ACTI object
% 
% $Author:  Peng Li
% $Date:    Jun 15, 2020
% $Modif.:  Mar 8, 2026
%               Revise to enable multiscale and max IS calculation
%               Default output will be max IS at scale 60 or first scale if
%                   60 not available
%               Other results will be in ReportDetail
%               Store IS and Period info in Periodogram
% 

period = this.ISIVInfo.PeriodInHour;
epoch  = this.Epoch / 60; % in min
cycle  = this.ISIVInfo.FixedCycles;
scale  = this.ISIVInfo.TimeScaleInMin;
x      = this.Data;
x(this.GapSeries) = nan;

% check if signal is long enough for FixedCycles
avg_period = mean(period); % most of the time, period will be a scalar. period is a vector only when we want to do periodogram for max IS and best period
n_cycles   = length(x) * epoch / 60 / avg_period;
if n_cycles < cycle
    this.message.content = sprintf('Signal is too short: %.2f cycles < %d required. ISIV analysis skipped.', n_cycles, cycle);
    this.message.type = 'warning';
    this.analysis.isiv = 0;
    return;
end

% init
defVal     = nan(numel(this.ISIVInfo.TimeScaleInMin), 1);
rep_detail = table(defVal, defVal, defVal, defVal, defVal, defVal, ...
    'VariableNames', {'timescale', 'is', 'iv', 'current_period', 'perc_missing_data', 'perc_missing_bin'});

rep   = rep_detail(1, :);
isAll = nan;
pAll  = period;

nonparaTbl = cell(numel(scale), 1);
for iT = 1:numel(this.ISIVInfo.TimeScaleInMin)
    sc = scale(iT);
    
    [is, iv, current_period, perc_missing_data, perc_missing_bin] = ...
        isiv(x, epoch, sc, period, cycle);

    current_period = current_period(:);
    
    tbl = table(is, iv, current_period, perc_missing_data, perc_missing_bin);
    tbl.timescale = sc .* ones(numel(is), 1);
    
    nonparaTbl{iT} = tbl;
end

if ~isempty(vertcat(nonparaTbl{:}))
    rep_detail = vertcat(nonparaTbl{:});

    % periodogram
    if ~isscalar(period)
        isAll = reshape(rep_detail.is, [], numel(scale));
        pAll  = unique(rep_detail.current_period);
    else
        isAll = rep_detail.is;
        pAll  = period;
    end

    % give report at max IS at scale 60 (or first scale if 60 is not provided)
    if any(scale == 60)
        sc = 60;
    else
        sc = scale(1);
    end
    repC = rep_detail(rep_detail.timescale == sc, :);
    [isC, mind] = max(repC.is);
    ivC = repC.iv(mind);
    current_periodC = repC.current_period(mind);
    perc_missing_dataC = repC.perc_missing_data(mind);
    perc_missing_binC = repC.perc_missing_bin(mind);
    rep = table(sc, isC, ivC, current_periodC, perc_missing_dataC, perc_missing_binC, ...
        'VariableNames', {'timescale', 'is', 'iv', 'current_period', 'perc_missing_data', 'perc_missing_bin'});
end

this.ISIVSummary.Report = rep;
this.ISIVSummary.ReportDetail = rep_detail;
this.ISIVSummary.Periodogram = struct('is', isAll, 'period', pAll);

this.message.content = sprintf('ISIV analysis is completed.');
this.message.type = 'success';
this.analysis.isiv = 1;