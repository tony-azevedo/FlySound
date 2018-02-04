function varargout = powerSpectrum(data,params,varargin)
% powerSpectrum(data,params,time,mode)

fig = findobj('tag',mfilename); 
if isempty(fig);
    if ~isacqpref('AnalysisFigures') ||~isacqpref('AnalysisFigures',mfilename) % rmacqpref('AnalysisFigures','powerSpectrum')
        proplist = {...
            'tag',mfilename,...
            'Position',[584    10   560   256],...
            'color',[1 1 1],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setacqpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getacqpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
end
[prot,d,fly,cell,trial] = extractRawIdentifiers(data.name);
set(fig,'Name',[d '_' fly '_' cell '_' prot '_' mfilename '_'  trial]);
if nargin>2
    t = varargin{1};
else
    t = makeInTime(params);
    if mod(t,2)
        t = t(1:end-1);
    end
end

f = params.sampratein/length(t)*[0:length(t)/2];
f = [f, fliplr(f(2:end-1))];

current = data.current(1:length(f))-mean(data.current(1:length(f)));
voltage = data.voltage(1:length(f))-mean(data.voltage(1:length(f)));

ax = findobj('tag',[mfilename 'ax']);
if isempty(ax)
    ax = subplot(1,1,1,'parent',fig,'tag',[mfilename 'ax'],'xscale','log','yscale','log');
else
    delete(get(ax,'children'));
end

if ~isfield(params,'mode') || sum(strcmp({'VClamp'},params.mode));
    current = current-mean(current,1);
    AveragePower_or_Variance = sum(current.^2)/(length(current));%*diff(t(1:2)));
    PSD = real(fft(current) .* conj(fft(current)));
    PSD = PSD/sum(PSD);
    PSD = PSD/diff(f(2:3));
    PSD_Ave_Power = sum(PSD)/(length(current));%*diff(f(1:2)));
    
    line(f,PSD,...
        'parent',ax,'linestyle','none','marker','.',...
        'markerfacecolor',[.3 1 .3],'markeredgecolor',[.3 1 .3],'markersize',2);
    ylabel(ax,'pA^2 s');
    xlabel(ax,'Hz');
    xlim(ax,[.1,3000]);

    [Pxx,f] = pwelch(current,params.sampratein,[],[],params.sampratein);
    hold(ax,'on')
    loglog(ax,f,Pxx/diff(f(1:2)),'color',[0 .5 0])
end

if ~isfield(params,'mode') || sum(strcmp({'IClamp_fast','IClamp'},params.mode));
    AveragePower_or_Variance = sum(voltage.^2)/(length(voltage));%*diff(t(1:2)));
    PSD = real(fft(voltage) .* conj(fft(voltage)))/length(voltage);
    PSD_Ave_Power = sum(PSD)/(length(voltage));%*diff(f(1:2)));

    line(f,PSD,...
        'parent',ax,'linestyle','none','marker','o',...
        'markerfacecolor',[0 0 1],'markeredgecolor',[0 0 1],'markersize',2);
    ylabel(ax,'V^2 s');
    xlabel(ax,'Hz');
end


varargout = {f};