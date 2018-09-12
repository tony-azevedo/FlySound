function prefs = getacqpref(str,varargin)

global acqprefdir
if isempty(acqprefdir)
    startup
end

if nargin==0
    fprintf('Acquisition preferences:\n')
    a = ls(acqprefdir);
    for d = 3:size(a,1)
        fprintf('\t%s\n',a(d,:))
    end
    return
end

yn = ~isempty(dir([fullfile(acqprefdir,str) '.mat']));
if ~yn
    prefs = [];
    return
else
    prefs = load(fullfile(acqprefdir,str)); prefs = prefs.(str);
    if nargin>1
        prefs = getacqsubpref(prefs,varargin{:});
    end
end

function prefs = getacqsubpref(prefs,varargin)
if nargin==2
    prefs = prefs.(varargin{1});
    return
end
if isstruct(prefs.(varargin{1}))
    prefs = getacqsubpref(prefs,varargin{2:end});
else
    prefs = [];
end


