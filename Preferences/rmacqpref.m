function yn = rmacqpref(str)

global acqprefdir

yn = ~isempty(dir([fullfile(acqprefdir,str) '.mat']));
if yn
    delete([fullfile(acqprefdir,str) '.mat']);
    fprintf(1,'%s acq prefs removed\n',str);
else
    error('Acquisition Preference %s doesn''t exist',str);
end
