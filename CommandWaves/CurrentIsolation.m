stimname = 'SineResponse35Hz0_5V';

150505_F1_C1
150505_F1_C3
150505_F1_C5 % Crazy cell, not good

150505_F2_C1 

150507_F1_C1
150509_F2_C1

150509_F2_C2 % possibly, small responses

150512_F1_C1 % Spiker, for sure
150512_F2_C1 % Most likely a spiker.
150512_F2_C2
150512_F2_C3 

%% Another Spiking neuron

celltype = 'BPH';

trials = {
'C:\Users\Anthony Azevedo\Raw_Data\150602\150602_F2_C1\PiezoSine_Raw_150602_F2_C1_22.mat'; % 25 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150602\150602_F2_C1\PiezoSine_Raw_150602_F2_C1_58.mat'; % 35Hz
'C:\Users\Anthony Azevedo\Raw_Data\150602\150602_F2_C1\PiezoSine_Raw_150602_F2_C1_24.mat'; % 50Hz
'C:\Users\Anthony Azevedo\Raw_Data\150602\150602_F2_C1\PiezoSine_Raw_150602_F2_C1_60.mat'; % 70Hz
'C:\Users\Anthony Azevedo\Raw_Data\150602\150602_F2_C1\PiezoSine_Raw_150602_F2_C1_26.mat'; % 100Hz
'C:\Users\Anthony Azevedo\Raw_Data\150602\150602_F2_C1\PiezoSine_Raw_150602_F2_C1_62.mat'; % 140Hz
'C:\Users\Anthony Azevedo\Raw_Data\150602\150602_F2_C1\PiezoSine_Raw_150602_F2_C1_28.mat'; % 200Hz
'C:\Users\Anthony Azevedo\Raw_Data\150602\150602_F2_C1\PiezoSine_Raw_150602_F2_C1_64.mat'; % 282 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150602\150602_F2_C1\PiezoSine_Raw_150602_F2_C1_30.mat'; % 400 Hz
};



%% Possible non-spiker in FruGal4

celltype = 'BPL';

trials = {
'C:\Users\Anthony Azevedo\Raw_Data\150512\150512_F2_C2\PiezoSine_Raw_150512_F2_C2_2.mat'; %35 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150512\150512_F2_C2\PiezoSine_Raw_150512_F2_C2_4.mat'; %50 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150512\150512_F2_C2\PiezoSine_Raw_150512_F2_C2_6.mat'; %70 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150512\150512_F2_C2\PiezoSine_Raw_150512_F2_C2_8.mat'; %100 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150512\150512_F2_C2\PiezoSine_Raw_150512_F2_C2_10.mat'; %141 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150512\150512_F2_C2\PiezoSine_Raw_150512_F2_C2_12.mat'; %200 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150512\150512_F2_C2\PiezoSine_Raw_150512_F2_C2_14.mat'; %282 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150512\150512_F2_C2\PiezoSine_Raw_150512_F2_C2_16.mat'; %400 Hz
}


%%
foldX = 2;
for t_ind = 1:length(trials)
trial = load(trials{t_ind});
fig = figure;
a = PiezoSineAverage(fig,getShowFuncInputsFromTrial(trial),'');

trace = findobj(fig,'color',[.7 0 0]);

x = get(trace,'xdata');
dT = 1/trial.params.sampratein;
y_0 = get(trace,'ydata');
y = y_0;

bl = mean(y(x<0));
y = y-bl;
y(x<=0) = 0;
y(x>0&x<=0.005+dT/2) = (dT:dT:0.005)/.005.* (y(x>0&x<=0.005+dT/2));

y(x>trial.params.stimDurInSec) = 0;
y(x>=trial.params.stimDurInSec-0.005 & x<=trial.params.stimDurInSec) = (0.005:-dT:dT)/0.005.* (y(x>=trial.params.stimDurInSec-0.005 & x<=trial.params.stimDurInSec));

y = smooth(y,20);

figure(fig);
ax = subplot(3,1,3);
cla(ax);
plot(x,y_0-bl,'color',[0 1 0]);hold on
plot(x,y,'color',[0 0 1]);
axis(ax,'tight');
xlim([-.1 .2]);


freqnumber = num2str(round(trial.params.freq));
while length(freqnumber)<3
    freqnumber = ['0' freqnumber];
end

audiowrite(...
    ['C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\SineResponse_' ...
    celltype '_'...
    freqnumber 'Hz_' ...
    regexprep(num2str(trial.params.displacement),'\.','_') 'V_1X.wav'],...
    y(x>0&x<trial.params.stimDurInSec),trial.params.sampratein,'Bitspersample',32)

audiowrite(...
    ['C:\Users\Anthony Azevedo\Code\FlySound\CommandWaves\SineResponse_' ...
    celltype '_'...
    freqnumber 'Hz_' ...
    regexprep(num2str(trial.params.displacement),'\.','_') 'V_' num2str(foldX) 'X.wav'],...
    foldX*y(x>0&x<trial.params.stimDurInSec),trial.params.sampratein,'Bitspersample',32)


end

%% Legit Spiking neuron in FruGal4

celltype = 'BPH';

trials = {
'C:\Users\Anthony Azevedo\Raw_Data\150531\150531_F1_C1\PiezoSine_Raw_150531_F1_C1_3.mat'; %17 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150531\150531_F1_C1\PiezoSine_Raw_150531_F1_C1_6.mat'; %25 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150531\150531_F1_C1\PiezoSine_Raw_150531_F1_C1_9.mat'; %35 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150531\150531_F1_C1\PiezoSine_Raw_150531_F1_C1_12.mat'; %50 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150531\150531_F1_C1\PiezoSine_Raw_150531_F1_C1_15.mat'; %70 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150531\150531_F1_C1\PiezoSine_Raw_150531_F1_C1_18.mat'; %100 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150531\150531_F1_C1\PiezoSine_Raw_150531_F1_C1_21.mat'; %141 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150531\150531_F1_C1\PiezoSine_Raw_150531_F1_C1_24.mat'; %200 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150531\150531_F1_C1\PiezoSine_Raw_150531_F1_C1_27.mat'; %282 Hz
'C:\Users\Anthony Azevedo\Raw_Data\150531\150531_F1_C1\PiezoSine_Raw_150531_F1_C1_30.mat'; %400 Hz
};


%% Beautiful spiker 150513_F2_C1 % Spiker, for sure, but a lot of 60Hz noise

celltype = 'BPH';

trials = {
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_3.mat';
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_6.mat';
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_9.mat';
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_12.mat';
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_15.mat';
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_18.mat';
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_21.mat';
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_24.mat';
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_27.mat';
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_30.mat';
'C:\Users\Anthony Azevedo\Raw_Data\150513\150513_F2_C1\PiezoSine_Raw_150513_F2_C1_33.mat';
}
