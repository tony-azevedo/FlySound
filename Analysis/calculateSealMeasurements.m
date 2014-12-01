function varargout = calculateSealMeasurements(data,params,varargin)
% calculateSealMeasurements(data,params,varargin)

if ~isfield(params,'mode') || ~sum(strcmp({'VClamp'},params.mode));
    varargout = {};
    return
end

fig = findobj('tag',mfilename); 
if isempty(fig);
    if ~ispref('AnalysisFigures') ||~ispref('AnalysisFigures',mfilename) %rmpref('AnalysisFigures','calculateSealMeasurements')
        proplist = {...
            'tag',mfilename,...
            'Position',[9    10   560   256],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@setDisplay);
            };
        setpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
end
if nargin>2
    t = varargin{1};
else
    t = makeTime(params);
    if mod(t,2)
        t = t(1:end-1);
    end
end
if nargin>3
    data.name = varargin{2};
end
if nargin>4
    data.tags = varargin{3};
end

[prot,d,fly,cell,trial,D] = extractRawIdentifiers(data.name);
set(fig,'FileName',[mfilename '_' prot '_' d '_' fly '_' cell '_' trial]);

y = data.current(:,1);
stimpnts = params.stepdur*params.samprateout;
y = reshape(y,2*stimpnts,params.pulses);

base = mean(mean(y(round(3/2*stimpnts):end,:),2));

y_bar = mean(y,2) - base;

% R = V/I(at end of step);
sealRes_Est1 = params.stepamp/1000 / (mean(y_bar(stimpnts-100:stimpnts))*1e-12);
accessRes_Est1 = params.stepamp/1000 / (max(y_bar)*1e-12);

str = sprintf('R input (ohms) = %.2e; \nR access (ohms) = %.2e;',...
    sealRes_Est1,...
    accessRes_Est1);

ax = findobj(fig,'type','axes','-not','tag','legend');
if isempty(ax)
    ax = subplot(1,1,1,'parent',fig,'tag',[mfilename 'ax']);
else
    delete(get(ax,'children'));
end

plot(t(t>=0 & t< params.stepdur*2),y,'parent',ax,'color',[1 .7 .7],'linewidth',1); hold on
l = line(t(t>=0 & t< params.stepdur*2),y_bar+base,'parent',ax,'color',[.7 0 0],'linewidth',1,'displayname',str);
text(t(stimpnts+5),mean(y_bar(stimpnts-100:stimpnts))+base + max(y_bar)/2,...
    str,'parent',ax,...
    'fontsize',10);
box off; set(gca,'TickDir','out');

ylabel(ax,'pA'); %xlim([0 max(t)]);
xlabel(ax,'Time (s)'); xlim(ax,[t(1) params.stepdur*2]);
title(ax,sprintf('%s %s\\}', [prot ' ' d ' ' fly ' ' cell ' ' trial], sprintf('\\{%s;',data.tags{:})));

[protocol,dateID,flynum,cellnum,trialnum] = extractRawIdentifiers(data.name);
set(fig,'name',[protocol '_' dateID '_' flynum '_' cellnum '_' trialnum '_' mfilename])

varargout = {sealRes_Est1,accessRes_Est1,fig};
