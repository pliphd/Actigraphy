function this = primarySleepSense(this)
%PRIMARYSLEEPSENSE Estimate primary sleep window on an ACTI object
% 
% Ref. [1] Crespo et al. Med Biol Eng Comput 2012. PMID: 22382991
% 
% Parameter setting:
%   SleepInfo.Option = 'Estimate'
%   SleepInfo.ModeParameter.Prim = ...
%           .zeta         Max valid consecutive zeroes (combined)
%           .zeta_a       Max valid consecutive zeroes (active)
%           .zeta_r       Max valid consecutive zeroes (rest)
%           .alpha        Window length parameter (hours)
%           .hs           Expected sleep duration (hours)
%           .Lp           Morphological window (minutes)
% 
% $Author:  Peng Li
% $Date:    Feb 15, 2026
% $Modif.:  Feb 24, 2026
%               While resample is nice, the built-in anti-aliasing filter
%                   will introduce negative activity counts (physiclly
%                   impossible) and turn true zeros into decimals.
%               The activity counts signal is technically "aggregation" of
%                   acceleration per epoch, so sum-up of sampling points
%                   should be the right way to go with.
% 

% resample to 1-min epoch to match the original alg
switch this.Epoch
    case 15
        p = 1; q = 4;
    case 30
        p = 1; q = 2;
    case 45
        p = 3; q = 4;
    case 60
        p = 1; q = 1;
end

% activity_signal_1min = resample(this.Data, p, q);

