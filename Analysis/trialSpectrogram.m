function varargout = trialSpectrogram(data,params,varargin)
% trialSpectrogram(data,params,varargin)

fig = findobj('tag',mfilename); 
if isempty(fig);
    if ~ispref('AnalysisFigures') ||~ispref('AnalysisFigures',mfilename) % rmpref('AnalysisFigures','trialSpectrogram')
        proplist = {...
            'tag',mfilename,...
            'Position',[1159 10 560 256],...
            'NumberTitle', 'off',...
            'Name', mfilename,... % 'DeleteFcn',@obj.setDisplay);
            };
        setpref('AnalysisFigures',mfilename,proplist);
    end
    proplist =  getpref('AnalysisFigures',mfilename);
    fig = figure(proplist{:});
end
[prot,d,fly,cell,trial] = extractRawIdentifiers(data.name);
set(fig,'FileName',[mfilename '_' prot '_' d '_' fly '_' cell '_' trial]);
if nargin>2
    t = varargin{1};
else
    t = makeTime(params);
    if mod(t,2)
        t = t(1:end-1);
    end
end

ax = findobj('tag',[mfilename 'ax']);
if isempty(ax)
    ax = subplot(1,1,1,'parent',fig,'tag',[mfilename 'ax'],'xscale','log','yscale','log');
else
    delete(get(ax,'children'));
end
title(ax,sprintf('%s', [prot '.' d '.' fly '.' cell '.' trial]));

f = params.sampratein/length(t)*[0:length(t)/2];

if ~isfield(params,'mode') || sum(strcmp({'VClamp'},params.mode));
    [S,F,T,P] = spectrogram(data.current,256,250,f(f<=1000),data.params.sampratein);
    colormap(pmkmp(256,'CubicL'))
    surf(T,F,10*log10(P),'edgecolor','none'); axis tight;
    %surf(T,F,(P),'edgecolor','none'); axis tight;
    % colorbar
    view(0,90);
    xlabel('Time (Seconds)'); ylabel('Hz');
end

if ~isfield(params,'mode') || sum(strcmp({'IClamp_fast','IClamp'},params.mode));
    [S,F,T,P] = spectrogram(data.voltage,256,250,f(f<=1000),data.params.sampratein);
    colormap(pmkmp(256,'CubicL'))
    surf(T,F,10*log10(P),'edgecolor','none'); axis tight;
    %surf(T,F,(P),'edgecolor','none'); axis tight;
    % colorbar
    view(0,90);
    xlabel('Time (Seconds)'); ylabel('Hz');
end

varargout = {f};