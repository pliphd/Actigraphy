function this = sleepDet(this)
%SLEEPDET Perform sleep detection on an ACTI object
% 
% $Author:  Peng Li
% $Date:    Dec 02, 2020
% $Modif.:  May 17, 2021
%               generate window from doMask2 instead of recalculate based
%               on mask series
%           Jun 24, 2021
%               see comments below for summary statics
%           Jun 25, 2021
%               nan gap epochs
%           Jan 04, 2024
%               allow Actiware sleep detection approach
%           Jan 30, 2024
%               revise algorithms for calc. of waso and times awake
%           Oct 15, 2025
%               add post-hoc sleep episode clean-up based on Option field
%               clean up summary stat based on what are actually calculated
%               some summary stat do not make sense for nap, 24-h sleep, or
%                   nocturnal sleep
%           Feb 15, 2026
%               add mask through primary sleep sense
%           Feb 16, 2026
%               revise the calculating logic
%                   (1) smooth the identified sleepSeries to better
%                       determine sleep bout
%                   (2) sleep bout starts or stops in the boundary of
%                       SleepWindow will be considered (instead of
%                       truncated as did before)
%                   (3) duration and waso will be calculated based on
%                       original sleepSeries
%                   (4) nap will be those outside of SleepWindow and
%                       removing those extended into SleepWindow (instead
%                       of truncated as happened before)
%                   (5) partially nights will be flagged and will not be
%                       contributing to summary results
% 

x   = this.Data;
len = length(x);
x(this.GapSeries) = nan;

% sleep detection
switch this.SleepInfo.Method
    case 'Cole-Kripke'
        sleepSeries = doSleepDet2(x, this.Epoch, ...
            this.SleepInfo.ModeParameter.V, ...
            this.SleepInfo.ModeParameter.P, ...
            this.SleepInfo.ModeParameter.C);
    case 'Actiware'
        sleepSeries = doSleepDetActiware(x, this.Epoch, this.SleepInfo.ModeParameter.T);
end

% identify primary sleep window
switch this.SleepInfo.Option
    case 'Estimate'
        this = this.primarySleepSense;
        mask = ~this.SleepWindow;
    case 'Fixed'
        mask = doMask2(len, this.Epoch, this.TimeInfo.StartDate, ...
            this.SleepInfo.StartTime, this.SleepInfo.EndTime);
        this.SleepWindow = ~mask;
end

% calculate sleep metrics
res = calcSleep(sleepSeries, mask, this.GapSeries, this.Epoch);

% pack results to class
% 1. sleep series and episodes
this.SleepSeries = res.sleepSeries;
this.Sleep       = detConstantOne(this.SleepSeries);

% 2. sleep onset and offset in clock hours
clockTime = this.TimeInfo.StartDate + seconds(this.Time);

sleepOnset = res.onoff(:, 1);
if res.is_partial_night(1)
    sleepOnset(1) = [];
end
this.SleepSummary.PrimaryOnset = sleepOnset;

sleepOffset = res.onoff(:, 2);
if res.is_partial_night(end)
    sleepOffset(end) = [];
end
this.SleepSummary.PrimaryOffset = sleepOffset;

avgOnset  = circAvg(seconds(timeofday(clockTime(sleepOnset))));
avgOnset.Format = 'hh:mm:ss';

avgOffset = circAvg(seconds(timeofday(clockTime(sleepOffset))));
avgOffset.Format = 'hh:mm:ss';

% 3. valid start and end indices used to calculate summary statistics
this.SleepSummary.ValidIndex = res.valid_idx;

% 4. summary report
this.SleepSummary.Report = table(res.total_sleep_min_24h/60, ...
    avgOnset, avgOffset, res.nocturnal_sleep_min/60, res.waso_min, ...
    res.nap_duration_per_day_min, res.nap_freq_per_day, ...
    'VariableNames', {'total_sleep_h', ...
        'primary_onset', 'primary_offset', 'primary_sleep_h', 'waso_min', ...
        'nap_h', 'nap_times'});

