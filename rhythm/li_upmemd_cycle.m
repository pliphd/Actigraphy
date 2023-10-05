function [imfStart, imfPeriod, imfAmplitude] = li_upmemd_cycle(comp, fs)
%LI_UPMEMD_CYCLE calculate cycle start point, period, and amplitude of each
% cycle from the component extracted using LI_UPMEMD
% 
% $Author:  Peng Li, Ph.D.
% $Date:    Mar 24, 2023
% 

% find local peaks and cycle lengths
hImf   = hilbert(comp);
phImf  = unwrap(angle(hImf));
ampImf = abs(hImf);

pos_vector = 1:length(phImf)-1;
imfStart   = pos_vector(diff(floor(phImf/(2*pi))) > 0) + 1;
imfPeriod  = diff(imfStart) ./ fs;

imfAmplitude = zeros(size(imfPeriod));
for iC = 1:numel(imfPeriod)
    imfAmplitude(iC) = mean(ampImf(imfStart(iC):imfStart(iC+1)-1));
end

% need at least three cycles to render
if numel(imfStart) >= 3
    if imfStart(1) / imfPeriod(1) < 0.25
        % remove the first cycle if the start point of the cycle <1/4 of the
        % period (to avoid edge effect)
        imfStart(1)     = [];
        imfPeriod(1)    = [];
        imfAmplitude(1) = [];
    end

    % remove those cycles with phase changes less than 2*pi and previous cycles
    pdiff = phImf(imfStart(2:end)) - phImf(imfStart(1:end-1));
    ind   = find(pdiff < 2*pi*0.99);
    ind   = [ind-1, ind];
    ind(ind <= 0) = [];

    imfStart(ind)     = [];
    imfPeriod(ind)    = [];
    imfAmplitude(ind) = [];

    % remove the start time of the last cycle (which is not complete)
    imfStart(end)=[];
else
    imfStart     = nan;
    imfPeriod    = nan;
    imfAmplitude = nan;
end