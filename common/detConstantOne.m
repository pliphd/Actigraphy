function seg = detConstantOne(Signal)
%DETCONSTANTONE Detect constant number 1 from 0-1 series.
% For isolated 1, the start and end indices are the same (the location of
% 1)
% 
% $Author:  Peng Li, Ph.D.
%           MBP, Div Sleep Med, BWH &HMS
% $Date:    Nov 14, 2016
% $Modif.:  Dec 02, 2020
%               relocation
% 

incl = Signal == 1;
incT = diff([0; incl; 0]);
stId = find(incT == 1);
edId = find(incT == -1) - 1;
seg  = [stId(:) edId(:)];