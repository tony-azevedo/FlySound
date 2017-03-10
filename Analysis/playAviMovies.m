function varargout = playAviMovies(data,params,varargin)

if ~isfield(data,'exposure')
    fprintf(1,'No Camera Input: Exiting dFoverF routine\n');
    return
end

fig = findobj('tag',mfilename);
if isempty(fig);
    if ~ispref('AnalysisFigures') ||~ispref('AnalysisFigures',mfilename) % rmpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'tag',mfilename,...
            'Position',[640 300 640 512+30],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
    
    % slider
    c.slider = uicontrol('parent',fig,'Style', 'slider','units','pixels','position',[6,19,628,12],...
        'Min',1,'Max',10,'Value',1,...
        'tag','slider','Callback', @gotomovietime);
    % play button
    c.playbutton = uicontrol('parent',fig,'style','togglebutton','units','pixels','position',[6,1,40,18],...
        'string','Play','tag','play','callback',@playcallback);
    c.speedfield = uicontrol('parent',fig,'style','edit','units','pixels','position',[48,1,40,18],...
        'tag','playbackspeed','backgroundcolor',[1 1 1],'string',1,'callback',@playbackspeed);
    
    %     set(fig,'windowScrollWheelFcn',@gotomovietime)
    
    guidata(fig,c);
else
    c = guidata(fig);
end

if ~any(data.exposure)
    uicontrol('parent',fig,'style','text','units','pixels','position',[260,256,80,48],...
        'tag','exposureNumText','backgroundcolor',get(fig,'color'),'string','Exposure input is empty')
    warning('Exposure input is empty');
    return
end

c.dispax = axes('parent',fig,'units','pixels','position',[0 36 641 513]);
set(c.dispax,'box','off','xtick',[],'ytick',[],'tag','dispax');
colormap(c.dispax,'gray')

figure(fig); 
moviename = getMoviePath(data.name);
c.vid = VideoReader(moviename);

Nframes = c.vid.Duration*c.vid.FrameRate;
c.frametimes = (0:Nframes-1)*1/c.vid.FrameRate;

t = makeInTime(data.params);
exptimes = t(data.exposure);
fps = 1/mean(diff(exptimes));
c.speedfield.UserData = fps;

set(c.slider,'max',Nframes,'sliderstep',[1/Nframes,10/Nframes],'userdata',c.frametimes);

c.vid.CurrentTime = 0;
global mov3
mov3 = c.vid.readFrame;
global mov
mov = mov3(:,:,1);

set(findobj('string','Play','tag','play'),'userdata',c.dispax);
c.h = imshow(mov,'parent',c.dispax,'InitialMagnification',0.50);

drawnow
guidata(fig,c);
playbackspeed(fig,[]);

varargout = {c.h};


function gotomovietime(hObject,evnt)
global mov3 mov

c = guidata(hObject);
c.slider.Value = round(c.slider.Value);

if ~isempty(evnt) && isfield(evnt,'VerticalScrollCount')
    step = evnt.VerticalScrollAmount * 6;
    if evnt.VerticalScrollCount > 0
        call = 'forward';
    elseif evnt.VerticalScrollCount < 0
        call = 'back';
    end
end

c.vid.CurrentTime = c.frametimes(c.slider.Value);
mov3 = c.vid.readFrame;
mov = mov3(:,:,1);
c.h.CData = mov;
drawnow
guidata(hObject,c);


function playcallback(hObject,evnt)
global mov3 
% persistent c startframe
% if isempty(c)
c = guidata(hObject);
% end
DT = 1/c.speedfield.Value;
c.slider.Value = round(c.slider.Value);
startframe = c.slider.Value;
if startframe == c.slider.Max
    c.slider.Value = 1;
end
while c.playbutton.Value
    tic
    if c.slider.Value >= c.slider.Max
        c.playbutton.Value = 0;
        break
    end
    c.vid.CurrentTime = c.frametimes(c.slider.Value);
    mov3 = c.vid.readFrame;
    c.h.CData = mov3(:,:,1);
    c.slider.Value = c.slider.Value+1;
    t_ = toc;
    if DT-t_>0;
        pause(DT-t_);
    end
end    
if ~(c.playbutton.Value)
    c.slider.Value = startframe;
end
% c = [];



function playbackspeed(hObject,evnt)
c = guidata(hObject);

c.speedfield.Value = c.speedfield.UserData*str2double(c.speedfield.String);
guidata(hObject,c);




