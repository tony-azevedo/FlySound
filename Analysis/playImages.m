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
    
end
if nargin>2
    exposureNum = varargin{1};
else
    exposureNum = 1;
end
exposureName = constructFilnameFromExposureNum(data,exposureNum);
im = imread(exposureName);
ax = findobj('tag',[mfilename 'ax']);
if isempty(ax)
    ax = subplot(1,1,1,'parent',fig,'tag',[mfilename 'ax']);
else
    delete(get(ax,'children'));
end
set(findobj('string','Play','tag','play'),'userdata',ax);
h = imshow(im,[],'parent',ax,'InitialMagnification','fit');
set(findobj(fig,'tag','exposureNumText'),'string',['#' num2str(exposureNum)]);
guidata(fig,{data,params,exposureNum});
varargout = {h};


function fn = constructFilnameFromExposureNum(data,exposureNum)

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
try fn = d(1).name;
catch
    error('There is no image at this exposure time: %s',[imFileStem numstem]);
end
fn = fullfile(imdir,d(1).name);

function callbackfnc(hObject,evnt)
c = guidata(hObject);

data = c{1};
params = c{2};
exposureNum = c{3};

call = get(hObject,'tag');
switch call
    case 'back'
        exposureNum = exposureNum-1;
        if exposureNum<1, exposureNum = 1; end
    case 'forward'
        exposureNum = exposureNum+1;
        if exposureNum>sum(data.exposure), exposureNum = sum(data.exposure); end
    case 'play'
        ax = get(hObject,'userdata');
        movie_exposeN = exposureNum;
        while movie_exposeN~=exposureNum-1
            movie_exposeN = movie_exposeN+1;
            try exposureName = constructFilnameFromExposureNum(data,movie_exposeN);
            catch e
                if isempty(strfind(e.message,'There is no image at this exposure'))
                    error(e)
                end
                movie_exposeN = 0;
                exposureName = constructFilnameFromExposureNum(data,movie_exposeN);
            end
            im = imread(exposureName);
            imshow(im,[],'parent',ax,'InitialMagnification','fit');
            set(findobj('tag','exposureNumText'),'string',['#' num2str(movie_exposeN)]);
            drawnow
            pause(0.002)
        end
end
playImages(data,params,exposureNum);
