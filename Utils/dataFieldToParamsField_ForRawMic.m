%% Process a directory of data, putting data into params

% go to folder of interest
%% 
a = dir('*Parameters*');
data = load(a.name);
data = data.data;

b = dir('RawMic*');
stem = b(1).name;
stem = regexprep(stem,'_\d+_','_%d_');
repstem = stem(1:regexp(stem,'_Rep\d+'));

for i = 1:length(data)
    rawreps = dir([sprintf(repstem,data(i).trial), '*']);
    for rr = 1:length(rawreps)
        disp(rawreps(rr).name);
        raw = load(rawreps(rr).name);        
        raw.params = data(i);
        raw.name = rawreps(rr).name(1:regexp(rawreps(rr).name,'\.mat')-1);
        save(rawreps(rr).name,'-struct','raw')
    end
end