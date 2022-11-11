function this = isivAnalysis(this)
%ISIVANALYSIS Perform nonparametric ISIV analysis on an ACTI object
% 
% $Author:  Peng Li
% $Date:    Jun 15, 2020
% 

period = this.ISIVInfo.PeriodInHour;
epoch  = this.Epoch / 60; % in min
cycle  = this.ISIVInfo.FixedCycles;
x      = this.Data;
x(this.GapSeries) = nan;

% init
defVal = nan(numel(this.ISIVInfo.TimeScaleInMin), 1);
this.ISIVSummary = table(defVal, defVal, defVal, defVal, defVal, defVal, ...
    'VariableNames', {'is', 'iv', 'current_period', 'perc_missing_data', 'perc_missing_bin', 'timescale'});

nonparaTbl = cell(numel(this.ISIVInfo.TimeScaleInMin), 1);
for iT = 1:numel(this.ISIVInfo.TimeScaleInMin)
    scale  = this.ISIVInfo.TimeScaleInMin(iT);
    
    [is, iv, current_period, perc_missing_data, perc_missing_bin] = ...
        isiv(x, epoch, scale, period, cycle);
    current_period = current_period(:);
    
    tbl = table(is, iv, current_period, perc_missing_data, perc_missing_bin);
    tbl.timescale = scale .* ones(numel(is), 1);
    
    nonparaTbl{iT} = tbl;
end

if ~isempty(vertcat(nonparaTbl{:}))
    this.ISIVSummary = vertcat(nonparaTbl{:});
end