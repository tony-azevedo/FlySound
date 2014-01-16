function varargout = playImages(data,params,varargin)
% powerSpectrum(data,params,time,mode)

fig = findobj('tag',mfilename); 
if isempty(fig);
    if ~ispref('AnalysisFigures') ||~ispref('AnalysisFigures',mfilename) % rmpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'tag',mfilename,...
            'Position',[1030 547 560 420],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
    
    % forward button
    uicontrol('parent',fig,'style','pushbutton','units','normalized','position',[.9,.92,.1,.08],...
        'string','<-','tag','back','callback',@callbackfnc)
    % back button
    uicontrol('parent',fig,'style','pushbutton','units','normalized','position',[.9,.84,.1,.08],...
        'string','->','tag','forward','callback',@callbackfnc)
    % play button
    uicontrol('parent',fig,'style','togglebutton','units','normalized','position',[.9,.76,.1,.08],...
        'string','Play','tag','play','callback',@callbackfnc)
    uicontrol('parent',fig,'style','text','units','normalized','position',[.9,.68,.1,.08],...
        'tag','exposureNumText','backgroundcolor',get(fig,'color'))
    
    set(fig,'windowScrollWheelFcn',@callbackfnc)
    
else
    c = guidata(fig);
end
if nargin>2
    exposureNum = varargin{1};
else
    exposureNum = 1;
end
exposureName = constructFilnameFromExposureNum(data,exposureNum);
im = imread(exposureName);

c.data = data;
c.params = params;
c.exposureNum = exposureNum;
if ~isfield(c,'cLims')
    c.cLims = [min(min(im)) max(max(im))];
end

c.dFfig = findobj('tag','dFoverF');

ax = findobj('tag',[mfilename 'ax']);
if isempty(ax)
    ax = subplot(1,1,1,'parent',fig,'tag',[mfilename 'ax']);
else
    delete(get(ax,'children'));
end
set(findobj('string','Play','tag','play'),'userdata',ax);
h = imshow(im,c.cLims,'parent',ax,'InitialMagnification','fit');
set(findobj(fig,'tag','exposureNumText'),'string',['#' num2str(exposureNum)]);

if ~isempty(c.dFfig)
    l = findobj(c.dFfig,'tag','playImagesLine');
    delete(l)
    ax = findobj(c.dFfig,'tag','dFoverFax');
    l = get(ax,'children');
    imdir = regexprep(regexprep(regexprep(data.name,'Raw','Images'),'.mat',''),'Acquisition','Raw_Data');
    if ~strcmp(get(l,'displayname'),imdir)
        dFoverF(data,params,'No');
        l = get(ax,'children');
    end
    exp_t = get(l,'xdata');
    ex = exp_t(exposureNum);
    line([ex ex],get(ax,'ylim'),'parent',ax,'tag','playImagesLine','color',[0 1 0]);
end

guidata(fig,c);
varargout = {h};


function varargout = constructFilnameFromExposureNum(data,exposureNum)

imdir = regexprep(regexprep(regexprep(data.name,'Raw','Images'),'.mat',''),'Acquisition','Raw_Data');
d = ls(fullfile(imdir,'*_Image_*'));
jnk = d(1,:);
pattern = ['_Image_' '\d+' '_'];
ind = regexp(jnk,pattern,'end');
jnk = jnk(ind(1)+1:end);
pattern = '\.tif';
ind = regexp(jnk,pattern);
ndigits = ind-1;
numstem = repmat('0',ndigits,1)';

imFileStem = [imdir '\' data.params.protocol '_Image_*_'];

ens = num2str(exposureNum);
numstem(end-length(ens)+1:end) = ens;

d = dir([imFileStem numstem '*']);
if length(d)==0
    varargout{1} = [];
else
    
    varargout{1} = fullfile(imdir,d(1).name);
    varargout{2} = imFileStem;
end

function callbackfnc(hObject,evnt)
global playflag
playflag = 0;
c = guidata(hObject);

data = c.data;
params = c.params;
exposureNum = c.exposureNum;
cLims = c.cLims;

step = 1;
call = get(hObject,'tag');
if ~isempty(evnt) && isfield(evnt,'VerticalScrollCount')
    step = evnt.VerticalScrollAmount * 6;
    if evnt.VerticalScrollCount > 0
        call = 'forward';
    elseif evnt.VerticalScrollCount < 0
        call = 'back';
    end
end

switch call
    case 'back'
        playflag = 0;
        exposureNum = exposureNum-step;
        if exposureNum<1, exposureNum = 1; end
    case 'forward'
        playflag = 0;
        exposureNum = exposureNum+step;
        if exposureNum>sum(data.exposure), exposureNum = sum(data.exposure); end
        
    case 'play'
        ax = get(hObject,'userdata');
        movie_exposeN = exposureNum;
        playflag = 1;
        while movie_exposeN~=exposureNum-1 && playflag
            movie_exposeN = movie_exposeN+1;
            exposureName = constructFilnameFromExposureNum(data,movie_exposeN);
            if isempty(exposureName)
                movie_exposeN = 0;
                continue
            end
            im = imread(exposureName);
            cLims = [min(cLims(1),min(min(im))), max(cLims(2),max(max(im)))];
            imshow(im,[],'parent',ax,'InitialMagnification','fit');
            set(findobj('tag','exposureNumText'),'string',['#' num2str(movie_exposeN)]);
            drawnow
            pause(0.002)
        end
        c.clims = cLims;
end
playImages(data,params,exposureNum);
