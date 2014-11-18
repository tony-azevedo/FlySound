%% Construction of Command to feed to Voltage Command protocol

%%
Fs = 50000;
x = 0:Fs-1/Fs;
y = zeros(size(x));
for start = 0:2:8;
    y(start*Fs/10+1:(start+1)*Fs/10) = 1;
end

plot(x,y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['Basic','.wav'],...
    y,...
    Fs,...
    'BitsPerSample',32);

%%
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs/2-1)/Fs;
y = zeros(size(x));

y(x<.2) = 88;
y(x>=.2 & x <.3) = 88 - (255/.1)*(x(x>=.2 & x <.3)-.2);
y(x>=.3) = 20;


plot(x,y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['NonInvasiveVmRamp','.wav'],...
    y,...
    Fs,...
    'BitsPerSample',32);
