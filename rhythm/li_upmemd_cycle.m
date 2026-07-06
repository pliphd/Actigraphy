function [imfStart, imfPeriod, imfAmplitude, imfNadir] = li_upmemd_cycle(comp, fs)
%LI_UPMEMD_CYCLE calculate cycle start point, period, and amplitude of each
% cycle from the component extracted using LI_UPMEMD
% 
% $Author:  Peng Li, Ph.D.
% $Date:    Mar 24, 2023
% $Modif.:  Jul 06, 2026
%               Allow nadir output (phase = pi)
%               Evaluate incomplete cycle based on whether nadir or peak
%                   are true inflection points
% 

% find local peaks and cycle lengths
hImf   = hilbert(comp);
phImf  = unwrap(angle(hImf));
ampImf = abs(hImf);

pos_vector = 1:length(phImf)-1;
imfStart   = pos_vector(diff(floor(phImf        / (2*pi))) > 0) + 1;
imfNadir   = pos_vector(diff(floor((phImf - pi) / (2*pi))) > 0) + 1;

imfPeriodTemp = diff(imfStart) ./ fs;

% need at least three cycles to render
if numel(imfStart) >= 3 || numel(imfNadir) >= 3
    halfWin = round(mean(imfPeriodTemp) * fs / 4);   % ≈ quarter-period in samples

    % --- Leading-edge check -------------------------------------------
    % The earlier of {imfStart(1), imfNadir_raw(1)} is the boundary-artifact
    % candidate; the one that arrives second is safe (a full cycle precedes it).
    if ~isempty(imfNadir) && imfNadir(1) < imfStart(1)
        % Nadir arrives first — evaluate it; peak is safe
        if ~isLocalMin(comp, imfNadir(1), halfWin)
            imfNadir(1) = [];
        end
    else
        % Peak arrives first — evaluate it
        if ~isLocalMax(comp, imfStart(1), halfWin)
            imfStart(1) = [];
        end
    end

    % --- Trailing-edge check ------------------------------------------
    % The later of {imfStart(end), imfNadir_raw(end)} is the boundary-artifact
    % candidate (e.g. a phase crossing at the rising signal tail).
    if isempty(imfNadir) || imfStart(end) > imfNadir(end)
        % Peak arrives last — evaluate it
        if ~isLocalMax(comp, imfStart(end), halfWin)
            imfStart(end) = [];
        end
    else
        % Nadir arrives last — evaluate it; peaks are safe
        if ~isLocalMin(comp, imfNadir(end), halfWin)
            imfNadir(end) = [];
        end
    end

    % remove those cycles with phase changes less than 2*pi and previous cycles
    pdiff = phImf(imfStart(2:end)) - phImf(imfStart(1:end-1));
    ind   = find(pdiff < 2*pi*0.99);
    ind   = unique([ind-1, ind]);
    ind(ind <= 0) = [];
    imfStart(ind)     = [];

    pdiff = phImf(imfNadir(2:end)) - phImf(imfNadir(1:end-1));
    ind   = find(pdiff < 2*pi*0.99);
    ind   = unique([ind-1, ind]);
    ind(ind <= 0) = [];
    imfNadir(ind)     = [];

    if isempty(imfStart) || isempty(imfNadir)
        imfStart = nan; imfNadir = nan; imfPeriod = nan; imfAmplitude = nan;
        return
    end

    if imfStart(1) > imfNadir(1)
        imfPeriod = diff(imfStart) ./ fs;
        imfAmplitude = zeros(size(imfPeriod));
        for iC = 1:numel(imfPeriod)
            imfAmplitude(iC) = mean(ampImf(imfStart(iC):imfStart(iC+1)-1));
        end
    else
        imfPeriod = diff(imfNadir) ./ fs;
        imfAmplitude = zeros(size(imfPeriod));
        for iC = 1:numel(imfPeriod)
            imfAmplitude(iC) = mean(ampImf(imfNadir(iC):imfNadir(iC+1)-1));
        end
    end
else
    imfStart     = nan;
    imfNadir     = nan;
    imfPeriod    = nan;
    imfAmplitude = nan;
end
end

function tf = isLocalMax(sig, idx, halfWin)
% A genuine peak has the signal rising before it and falling after it.
% Use halfWin/2 (≈ period/8) so the slope window stays within one half-cycle.
nearWin = max(2, round(halfWin / 2));
lo = max(1, idx - nearWin);
hi = min(length(sig), idx + nearWin);
% Need at least one sample on each side; if idx is at a boundary, reject
if lo >= idx || idx >= hi
    tf = false; return
end
tf = mean(diff(sig(lo:idx))) > 0 ...   % rising approach
    && mean(diff(sig(idx:hi))) < 0;       % falling departure
end

function tf = isLocalMin(sig, idx, halfWin)
nearWin = max(2, round(halfWin / 2));
lo = max(1, idx - nearWin);
hi = min(length(sig), idx + nearWin);
if lo >= idx || idx >= hi
    tf = false; return
end
tf = mean(diff(sig(lo:idx))) < 0 ...   % falling approach
    && mean(diff(sig(idx:hi))) > 0;       % rising departure
end