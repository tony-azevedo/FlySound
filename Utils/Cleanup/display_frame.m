function display_frame(obj,event)
persistent camfig camax
if isempty(camfig)||~camfig.isvalid
    camfig = findobj('type','figure','tag','PGRCamFig');
    camax = findobj('type','axes','tag','PGRCamAx');
end
Loc = getacqpref('AcquisitionHardware','PGRCameraLocation');
if isempty(camfig)|| isempty(camax)||~strcmp(get(camfig,'UserData'),Loc)
    camfig = figure(1001); clf;
    switch Loc
        case 'PGRCameraObjective'
            set(camfig,'position',[560 0 1280 1024],'name','PGR Camera','tag','PGRCamFig')
        case 'PGRCameraSubstage'
            set(camfig,'position',[1120 31 560 420],'name','PGR Camera','tag','PGRCamFig')
    end
    camax = axes('parent',camfig,'units','normalized','position',[0 0 1 1]);
    set(camax,'box','on','xtick',[],'ytick',[],'tag','PGRCamAx');
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