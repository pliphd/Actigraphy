function accOut = calibAcc(accIn, para)
%CALIDACC calibrate accelerometer data based on input parameters
% 
% INPUTS
%   ACCIN:              3-D accelerometer data, unit g, N by 3 matrix
%   PARA:               Parameters for calibration
%                           2 by 3 matrix
%                           ---------------
%                           offset_i
%                           scale_i
% 
%                           i = x, y, z
% 
% OUTPUTS
%   ACCOUT:             3-D accelerometer data, unit g, N by 3 matrix
% 
% $Author:  Peng Li, Ph.D.
% $Date:    Mar 14, 2025
% 

accOut = para(1, :) + para(2, :) .* accIn;