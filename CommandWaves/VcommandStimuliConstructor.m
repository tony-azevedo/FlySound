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


%% VoltageRamp_m100_p20 
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs/2)/Fs;
y = (20+100)/(x(end)-x(1))*x - 100;

x = x(1:end-1);
y = y(1:end-1);

plot(x,y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['VoltageRamp_m100_p20','.wav'],...
    y,...
    Fs,...
    'BitsPerSample',32);

%% VoltageRamp_m100_p20_1s 
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs-1)/Fs;
y = (20+100)*x - 100;

plot(x,y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['VoltageRamp_m100_p20_1s','.wav'],...
    y,...
    Fs,...
    'BitsPerSample',32);

%% VoltageRamp_m70_p20 
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs/2)/Fs;
y = (20+70)/(x(end)-x(1))*x - 70;

x = x(1:end-1);
y = y(1:end-1);

plot(x,y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['VoltageRamp_m70_p20','.wav'],...
    y,...
    Fs,...
    'BitsPerSample',32);

%% VoltageRamp_m70_p20_1s
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs)/Fs;
y = (20+70)/(x(end)-x(1))*x - 70;

x = x(1:end-1);
y = y(1:end-1);

plot(x,y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['VoltageRamp_m70_p20_1s','.wav'],...
    y,...
    Fs,...
    'BitsPerSample',32);


%% VoltageRamp_m70_p20 
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs/2)/Fs;
y = (20+70)/(x(end)-x(1))*x - 70;

x = x(1:end-1);
y = [-70 * ones(size(x)) y(1:end-1)];

plot(y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['VoltageRamp_m70_p20','.wav'],...
    y,...
    Fs,...
    'BitsPerSample',32);



%% VoltageRamp_m70_p20_1s
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs)/Fs;
y = (20+70)/(x(end)-x(1))*x - 70;

x = x(1:end-1);
y = [-70 * ones(size(x)) y(1:end-1)];

plot(y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['VoltageRamp_m70_p20_1s','.wav'],...
    y,...
    Fs,...
    'BitsPerSample',32);


%% VoltageRamp_m60_p40 
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs/2)/Fs;
y = (40+60)/(x(end)-x(1))*x - 60;

x = x(1:end-1);
y = [-60 * ones(size(x)) y(1:end-1)];

plot(y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['VoltageRamp_m60_p40','.wav'],...
    y,...
    Fs,...
    'BitsPerSample',32);



%% VoltageRamp_m60_p40_h_1s
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs)/Fs;
y = (40+60)/(x(end)-x(1))*x - 60;

x = x(1:end-1);
y = [-60 * ones(size(x)) y(1:end-1) 40 * ones(size(x))];

plot(y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['VoltageRamp_m60_p40_h_1s','.wav'],...
    y,...
    Fs,...
    'BitsPerSample',32);

%% VoltageRamp_m60_p40_h_0_5s
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs/2)/Fs;
y = (40+60)/(x(end)-x(1))*x - 60;

x = x(1:end-1);
y = [-60 * ones(size(x)) y(1:end-1) 40 * ones(size(x))];

x = [x x+Fs/2/Fs x+2*Fs/2/Fs];
plot(x,y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['VoltageRamp_m60_p40_h_0_5s','.wav'],...
   y,...
   Fs,...
   'BitsPerSample',32);


%% VoltageRamp_m50_p12_h_0_5s
close all

cd 'C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\'

Fs = 50000;
x = (0:Fs/2)/Fs;
y = (12+50)/(x(end)-x(1))*x - 50;

x = x(1:end-1);
y = [-50 * ones(size(x)) y(1:end-1) 12 * ones(size(x))];

x = [x x+Fs/2/Fs x+2*Fs/2/Fs];
plot(x,y);

cd C:\Users\Anthony' Azevedo'\Code\FlySound\CommandWaves\

audiowrite(['VoltageRamp_m50_p12_h_0_5s','.wav'],...
   y,...
   Fs,...
   'BitsPerSample',32);

