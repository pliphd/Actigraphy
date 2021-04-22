function gapSeries = gap2Series(gap, length)
%GAP2SERIES convert gaps to series representation
% 
% E.g.
%       For a signal of length 10
%       gap was defined from 3 to 6 (gap = [3 6])
%       then, GapSeries = [1 1 0 0 0 0 1 1 1 1];
% 
% $Author:  Peng Li
%           Division of Sleep Medicine
%           Brigham and Women's Hospital, Harvard Medical School
% $Date:    Feb 28, 2017
% $Modif.:  Dec 02, 2020
%               relocation
% 

gapSeries = ones(length, 1);

for iS = 1:size(gap, 1)
    gapSeries(gap(iS, 1):gap(iS, 2)) = 0;
end