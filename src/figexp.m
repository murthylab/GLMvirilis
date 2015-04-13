function figexp(fileName,width,height,varargin)
%   export matlab figure as png and pdf
%   figexp(fileName,width,height)
%
%ARGS
%   fileName    - filename the fig to export to (WITHOUT extension)
%   width       - width of exported picture, RELATIVE to paper size
%   height      - height, RELATIVE to papersize

%created 06/11/13 Jan

h_fig = copyobj(gcf,0);
set(h_fig,'Visible','off','WindowStyle','normal');

allaxes   = findall(h_fig,'type','axes');
%alltext   = findall(h_fig,'type','text');
%allfont   = [alltext;allaxes];

%set( allfont,'FontUnits','points','FontName','Helvetica-Narrow','FontSize',9);
set( allaxes,'FontUnits','points','FontSize',10,'FontName','Helvetica');
set(h_fig,'Renderer','painters')

set(h_fig,'PaperUnits','centimeters');
papersize=get(h_fig,'PaperSize');
width=width*papersize(1) ;      % empty width stays empty this way
height=height*papersize(2);      % idem

set(h_fig,'PaperPositionMode','manual');
set(h_fig,'PaperPosition',[0 0 width height]);

if nargin>3 && varargin{1}==0
   save_fig(fileName, 'png');
else
   save_fig(fileName, 'pdf');
end
delete(h_fig)
clear h_fig