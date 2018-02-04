function yn = setacqpref(str,fields,values)

global acqprefdir

yn = ~isempty(dir([fullfile(acqprefdir,str) '.mat']));
if yn
    acqprefs = load([fullfile(acqprefdir,str) '.mat']); acqprefs = acqprefs.(str);
end
if nargin==2
    eval([str '= fields;'])
    save(fullfile(acqprefdir,str),str)
    yn = true;
    return
end
if ischar(fields)
    % main case where you're just adding a single field with a value (of
    % any type)
    acqprefs.(fields) = values;
elseif iscell(fields)
    if length(values)~= length(fields) || ~iscell(fields)
        error('Fields and values must have same number entries');
    elseif ~iscell(fields)
        error('Fields must be a cell array');
    end
    for entr = 1:length(values)
        acqprefs.(fields{entr}) = values{entr};
    end
end
    
eval([str '= acqprefs;'])
save(fullfile(acqprefdir,str),str)

yn = true;

% defaults = load(fullfile(prefdir,'AcquisitionPrefs')); defaults = defaults.defaults;