% 5. back-up meta for use
resMeta.nightly_duration = res.nightly_duration;
resMeta.nightly_was = res.nightly_waso;
resMeta.is_partial_night = res.is_partial_night;
resMeta.onoff = res.onoff;
resMeta.message = res.message;
this.SleepSummary.Meta = resMeta;

this.message.content = this.SleepSummary.Meta.message;
this.message.type = 'success';
this.analysis.sleep = 1;
end

% helper functions
function res = calcSleep(sleepSeries, mask, gapSeries, epoch_sec)
    % INPUTS:
    % sleepSeries:  Binary vector (0=wake, 1=sleep)
    % mask:         Binary vector (Primary Sleep Window)
    % gapSeries:    Binary vector (1 = Invalid/Off-wrist data/other invalid detected already in actigraphy)
    % epoch_sec:    Scalar (Epoch length in seconds)

    % PARAMETERS
    same_sleep_thre_min = 5;
    same_sleep_points   = (same_sleep_thre_min * 60) / epoch_sec;
    nap_thre            = 5 * 60 / epoch_sec;

    % 1. SMOOTH SLEEP (Bridge gaps < 3 min)
    bridgedSleep = bridge_same_sleep(sleepSeries, same_sleep_points);
    
    % 2. PRIMARY SLEEP WINDOW (Based on Mask)
    [mask_starts, mask_ends] = find_bouts(mask);
    num_nights = length(mask_starts);
    
    % 3. POTENTIAL SLEEP BOUTS (Based on bridged/smoothed sleep)
    [bout_starts, bout_ends] = find_bouts(bridgedSleep);
    num_bouts = length(bout_starts);
    
    % Initialize storage
    nocturnal_sleep_min = zeros(num_nights, 1);
    waso_min            = zeros(num_nights, 1);
    onset_indices       = zeros(num_nights, 1);
    offset_indices      = zeros(num_nights, 1);
    
    % Flag for partial nights (True if incomplete or touching a gap)
    is_partial_night    = false(num_nights, 1);
    
    % Track which sleep bouts are nocturnal/primary (to separate Naps later)
    bout_is_nocturnal   = false(num_bouts, 1);
    
    % 4. NOCTURNAL ANALYSIS
    nocSeries = zeros(size(sleepSeries)); 
    
    for iN = 1:num_nights
        m_start = mask_starts(iN);
        m_end   = mask_ends(iN);
        
        % --- CRITERIA 1: Check Recording Boundaries ---
        if m_start == 1 || m_end == length(sleepSeries)
            is_partial_night(iN) = true;
        end
        
        % Find overlapping bridged bouts
        overlapping_bouts_idx = find(bout_starts < m_end & bout_ends > m_start);
        
        if isempty(overlapping_bouts_idx)
            onset_indices(iN) = NaN; offset_indices(iN) = NaN;
            % If no sleep occurred in primary window, is it effectively 0 min sleep?
            % Or is it invalid?
            % Decided to treat as 0 unless gap exists.
            % Check for gap in this empty window:
            if any(gapSeries(m_start:m_end))
                is_partial_night(iN) = true;
            end
            continue;
        end
        
        % Mark bouts as nocturnal
        bout_is_nocturnal(overlapping_bouts_idx) = true;
        
        % Define Adjusted Window (Onset/Offset)
        adj_start = bout_starts(overlapping_bouts_idx(1));
        adj_end   = bout_ends(overlapping_bouts_idx(end));
        
        onset_indices(iN)  = adj_start;
        offset_indices(iN) = adj_end;

        % --- CRITERIA 2: Check Gap Boundaries ---
        
        % Scenario 1: Onset is at the right edge of a gap
        % (i.e., the point immediately preceding onset is invalid)
        % sometimes, it may not be immediately preceding onset (small
        % activties in sleep, so add another criterion using primary sleep
        % window
        if adj_start > 1 && gapSeries(adj_start - 1) == 1 || any(gapSeries(m_start:m_end))
            is_partial_night(iN) = true;
        end
        
        % Scenario 2: Offset is at the left edge of a gap
        % (i.e., the point immediately following offset is invalid)
        % previous any() syntax will safeguard if gap is not immediately
        % following offset
        if adj_end < length(gapSeries) && gapSeries(adj_end + 1) == 1
            is_partial_night(iN) = true;
        end
        
        % Scenario 3: Gap is fully within the sleep window
        % (Any point between onset and offset is invalid)
        if any(gapSeries(adj_start:adj_end))
            is_partial_night(iN) = true;
        end
        
        % Calculate metrics 
        % If partial, calculate raw numbers for nightly_duration i meta data, 
        % but they won't contribute to the final average
        window_data = sleepSeries(adj_start:adj_end);
        nocSeries(adj_start:adj_end) = window_data;
        
        % Note: If gap exists inside, window_data will contain 0s
        nocturnal_sleep_min(iN) = sum(window_data == 1) * epoch_sec / 60;
        waso_min(iN) = sum(window_data == 0) * epoch_sec / 60;
    end

    % Clean up invalid indices (where no sleep was found)
    inv_idx = isnan(onset_indices);
    if any(inv_idx)
        onset_indices(inv_idx)  = [];
        offset_indices(inv_idx) = [];
        nocturnal_sleep_min(inv_idx) = [];
        waso_min(inv_idx) = [];
        is_partial_night(inv_idx) = [];
    end
    
    % 5. NAP ANALYSIS
    nap_bouts_idx = find(~bout_is_nocturnal);
    
    % Reconstruct napSeries
    napSeries = zeros(size(sleepSeries));
    for k = 1:length(nap_bouts_idx)
        idx = nap_bouts_idx(k);

        b_s = bout_starts(idx); 
        b_e = bout_ends(idx);
        
        % Extra Nap Criterion:
        
        % 5.1. Get the RAW series in this bout
        raw_bout = sleepSeries(b_s:b_e);
        
        % 5.2. Find contiguous Sleep segments inside this bout (to check >5min)
        [sub_starts, sub_ends] = find_bouts(raw_bout);
        
        % 5.3. Filter sub-segments < 5 mins
        valid_sub_mask = false(size(raw_bout));
        for s = 1:length(sub_starts)
            dur_pts = sub_ends(s) - sub_starts(s) + 1;
            if dur_pts >= nap_thre
                valid_sub_mask(sub_starts(s):sub_ends(s)) = true;
            end
        end
        
        % 5.4. Add valid sub-segments to the global napSeries
        % (Only where valid_sub_mask is true AND raw_bout was 1)
        napSeries(b_s:b_e) = valid_sub_mask & raw_bout;
    end
    
    % 6. OUTPUTS
    % 6.A. Valid Filter (Exclude Partial/Gap-Affected Nights)
    valid_nights_idx = find(~is_partial_night);
    
    if isempty(valid_nights_idx)
        msg = 'All nights appeared to be partial/truncated or contain gaps.';
        avg_nocturnal_sleep = NaN;
        avg_waso = NaN;
    else
        msg = ['Sleep summary data were aggragated from ' num2str(sum(~is_partial_night)) ' nights.'];
        avg_nocturnal_sleep = mean(nocturnal_sleep_min(valid_nights_idx));
        avg_waso = mean(waso_min(valid_nights_idx));
    end
    
    % 6.B. Total 24h Sleep
    % Re-Construct full valid sleepSeries
    full_valid_sleep = nocSeries | napSeries;
    
    % Define Valid Analysis Window (Trim partial nights at edges)
    if isempty(onset_indices)
        % Fallback if no nights detected at all
        start_valid_idx = 1; 
        end_valid_idx = length(sleepSeries);
    else
        if is_partial_night(1) && length(onset_indices) > 1
            start_valid_idx = onset_indices(2);
        else
            start_valid_idx = onset_indices(1);
        end
        
        if is_partial_night(end) && length(offset_indices) > 1
            end_valid_idx = offset_indices(end-1);
        else
            end_valid_idx = offset_indices(end);
        end
    end
    
    % Safety check on indices
    if start_valid_idx >= end_valid_idx
        valid_days = 0;
        valid_series = [];
    else
        raw_duration_epochs = end_valid_idx - start_valid_idx + 1;
        
        gap_epochs_in_window = sum(gapSeries(start_valid_idx:end_valid_idx));
        effective_duration_epochs = raw_duration_epochs - gap_epochs_in_window;
        
        valid_days = effective_duration_epochs * epoch_sec / (24 * 3600);
        valid_series = full_valid_sleep(start_valid_idx:end_valid_idx);
    end
    
    if valid_days > 0
        total_sleep_min_24h = (sum(valid_series) * epoch_sec / 60) / valid_days;
    else
        total_sleep_min_24h = NaN;
    end

    % 6.C. Nap Stats (Within Valid Window)
    valid_nap_count = 0;
    valid_nap_duration = 0;
    
    [final_nap_starts, final_nap_ends] = find_bouts(napSeries);
    
    for k = 1:length(final_nap_starts)
        n_s = final_nap_starts(k);
        n_e = final_nap_ends(k);
        
        % Check if this nap is within the valid timeline
        if n_s >= start_valid_idx && n_e <= end_valid_idx
            valid_nap_count = valid_nap_count + 1;
            valid_nap_duration = valid_nap_duration + sum(napSeries(n_s:n_e)) * epoch_sec / 60;
        end
    end
    
    if valid_days > 0
        nap_freq_per_day = valid_nap_count / valid_days;
        nap_duration_per_day = valid_nap_duration / valid_days;
    else
        nap_freq_per_day = NaN;
        nap_duration_per_day = NaN;
    end
    
    % 6.D. Pack Results
    res.total_sleep_min_24h = total_sleep_min_24h;
    res.nocturnal_sleep_min = avg_nocturnal_sleep;
    res.waso_min = avg_waso;
    res.nap_freq_per_day = nap_freq_per_day;
    res.nap_duration_per_day_min = nap_duration_per_day;
    
    % Metadata
    res.sleepSeries = full_valid_sleep;
    res.nightly_duration = nocturnal_sleep_min;
    res.nightly_waso = waso_min;
    res.valid_days_used = valid_days;
    res.is_partial_night = is_partial_night;
    res.valid_idx = [start_valid_idx, end_valid_idx];
    res.onoff = [onset_indices offset_indices];
    res.message = msg;
end

% --- HELPERS ---

function bridged = bridge_same_sleep(series, max_gap_points)
    bridged = series;
    d = diff([1; series; 1]);
    starts = find(d == -1);
    ends = find(d == 1) - 1;
    if isempty(starts), return; end
    for i = 1:length(starts)
        len = ends(i) - starts(i) + 1;
        if len < max_gap_points
            bridged(starts(i):ends(i)) = 1;
        end
    end
end

function [starts, ends] = find_bouts(binary_vec)
    % Standard RLE to find runs of 1s
    if isempty(binary_vec)
        starts = []; ends = []; return;
    end
    diff_vec = diff([0; binary_vec(:); 0]);
    starts = find(diff_vec == 1);
    ends = find(diff_vec == -1) - 1;
end

function res = circAvg(times_seconds)
% Convert times to radians (0 to 2*pi)
T = 24 * 60 * 60; % Total seconds in a day
theta = (times_seconds / T) * (2 * pi);

% Calculate the mean using circular statistics
mean_theta = atan2(mean(sin(theta)), mean(cos(theta)));

% Convert the mean angle back to seconds
% Adjust for negative angles if necessary
if mean_theta < 0
    mean_theta = mean_theta + 2 * pi;
end
average_seconds = (mean_theta / (2 * pi)) * T;

res = seconds(average_seconds);
end