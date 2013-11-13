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
    % back button
end
if nargin>2
    exposureNum = varargin{1};
else
    exposureNum = 1;
end
d = ls('*_Image_*');
jnk = d(1,:);
pattern = ['_Image_' '\d+' '_'];
ind = regexp(jnk,pattern,'end');
jnk = jnk(ind(1)+1:end);
pattern = '\.tif';
ind = regexp(jnk,pattern);
ndigits = ind-1;

imFileStem = [data.params.protocol '_Image_' num2str(data.imageNum) '_*'];
pattern = [obj.protocol.protocolName,'_Image_'];
imnumstr = regexprep(regexp(images(im).name,[pattern '\d+'],'match'),pattern,'');
d = dir([imFileStem num2str(exposureNum) '*']);
im = Tiff(d(1).name,'r');
ax = findobj('tag',[mfilename 'ax']);
if isempty(ax)
    ax = subplot(1,1,1,'parent',fig,'tag',[mfilename 'ax'],'xscale','log','yscale','log');
else
    delete(get(ax,'children'));
end

if ~isfield(params,'mode') || sum(strcmp({'VClamp'},params.mode));
    line(f,fft(current) .*...
        conj(fft(current)),...
        'parent',ax,'linestyle','none','marker','o',...
        'markerfacecolor',[0 .5 0],'markeredgecolor',[0 .5 0],'markersize',2);
end

if ~isfield(params,'mode') || sum(strcmp({'IClamp_fast','IClamp'},params.mode));
    line(f,fft(voltage).*conj(fft(voltage)),...
        'parent',ax,'linestyle','none','marker','o',...
        'markerfacecolor',[0 0 1],'markeredgecolor',[0 0 1],'markersize',2);
end

varargout = {f};