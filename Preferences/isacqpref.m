function yn = isacqpref(str,varargin)

global acqprefdir

yn = ~isempty(dir([fullfile(acqprefdir,str) '.mat']));

if nargin>1 && yn
    prefs = getacqpref(str,varargin{:});
    if isempty(prefs)
        yn = 0;
    end
end