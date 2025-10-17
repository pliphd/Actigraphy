% Accelerometer data preview
% 
% Descriptions tba
% 
%   $Author:  Peng Li, Ph.D.
%   $Date:    Oct 16, 2025
% 
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%                      (C) Peng Li 2019 -
% +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% 
classdef AccPreview < handle
    properties (Access = private)
        % main interface
        PreviewTable
    end
    
    properties (Access = public)
        % data related
        colNames
    end
    
    properties (Access = public)
        PreviewFigure
    end
    
    methods (Access = public)
        function app = AccPreview(previewFile, varargin)
            createComponents(app);

            % update name
            [~, fname, fext] = fileparts(previewFile);
            app.PreviewFigure.Name = app.PreviewFigure.Name + ": " + fname + fext;
            
            % digest first line -- header
            fid    = fopen(previewFile);
            lin1st = fgetl(fid) ;
            con1st = split(lin1st, ',')';
            nCols  = numel(con1st);

            app.colNames = matlab.lang.makeValidName(con1st);

            previewData  = table('Size', [0, nCols], 'VariableNames', app.colNames, 'VariableTypes', repmat({'string'}, 1, nCols));

            app.PreviewTable.Data = previewData;

            % propogate data
            rowCnt = 1;
            nPre   = 1e3;
            while ~feof(fid)
                if rowCnt > nPre
                    break;
                end
                nextl   = fgetl(fid) ;
                nextCon = split(nextl, ',')';
                app.PreviewTable.Data{rowCnt, :} = nextCon;
                rowCnt = rowCnt + 1 ;
            end
            fclose(fid);
        end
    end
    
    methods (Access = private)
        function createComponents(app)
            % center window
            pos = CenterFig(1/2, 1/2, 'normalized');
            
            app.PreviewFigure = uifigure('Color', 'w', ...
                'Units', 'normalized', 'Position', pos, 'Resize', 'on', ...
                'Name', 'Accelerometer Data Preview', ...
                'NumberTitle', 'off');
            
            gFigure = uigridlayout(app.PreviewFigure);
            gFigure.RowHeight   = repmat({'1x'}, 1, 10);
            gFigure.ColumnWidth = repmat({'1x'}, 1, 7);
            
            app.PreviewTable    = uitable(gFigure);
            app.PreviewTable.Layout.Row    = [1 10];
            app.PreviewTable.Layout.Column = [1 7];
        end
    end
end