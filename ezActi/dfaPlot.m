classdef dfaPlot < actigraphy
    properties (Access = public)
        dfaAxis
        dfaShallowAxis
    end
    
    %% construction and deletion
    methods (Access = public)
        function app = dfaPlot(varargin)
            app@actigraphy(varargin{:});
            
            % change position
            pos = CenterFig(1/3, 2/3, 'norm');
            app.actigraphyFig.Position = pos;
            app.actigraphyFig.Name     = 'Detrended fluctuation function';
            set([app.actiAxis app.shallowAxis], 'Position', [.07 .8 .86 .15]);
            
            app.actigraphyFig.Tag      = 'dfaPlotFig';
            
            % add new feature
            app.dfaAxis = axes(app.actigraphyFig, 'Units', 'normalized', 'Position', [.07 .1 .86 .55],  'ActivePositionProperty', 'position', ...
                'Box', 'off', 'TickDir', 'out', 'FontSize', app.actiAxis.FontSize);
            app.dfaShallowAxis = axes(app.actigraphyFig, 'Units', 'normalized', 'Position', app.dfaAxis.Position,  'ActivePositionProperty', 'position', ...
                'Box', 'off', 'TickDir', 'out', 'FontSize', app.actiAxis.FontSize, 'YColor', 'none', 'XAxisLocation', 'top', 'Color', 'none');
        end
    end
end