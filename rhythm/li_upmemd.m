function imf = li_upmemd(sig, fs, fd)
%LI_UPMEMD rewritten from the original upmemd
% 
% $Author:  Peng Li, Ph.D.
% $Date:    Mar 24, 2023
% 

nIMF = 2;
n    = numel(sig);
rmf  = [2.18*fd*2.^(floor(log2((0.5*fs) / (2.18*fd))):-1:0), fd];
maxn = numel(rmf);

maskAmp = std(sig, 'omitnan');
imf     = nan(n, maxn);
for iC  = 1:maxn
    allMode = zeros(n, nIMF);

    % even phase
    for iP  = 1:16
        maskSig = cos(2*pi*rmf(iC)*(0:n-1)/fs + (iP-1)*2*pi/16)';
        z = sig + maskSig*maskAmp;

        try % this goes toward the built-in emd
            allModeCand = emd(z, 'MaxNumIMF', nIMF);
        catch % this goes towards the C code
            allModeCand = emd(z', 1, 2, nIMF, 10);
        end

        allMode = allMode + allModeCand;
    end
    allMode = allMode ./ 16;
    imf(:, iC) = allMode(:, 1);

    sig = sig - allMode(:, 1);
end