data    = this.Data;
rescale = 60 / this.Epoch;
switch rescale
    case {4, 2}
        tempLen = floor(length(data) / rescale) * rescale;
        if tempLen == length(data)
            rec1 = sum(reshape(data, rescale, []), 1, "omitnan")';
        else
            res  = sum(data(tempLen+1:end), "omitnan");
            rec1 = [sum(reshape(data(1:tempLen), rescale, []), 1, "omitnan")'; res(:)];
        end
    case 3
        return; % do nothing at this moment, to interp later
    case 1
        rec1 = data;
end

activity_signal_1min = rec1;

% direct use of default zeta
% see comments below in primSense function and estimate_zeta for the
% problems
% zeta = estimate_zeta(activity_signal_1min, 100, 1000, 0.05);

params = this.SleepInfo.ModeParameter.Prim;

primarySleep_1min = primSense(activity_signal_1min, params);
sleepWindow = double(resample(primarySleep_1min, q, p) > 0.5);
this.SleepWindow = sleepWindow(1:numel(this.Data));
end

function primarySleep = primSense(s, p)
% PRIMSENSE Implements the algorithm from Crespo et al. (2012)
%
% Inputs:
%   s - Actigraphy signal vector (1 sample/min)
%   p - Parameter struct (zeta, zeta_a, zeta_r, alpha, hs, t_percentile, Lp)
%
% Outputs:
%   final_output - Binary vector (0=Rest, 1=Activity)
%   debug - Struct containing intermediate signals

N = length(s);

% --- STAGE 1: PREPROCESSING (Section 2.1.1) ---

% 2.1.1.1 Signal conditioning based on empirical probability model
% Eq (1): Identify regions with > zeta consecutive zeroes
is_zero = (s == 0);

% Find sequences of zeroes
[zero_starts, zero_lens] = find_consecutive_runs(is_zero);

% can use a more robust approach based on the empirical distribution of 
% zero run lengths, to estimate zeta
% e.g., zeta = ceil(prctile(zero_lens, 95));

invalid_zero_indices = [];
for k = 1:length(zero_lens)
    if zero_lens(k) > p.zeta
        idx_range = zero_starts(k):(zero_starts(k) + zero_lens(k) - 1);
        invalid_zero_indices = [invalid_zero_indices, idx_range]; %#ok<AGROW>
    end
end

% Eq (2): Replace invalid zeroes with percentile p.hs/24
thresh_percentile = (p.hs / 24) * 100;

s_v = s;
s_v(invalid_zero_indices) = [];

s_t = max([1, prctile(s_v, thresh_percentile)]);
x   = s;
x(invalid_zero_indices) = s_t;

% Eq (3): Padding
% Pad with 30 * alpha elements of value m = max(s)
pad_len = 30 * p.alpha;

m_val   = prctile(s_v, 100-thresh_percentile);

padding = ones(pad_len, 1) .* m_val;
x_p     = [padding; x; padding];

% 2.1.1.2 Rank-order processing (Median Filter)
% Eq (4): Median filter. Window Lw = 60*alpha + 1
Lw = 60 * p.alpha + 1;

% Use medfilt1 with 'truncate' to handle edges, though padding handles main edges
x_f_padded = medfilt1(x_p, Lw, 'truncate');

% Remove padding to get x_f(n) corresponding to original signal size
x_f = x_f_padded(pad_len+1:end-pad_len);

% Eq (5): Rank-order thresholding
p_thresh = prctile(x_f, thresh_percentile);
y1       = double(x_f > p_thresh);

% 2.1.1.3 Morphological Filtering
% Eq (6): ye = (y1 . Lp) o Lp (Closing then Opening)
% Structural element size Lp (minutes)
y_e = morphological_closing_opening(y1, p.Lp);

% --- OPTIMIZED STAGE 2: PROCESSING ---

% 2.1.2.1 Model-based data validation
% Identify potential invalid runs of zeros separately during sleep and wake
b_indices = false(N, 1);

rest_regions = (y_e == 0);
s_rest_zeroes = (s == 0) & rest_regions;
[rz_starts, rz_lens] = find_consecutive_runs(s_rest_zeroes);
for k = 1:length(rz_lens)
    if rz_lens(k) > p.zeta_r
        b_indices(rz_starts(k):(rz_starts(k) + rz_lens(k) - 1)) = true;
    end
end

wake_regions = (y_e == 1);
s_wake_zeroes = (s == 0) & wake_regions;
[wz_starts, wz_lens] = find_consecutive_runs(s_wake_zeroes);
for k = 1:length(wz_lens)
    if wz_lens(k) > p.zeta_a
        b_indices(wz_starts(k):(wz_starts(k) + wz_lens(k) - 1)) = true;
    end
end

% 2.1.2.2 Adaptive rank-order processing

% 1. Handle invalid data by setting to NaN
s_clean = s;
s_clean(b_indices) = NaN;

% 2. Pad with 'm' (Max Value) as per paper to bias edges to 'Active'
% The paper pads with 60 mins (1 hour) of max value.
pad_len_2   = 60;
padding_vec = ones(pad_len_2, 1) .* m_val;
s_padded    = [padding_vec; s_clean; padding_vec];

% 3. Apply Moving Median with 'omitnan'
% Lw is the max window length (approx 480 mins)
Lw_max      = pad_len_2 * p.alpha + 1;

% 'Endpoints', 'shrink' reproduces the adaptive window growth at edges.
% 'omitnan' reproduces the exclusion of invalid 'b' points.
x_fa_padded = movmedian(s_padded, Lw_max, 'omitnan', 'Endpoints', 'shrink');

% 4. Remove padding
x_fa = x_fa_padded(pad_len_2+1:end-pad_len_2);

% 5. Thresholding
p_thresh = prctile(x_fa, thresh_percentile);
y2 = double(x_fa > p_thresh);

% 2.1.2.3 Morphological Filtering (Final)
% Eq (15): Window length Lp' = 2 * (Lp - 1) + 1
Lp_prime = 2 * (p.Lp - 1) + 1;

o = morphological_closing_opening(y2, Lp_prime);

% Eq (16): Heuristic rule - edges are awake (1)
o(1) = 1;
o(end) = 1;

primarySleep = o;
end

function [starts, lengths] = find_consecutive_runs(binary_vec)
% Finds start indices and lengths of consecutive 1s in a binary vector
% Detect changes
d = diff([0; binary_vec(:); 0]);
starts = find(d == 1);
ends = find(d == -1);
lengths = ends - starts;
end

function y_out = morphological_closing_opening(y_in, WinSize)
% Implements (y . WinSize) o WinSize
% Closing: Dilation followed by Erosion
% Opening: Erosion followed by Dilation
%
% In 1D binary signal:
% Erosion = moving min
% Dilation = moving max

if WinSize <= 0
    y_out = y_in;
    return;
end

% 1. Closing: (y (+) L) (-) L
% Dilation
y_dilated = movmax(y_in, WinSize);
% Erosion
y_closed = movmin(y_dilated, WinSize);

% 2. Opening: (y_closed (-) L) (+) L
% Erosion
y_eroded = movmin(y_closed, WinSize);
% Dilation
y_opened = movmax(y_eroded, WinSize);

y_out = y_opened;
end

%% used to estimate zeta, won't work as described in the paper
function zeta = estimate_zeta(s, seq_length_max, n_bootstrap, level)
% ESTIMATE_ZETA Bootstrap estimation of max valid consecutive zeros
% 
% In many cases if low activity, the estimated zeta is 1 (meaning that
% there is <0.05 chance that random sample will have that many of 2 
% consecutive zeros than observed, which is sort of meaningless
% 
% $Author:  Peng Li
% $Date:    Feb 25, 2026
% 

if nargin < 2, seq_length_max = 100; end
if nargin < 3, n_bootstrap = 1000; end
if nargin < 4, level = 0.05; end

is_zero = (s == 0);
N = length(is_zero);
p_values = zeros(seq_length_max, 1);

for n = 1:seq_length_max
    if N - n + 1 < 1, break; end
    
    % Observed proportion of n-consecutive zeros
    mov_sum = movsum(is_zero, n, 'Endpoints', 'discard');
    obs_count = sum(mov_sum == n);
    total_windows = N - n + 1;
    prop_obs = obs_count / total_windows;
    
    % Bootstrap for null distribution
    props_rand = zeros(n_bootstrap, 1);
    for b = 1:n_bootstrap
        is_zero_rand = datasample(is_zero, N);  % Shuffle equivalent
        mov_sum_rand = movsum(is_zero_rand, n, 'Endpoints', 'discard');
        rand_count = sum(mov_sum_rand == n);
        props_rand(b) = rand_count / total_windows;
    end
    
    % One-tailed p-value (obs > rand, indicating non-random clustering)
    p_values(n) = mean(props_rand >= prop_obs);
end

% Find first n where p < level (start of invalid longs runs)
idx = find(p_values < level, 1, 'first');
if isempty(idx)
    zeta = seq_length_max;  % No significance, use max
else
    zeta = max(1, idx - 1);  % Max valid is one before
end
end