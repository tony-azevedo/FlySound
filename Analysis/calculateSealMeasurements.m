function varargout = calculateSealMeasurements(data,params,varargin)
% powerSpectrum(data,params,time,mode)

if ~isfield(params,'mode') || ~sum(strcmp({'VClamp'},params.mode));
    varargout = {};
    return
end

fig = findobj('tag',mfilename); 
if isempty(fig);
    if ~ispref('AnalysisFigures') ||~ispref('AnalysisFigures',mfilename)
        proplist = {...
            'tag',mfilename,...
            'Position',[570 2 560 256],...
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

y = data.current(:,1);
stimpnts = params.stepdur*params.samprateout;
y = reshape(y,2*stimpnts,params.pulses);

base = mean(mean(y(round(3/2*stimpnts):end,:),2));

y_bar = mean(y,2) - base;

% R = V/I(at end of step);
sealRes_Est1 = params.stepamp/1000 / (y_bar(stimpnts)*1e-12);

start = t(10);
finit = t(stimpnts); %s
pulse_t = t(t>start & t<finit);
% TODO: handle the warnings
Icoeff = nlinfit(...
    pulse_t - pulse_t(1),...
    y_bar(t>start & t<finit),...
    @exponential,...
    [max(y_bar)/3,max(y_bar),params.stepdur]);
RCcoeff = Icoeff; RCcoeff(1:2) = params.stepamp/1000 ./(RCcoeff(1:2)*1e-12); % 5 mV step/I_i or I_f

sealRes_Est2 = RCcoeff(1);

str = sprintf('R (ohms): \n\test 1 (step end) = %.2e; \n\test 2 (exp fit) = %.2e;',...
    sealRes_Est1,...
    sealRes_Est2);

ax = findobj(fig,'type','axes','-not','tag','legend');
if isempty(ax)
    ax = subplot(1,1,1,'parent',fig,'tag',[mfilename 'ax']);
else
    delete(get(ax,'children'));
end

plot(t(t>=0 & t< params.stepdur*2),y,'parent',ax,'color',[1 .7 .7],'linewidth',1); hold on
line(t(t>=0 & t< params.stepdur*2),y_bar+base,'parent',ax,'color',[.7 0 0],'linewidth',1);
l = line(t(t>start & t<finit),...
    exponential(Icoeff,pulse_t-pulse_t(1))+base,...
    'parent',ax,...
    'color',[0 1 1],'linewidth',1,'displayname',str);
legend(l,str);box off; set(gca,'TickDir','out');

ylabel(ax,'pA'); %xlim([0 max(t)]);
xlabel(ax,'Time (s)'); xlim(ax,[t(1) params.stepdur*2]);

varargout = {RCcoeff,sealRes_Est1,};

% function displayTrial(obj)
%     figure(1);
%     redlines = findobj(1,'Color',[1, 0, 0]);
%     set(redlines,'color',[1 .8 .8]);
%     bluelines = findobj(1,'Color',[0, 0, 1]);
%     set(bluelines,'color',[.8 .8 1]);
%     greylines = findobj(1,'Color',[.6 .6 .6]);
%     set(greylines,'color',[.8 .8 .8]);
%     pinklines = findobj(1,'Color',[.5 1 1]);
%     set(pinklines,'color',[.8 .8 .8]);
%

%     msgbox(str);
% end