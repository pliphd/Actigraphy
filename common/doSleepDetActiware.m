function sleepSeries = doSleepDetActiware(data, epoch, T)
%DOSLEEPDETACTIWARE detect sleep episode in actigraphy DATAINMIN
% 
% REF.: [1] Actiwatch Software Manual p. 76-77
% 
%       auto threshold is currently not available as the instruction in
%       Actiwatch Software Manual is not clear enough
% 
% $Author:  Peng Li
% $Date:    Jan 04, 2024
% 

% define weights
switch epoch
    case 15
        w = [1/25 1/25 1/25 1/25 1/5 1/5 1/5 1/5 4 1/5 1/5 1/5 1/5 1/25 1/25 1/25 1/25];
    case 30
        w = [1/25 1/25 1/5 1/5 2 1/5 1/5 1/25 1/25];
    case 60
        w = [1/25 1/5 1 1/5 1/25];
    case 120
        w = [0.12 1/2 0.12];
    otherwise
        return;
end

% calculate "total activity counts" based on Actiware definition
% which is essentially a process of convolution
s = conv(data, w, 'same');

sleepSeries = s <= T;