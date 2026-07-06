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

imfPeriod    = diff(imfStart) ./ fs;
imfAmplitude = zeros(size(imfPeriod));
for iC = 1:numel(imfPeriod)
    imfAmplitude(iC) = mean(ampImf(imfStart(iC):imfStart(iC+1)-1));
end

% need at least three cycles to render
if numel(imfStart) >= 3
    halfWin = round(mean(imfPeriod) * fs / 4);   % ≈ quarter-period in samples

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
            imfStart(1)     = [];
            imfPeriod(1)    = [];
            imfAmplitude(1) = [];
        end
    end

    % --- Trailing-edge check ------------------------------------------
    % The later of {imfStart(end), imfNadir_raw(end)} is the boundary-artifact
    % candidate (e.g. a phase crossing at the rising signal tail).
    if ~isempty(imfNadir) && numel(imfStart) >= 2
        if imfStart(end) > imfNadir(end)
            % Peak arrives last — evaluate it
            if ~isLocalMax(comp, imfStart(end), halfWin)
                imfStart(end)     = [];
                imfPeriod(end)    = [];
                imfAmplitude(end) = [];
            end
        else
            % Nadir arrives last — evaluate it; peaks are safe
            if ~isLocalMin(comp, imfNadir(end), halfWin)
                imfNadir(end) = [];
            end
        end
    end

    % remove those cycles with phase changes less than 2*pi and previous cycles
    pdiff = phImf(imfStart(2:end)) - phImf(imfStart(1:end-1));
    ind   = find(pdiff < 2*pi*0.99);
    ind   = [ind-1, ind];
    ind(ind <= 0) = [];

    imfStart(ind)     = [];
    imfNadir(ind)     = [];
    imfPeriod(ind)    = [];
    imfAmplitude(ind) = [];
else
    imfStart     = nan;
    imfNadir     = nan;
    imfPeriod    = nan;
    imfAmplitude = nan;
end
end

function tf = isLocalMax(sig, idx, halfWin)
% True when the maximum of sig in [idx±halfWin] lies within halfWin/2 of idx.
lo = max(1, idx - halfWin);
hi = min(length(sig), idx + halfWin);
[~, k] = max(sig(lo:hi));
tf = abs((lo + k - 1) - idx) <= max(1, round(halfWin / 2));
end

function tf = isLocalMin(sig, idx, halfWin)
lo = max(1, idx - halfWin);
hi = min(length(sig), idx + halfWin);
[~, k] = min(sig(lo:hi));
tf = abs((lo + k - 1) - idx) <= max(1, round(halfWin / 2));
end