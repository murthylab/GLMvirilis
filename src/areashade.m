function h = areashade(x,y1,y2,color,varargin)

h = fill([x(:)' fliplr(x(:)')],[y1(:)' fliplr(y2(:)')],color,...
        'LineStyle','none',varargin{:});