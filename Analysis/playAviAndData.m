function varargout = playAviAndData(data,params,varargin)

if ~isfield(data,'exposure')
    fprintf(1,'No Camera Input: Exiting dFoverF routine\n');
    return
end

fig = findobj('tag',mfilename);
if isempty(fig);
    if ~ispref('AnalysisFigures') ||~ispref('AnalysisFigures',mfilename) % rmpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'tag',mfilename,...
            'Position',[640 300 640 512+100],...
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
    c.dEfield = uicontrol('parent',fig,'style','edit','units','pixels','position',[96,1,40,18],...
        'tag','playbackspeed','backgroundcolor',[1 1 1],'string',1,'callback',@changeDE);
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


switch data.params.mode; case 'VClamp', invec = 'current'; case 'IClamp', invec = 'voltage'; otherwise invec = 'voltage'; end   
t = makeInTime(data.params);

% frame_times is when the exposures happen in time
if data.exposure(1) == 0
    data.exposure(1) = 1;
    data.exposure(find(data.exposure,1,'last')) = 0;
end
c.exptimes = find(data.exposure);

global mov3 mov x y v dE dT
dE = 20;
dT = abs(x(c.exptimes(dE))-x(c.exptimes(1)));

% voltage trace vs time
x = t(1:c.exptimes(end));
v = data.(invec)(1:c.exptimes(end));
y = nan(size(x));

c.dispax = axes('parent',fig,'units','pixels','position',[0 100 640 512]);
c.traceax = axes('parent',fig,'units','pixels','position',[0 37 640 64]);
set(c.dispax,'box','off','xtick',[],'ytick',[],'tag','dispax','color',[0 0 0]);
colormap(c.dispax,'gray')

figure(fig); 
moviename = getMoviePath(data.name);
c.vid = VideoReader(moviename);

Nframes = c.vid.Duration*c.vid.FrameRate;
c.frametimes = (0:Nframes-1)*1/c.vid.FrameRate;

t = makeInTime(data.params);
fps = 1/mean(diff(t(data.exposure)));
c.speedfield.UserData = fps;

set(c.slider,'max',Nframes,'sliderstep',[1/Nframes,10/Nframes],'userdata',c.frametimes);
set(c.dEfield,'string',num2str(dE));

c.vid.CurrentTime = 0;
mov3 = c.vid.readFrame;
mov = mov3(:,:,1);

set(findobj('string','Play','tag','play'),'userdata',c.dispax);
c.h = imshow(mov,'parent',c.dispax,'InitialMagnification',0.50);

y(1:c.exptimes(c.slider.Value)) = v(1:c.exptimes(c.slider.Value));
c.voltage = plot(c.traceax,x,y,'color',[1 0 0],'userdata',v);
c.voltage.YDataSource = 'y';

set(c.traceax,'box','off','xtick',[],'ytick',[],'tag','traceax','ylim',[min(v) max(v)],'xlim',[t(1) t(c.exptimes(end))],'color',[0 0 0]);

c.fpstext = uicontrol('parent',fig,'style','text','units','pixels','position',[6,512+72,80,24],...
    'tag','fps','backgroundcolor','none','string',sprintf('%.1f Hz',fps),'fontsize',12,'ForegroundColor',[1 0 0]);


drawnow
guidata(fig,c);
playbackspeed(fig,[]);

varargout = {c.h};


function gotomovietime(hObject,evnt)
global mov3 mov x y v dE dT

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

y(c.exptimes(max([1 c.slider.Value-dE])):c.exptimes(c.slider.Value)) = v(c.exptimes(max([1 c.slider.Value-dE])):c.exptimes(c.slider.Value));
y(c.exptimes(c.slider.Value):end) = nan;
y(1:c.exptimes(max([1 c.slider.Value-dE]))) = nan;
refreshdata(c.voltage,'caller');
c.traceax.XLim = [x(c.exptimes(c.slider.Value))-dT x(c.exptimes(c.slider.Value))];

drawnow
guidata(hObject,c);


function playcallback(hObject,evnt)
global mov3 x y v dE dT
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

    y(c.exptimes(max([1 c.slider.Value-dE])):c.exptimes(c.slider.Value)) = v(c.exptimes(max([1 c.slider.Value-dE])):c.exptimes(c.slider.Value));
    y(c.exptimes(c.slider.Value):end) = nan;
    y(1:c.exptimes(max([1 c.slider.Value-dE]))) = nan;
    refreshdata(c.voltage,'caller');
    c.traceax.XLim = [x(c.exptimes(c.slider.Value))-dT x(c.exptimes(c.slider.Value))];
    
    drawnow

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


function changeDE(hObject,evnt)
global dE dT x
c = guidata(hObject);

dE = str2double(c.dEfield.String);
dT = abs(x(c.exptimes(dE))-x(c.exptimes(1)));
c.traceax.XLim = [x(c.exptimes(c.slider.Value))-dT x(c.exptimes(c.slider.Value))];
drawnow

guidata(hObject,c);




