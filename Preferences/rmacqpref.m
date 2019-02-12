function yn = rmacqpref(str,varargin)

global acqprefdir
if isempty(acqprefdir)
    startup
end

yn = ~isempty(dir([fullfile(acqprefdir,str) '.mat']));
if yn
    prefs = load(fullfile(acqprefdir,str)); prefs = prefs.(str);
    if nargin==1
        delete([fullfile(acqprefdir,str) '.mat']);
        fprintf(1,'%s acq prefs removed\n',str);
    elseif nargin==2
        prefs = rmfield(prefs,varargin{1});
        eval([str '= prefs;'])
        save(fullfile(acqprefdir,str),str)
        fprintf('%s is removed from %s\n',varargin{1},str);
    else
        [prefs,pref2rm] = rmacqsubpref(prefs,varargin{:});
    end
else
    error('Acquisition Preference %s doesn''t exist',str);
end


function pref2rm = rmacqsubpref(prefs,varargin)
pref2rm = (varargin{1});
error('Work on removing deeper layers of network');
if nargin==2
    pref2rm = (varargin{1});
    return
end
if isstruct(prefs.(varargin{1}))
    pref2rm = rmacqsubpref(prefs.(varargin{1}),varargin{2:end});
else
    prefs = [];
end

