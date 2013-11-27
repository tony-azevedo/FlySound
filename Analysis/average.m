function varargout = average(data,params,varargin)
% powerSpectrum(data,params,time,mode)
% proplist = getpref('AnalysisFigures','average');
% rmpref('AnalysisFigures','average');

fig = findobj('tag',mfilename); 
if isempty(fig);
    if ~ispref('AnalysisFigures') ||~ispref('AnalysisFigures',mfilename) % rmpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'tag',mfilename,...
            'Position',[584         350        1089         616],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
    p = uicontrol('parent',fig,'style','pushbutton',...
        'units','normalized','position',[.01 .92 .1 .08],...
        'string','Clear',...
        'callback',@clearaverage);
    set(p,'units','points')
end
if nargin>2
    t = varargin{1};
else
    t = makeInTime(params);
end

axID = '';
dims = [1,1];
subplotind = 1;
if nargin>5
    prot = varargin{4};
    axID = '';
    spID = [];
    for pti = 1:min(length(prot.paramsToIter),2)
        p = prot.paramsToIter{pti};
        dims(pti) = length(prot.params.(p));
        p = p(1:end-1);
        axID = [axID p num2str(prot.params.(p))];
        spID = [spID prot.params.(p)];
    end
    [~,subplotind] = intersect(prot.paramIter',spID,'rows');    
end

current = data.current(1:length(t))-mean(data.current(1:length(t)));
voltage = data.voltage(1:length(t))-mean(data.voltage(1:length(t)));

ax = findobj('tag',[mfilename 'ax' axID]);
if isempty(ax)
    ax = subplot(dims(2),dims(1),subplotind,'parent',fig,'tag',[mfilename 'ax' axID]);
end

if ~isfield(params,'mode') || sum(strcmp({'VClamp'},params.mode));
    n = get(ax,'userdata');
    line(t,current,...
        'parent',ax,'linestyle','-',...
        'color',[1 .7 .7]);
    ave = findobj(ax,'tag','line_average');
    if isempty(ave)
        line(t,current,...
            'parent',ax,'linestyle','-',...
            'color',[.7 0 0],...
            'tag','line_average');
        set(ax,'userdata',1);
    else
        set(ave,'ydata',(get(ave,'ydata')*n+current')/(n+1));
        chi = get(ax,'children');
        set(ax,'children',circshift(chi,-find(chi==ave)+1));
        set(ax,'userdata',n+1);
    end
    axis(ax,'tight')
end

if ~isfield(params,'mode') || sum(strcmp({'IClamp_fast','IClamp'},params.mode));
    n = get(ax,'userdata');
    line(t,voltage,...
        'parent',ax,'linestyle','-',...
        'color',[1 .7 .7]);
    ave = findobj(ax,'tag','line_average');
    if isempty(ave)
        line(t,voltage,...
            'parent',ax,'linestyle','-',...
            'color',[.7 0 0],...
            'tag','line_average');
        set(ax,'userdata',1);
    else
        set(ave,'ydata',(get(ave,'ydata')*n+voltage')/(n+1));
        chi = get(ax,'children');
        set(ax,'children',circshift(chi,-find(chi==ave)+1));
        set(ax,'userdata',n+1);
    end
    axis(ax,'tight')
end

varargout = {};

function clearaverage(hObject, eventdata, handles)
fig = get(hObject,'parent');
chiax = findobj(fig,'type','axes');
for ch = 1:length(chiax)
    delete(get(chiax(ch),'children'));
end