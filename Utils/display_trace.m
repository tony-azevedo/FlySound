function display_trace(obj,event)
persistent camfig camax
if isempty(camfig)||~camfig.isvalid
    camfig = findobj('type','figure','tag','PGRTraceFig');
    camax = findobj('type','axes','tag','PGRTraceAx');
end
if isempty(camfig)|| isempty(camax)
    camfig = figure(1001); clf;
    set(camfig,'position',[1120 31 560 420],'name','PGR Camera','tag','PGRTraceFig')
    camax = axes('parent',camfig,'units','normalized','position',[0 0 1 1]);
    set(camax,'box','on','xtick',[],'ytick',[],'PGRTraceAx');
    colormap(camax,'gray')
end
sample_frame = peekdata(obj,1);
figure(camfig)
imagesc(sample_frame,'parent',camax);

drawnow; % force an update of the figure window

% abstime = event.Data.AbsTime;
% 
% t = fix(abstime);
% 
% fprintf('%s %d:%d:%d\n','timestamp', t(4),t(5),t(6))