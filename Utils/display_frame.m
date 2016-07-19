function display_frame(obj,event)
persistent camfig camax
if isempty(camfig)
    camfig = findobj('type','figure','tag','PGRCamFig');
    camax = findobj('type','axes','tag','PGRCamAx');
end
if isempty(camfig)
    camfig = figure(1001); clf;
    set(camfig,'position',[1120 31 560 420],'name','PGR Camera','tag','PGRCamFig')
    camax = axes('parent',camfig,'units','normalized','position',[0 0 1 1]);
    set(camax,'box','on','xtick',[],'ytick',[]);
end
sample_frame = peekdata(obj,1);
figure(camfig)
imagesc(sample_frame,'parent',camax);

drawnow; % force an update of the figure window

abstime = event.Data.AbsTime;

t = fix(abstime);

% fprintf('%s %d:%d:%d\n','timestamp', t(4),t(5),t(6))