%% Process a directory of data, putting data into params

% go to folder of interest
%% 
a = dir('*_Params_*');
b = dir('*_Raw_*');

for i = 1:length(a)
    p = load(a(i).name);
    raw = load(b(i).name);

    raw.params = p.data;
    fn = fieldnames(raw);
    savestr = ['save(name'];
    for f = 1:length(fn)
        eval([fn{f} '=raw.(fn{f});'])
        savestr = [savestr ',''' fn{f} ''''];
    end
    savestr = [savestr ');'];
    eval(savestr)
end