function SegSeries = seg2Series(seg, length)
%SEG2SERIES convert segments to series representation
% 
% E.g.
%       For a signal of length 10
%       seg was defined from 3 to 6 (seg = [3 6])
%       then, SegSeries = [0 0 1 1 1 1 0 0 0 0];
% 
% $Author:  Peng Li
%           Division of Sleep Medicine
%           Brigham and Women's Hospital, Harvard Medical School
% $Date:    Feb 28, 2017
% $Modif.:  Dec 02, 2020
%               relocation
% 

SegSeries = zeros(length, 1);

for iS = 1:size(seg, 1)
    SegSeries(seg(iS, 1):seg(iS, 2)) = 1;
end