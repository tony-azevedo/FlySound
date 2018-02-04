function yn = isacqpref(str)

global acqprefdir

yn = ~isempty(dir([fullfile(acqprefdir,str) '.mat']));