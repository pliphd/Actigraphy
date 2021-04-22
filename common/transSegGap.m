function MatNew = transSegGap(MatOld, Length)
%TRANSSEGGAP Transform a matrix of segment/gap to a matrix of gap/segment
% 
%   Length specifies the total points of the corresponding signal
% 
% $Author:  Peng Li, Ph.D.
%           MBP, Div Sleep Med, BWH &HMS
% $Date:    May 4, 2016
% $Modif.:  Feb 28, 2017
%               add option for empty MatOld
%           Apr 22, 2021
%               add option for empty MatNew
% 

if ~isempty(MatOld)
    temp = MatOld';
    temp = temp(:);
    if temp(1) == 1
        temp(1) = [];
        Shift1  = 1;
    else
        temp    = [1; temp];
        Shift1  = 0;
    end
    if temp(end) == Length
        temp(end) = [];
        Shiftend  = 1;
    else
        temp      = [temp; Length];
        Shiftend  = 0;
    end
    MatNew  = reshape(temp, 2, [])';
    
    % shift one point
    MatNew(:, 1)   = MatNew(:, 1)   + 1;
    MatNew(:, end) = MatNew(:, end) - 1;
    
    if ~isempty(MatNew)
        if MatNew(1) == 2 && Shift1 == 0
            MatNew(1) = 1;
        end
        if MatNew(end) == Length - 1 && Shiftend == 0
            MatNew(end) = Length;
        end
    end
else
    MatNew = [1 Length];
end