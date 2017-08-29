%% From text files
fid = fopen('Acquire_ContRaw_161221_F1_C1_4.txt','r');
header = fscanf(fid,'%s',[1 1]);

field = fscanf(fid,'%s',[1 1]);
data.(field) = fscanf(fid,'%s',[1 1]);
%mode
field = fscanf(fid,'%s',[1 1]);
data.(field) = fscanf(fid,'%s',[1 1]);
%gain
field = fscanf(fid,'%s',[1 1]);
data.(field) = fscanf(fid,'%s',[1 1]);
%samprate
field = fscanf(fid,'%s',[1 1]);
data.(field) = fscanf(fid,'%s',[1 1]);

data.gain = str2double(data.gain);
data.samprate = str2double(data.samprate);

A = fscanf(fid,'%f\t%f',[2,inf]);

B = A';

figure(1)
subplot(2,1,1)
plot(B(1:10000,:));

%
N = 1000;

% Process A
for start_idx = 1:size(A,2)/N;
    n = N/2;
    idx = N*(start_idx-1);
    a = A(:,idx+(1:n));
    b = a(:);
    B(idx+(1:N),1) = b;

    a = A(:,idx+n+(1:n));
    b = a(:);
    B(idx+(1:N),2) = b;
end
figure(1)
subplot(2,1,2)
plot(B(1:10000,:));
title(['Mode is ' data.mode '?'])

%%
data.mode = 'IClamp';

%% Package trial and save
clear trial
trial.name = header;
trial.params = data;
switch data.mode
    case 'IClamp'
        trial.voltage = B(:,1);
        trial.current = B(:,2);
    case 'VClamp'
        trial.current = B(:,1);
        trial.voltage = B(:,2);
end
disp(trial.name)
disp(trial.params.mode)
disp(trial)
trial.name = regexprep(header,{'Acquisition','.txt'},{'Raw_Data','.mat'});

save(trial.name,'trial')