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

% df = log10(800)/256;
% f = df:df:log10(800);
% f = 10.^f;

df = 800/256;
f = df:df:800;

if ~isfield(params,'mode') || sum(strcmp({'VClamp'},params.mode));
    [S,F,T,P] = spectrogram(data.current-mean(data.current),2048,1024,f,data.params.sampratein);
end
if ~isfield(params,'mode') || sum(strcmp({'IClamp_fast','IClamp'},params.mode));
    [S,F,T,P] = spectrogram(data.voltage-mean(data.voltage),1024,512,f,data.params.sampratein);
end

P(P< mean(P(end,:))) = mean(P(end,:));
if isfield(params,'preDurInSec')
    T = T-params.preDurInSec;
end
colormap(ax,'Hot') % 'Hot'
surf(ax,T, F, 10*log10(P),'edgecolor','none');
%set(ax, 'YScale', 'log');
view(ax,0,90);
axis(ax,'tight');

xlabel(ax,'Time (Seconds)'); ylabel(ax,'Hz');
title(ax,sprintf('%s', [prot '.' d '.' fly '.' cell '.' trial]));

varargout = {S,F,T,P,fig};