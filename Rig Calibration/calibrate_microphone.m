function calibrate_microphone(mic_number,exp_number,freq,stimdur,voltage,gain_BK,gain_KE1,gain_KE2,numreps)

% voltage_set = [4 3 3 2 1 .5 .5];  suggested voltages for each frequency
% freq_vector = [70 100 200 300 700 1000 1500];  suggested frequencies that will be tested

% make a directory if one does not exist
if ~isdir(['C:\Users\Anthony Azevedo\Acquisition\',date,'\',date,'_Mic',...
        num2str(mic_number),'_E',num2str(exp_number)])
    mkdir(['C:\Users\Anthony Azevedo\Acquisition\',date,'\',date,'_Mic',...
        num2str(mic_number),'_E',num2str(exp_number)]);
end

%% access data structure and count trials

% check whether a saved data file exists with today's date
D = dir(['C:\Users\Anthony Azevedo\Acquisition\',date,'\',date,...
    '_Mic',num2str(mic_number),'_E',num2str(exp_number),'\Calibration Parameters_',...
    date,'_Mic',num2str(mic_number),'_E',num2str(exp_number),'.mat']);
if isempty(D)  
    % if no saved data exists then this is the first trial
    n=1;
    disp(n);
else
    %load current data file
    load(['C:\Users\Anthony Azevedo\Acquisition\',date,'\',date,'_Mic',num2str(mic_number),...
    '_E',num2str(exp_number),'\Calibration Parameters_',date,'_Mic',num2str(mic_number),...
    '_E',num2str(exp_number),'.mat']','data');
    n = length(data)+1;
    disp(n);
end

% save trial parameters
data(n).date = date;
data(n).mic_number = mic_number;
data(n).exp_number = exp_number;
data(n).fs_out = 45000;   % sound output sampling rate 
data(n).fs_in = 2^14;   % microphone input sampling rate (a power of 2 for FFT)
data(n).voltage = voltage;
data(n).stimdur = stimdur;
data(n).freq = freq;
data(n).gain_BK = gain_BK;
data(n).gain_KE1 = gain_KE1;
data(n).gain_KE2 = gain_KE2;
data(n).stimonsamp = floor(.5*data(n).fs_out)+1;
data(n).stimoffsamp = floor(.5*data(n).fs_out)+(data(n).stimdur*data(n).fs_out);
data(n).nsampout = data(n).stimoffsamp+data(n).stimonsamp;
data(n).nsampin = ceil(data(n).nsampout/data(n).fs_out*data(n).fs_in);
if data(n).freq>=300
    data(n).speaker = '6-inch mid-range driver';  % 6-inch mid-range speaker used for higher frequencies
else
    data(n).speaker = 'subwoofer';  % subwoofer used for lower frequencies
end

data(n).trial = n;

% create stimulus
[stimtrain] = generateTone(data(n).freq,data(n).fs_out,data(n).stimdur,0);
stimtrain = stimtrain*data(n).voltage; % scale to desired output intensity
if size(stimtrain,1)==1  % ensure that stimtrain is a column vector
    stimtrain=stimtrain';
end

% acquire data
for rep = 1:numreps
    disp(rep)
    [BK_voltage KE1_voltage KE2_voltage stim] = acquireMicData(data(n),stimtrain,rep);
end

% save data
save(['C:\Users\Anthony Azevedo\Acquisition\',data(n).date,'\',...
    data(n).date,'_Mic',num2str(data(n).mic_number),'_E',...
    num2str(data(n).exp_number),'\Calibration Parameters_', ...
    data(n).date,'_Mic',num2str(data(n).mic_number),'_E',...
    num2str(data(n).exp_number)],'data');

% plot raw microphone signal
plotMicData(data(n));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% function [BK_voltage KE_voltage stim] = acquireMicData(data,stimtrain)
function [BK_voltage KE1_voltage KE2_voltage stim] = acquireMicData(data,stimtrain,rep)

aiSession = daq.createSession('ni');                            % AI = analoginput ('nidaq', 'Dev1');

chs = aiSession.addAnalogInputChannel('Dev1',[0 1 2], 'Voltage');        % addchannel (AI, 0:1);
chs(1).Name = 'BK';
chs(2).Name = 'KE1';
chs(3).Name = 'KE2';
aiSession.Rate = data.fs_in;                % set(AI, 'SampleRate', data(n).fs_in);
%aiSession.NumberOfScans = length(stimtrain);     % set(AI, 'SamplesPerTrigger', inf);
% set(AI, 'InputType', 'Differential');
% set(AI, 'TriggerType', 'Manual');
% set(AI, 'ManualTriggerHwOn','Trigger');

aoSession = daq.createSession('ni');                            % AO = analogoutput ('nidaq', 'Dev1');
chs = aoSession.addAnalogOutputChannel('Dev1',[1], 'Voltage');        % addchannel (AO, 1);
aoSession.Rate = data.fs_out;                % set(AO, 'SampleRate', fs_out); set(AO, 'TriggerType', 'Manual');

aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');

ch1out = [stimtrain];
aoSession.wait;
aoSession.queueOutputData(ch1out);  % putdata(AO,[ch1out]);
aiSession.NumberOfScans = round(length(ch1out)/data.fs_out*data.fs_in);                % set(AI, 'SampleRate', data(n).fs_in);

aoSession.startBackground; % Start the session that receives start trigger first
in = aiSession.startForeground; % both amp and signal monitor input

% % wait for playback/recording to finish
% nsampin = AI.SamplesAcquired;
% nsampout = AO.SamplesOutput;
% while (nsampin<data(n).nsampin)
%     nsampin = AI.SamplesAcquired;
%     nsampout = AO.SamplesOutput;
% end;

% stop playback
% stop([AI AO]);

% record difference in AI/AO start times
% data(n).trigdiff = AO.InitialTriggerTime-AI.InitialTriggerTime;

% read data from engine
% x = getdata(AI,data(n).nsampin);
BK_voltage=in(:,1); % BK mic should be plugged into ACH0
KE1_voltage=in(:,2); % KE mic should be plugged into ACH1
KE2_voltage=in(:,3); % KE mic should be plugged into ACH1
stim = stimtrain;

% save rep
save(['C:\Users\Anthony Azevedo\Acquisition\',data.date,'\',...
    data.date,'_Mic',num2str(data.mic_number),'_E',...
    num2str(data.exp_number),'\RawMicCal_', ...
    data.date,'_Mic',num2str(data.mic_number),'_E',...
    num2str(data.exp_number),'_',num2str(data.trial),'_Rep',num2str(rep)],'BK_voltage',...
    'KE1_voltage','KE2_voltage','stim');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% function [stim_vector] = generateTone(freq, samprate, dur, dr) 
function [stim_vector] = generateTone(freq, samprate, dur, dr) 

%[stim_vector] = generateTone(freq, samprate, dur, dr)
%
%Function generates a single tone of user-determined frequency, output
%sample rate, and duration.  
%
%Inputs:
%   freq = stimulus frequency (in Hz)
%   samprate = output sample rate of stimulus (in Hz)
%   dur = duration of tone (in seconds)
%   dr = duration of ramp (set to 0 for default, which is dur/10)
%
%Outputs:
%   stim_vector = stimulus vector

sf = samprate;   % sample frequency (Hz)
stim_vector = zeros(1, (dur * sf));

%Make cos theta ramped pure tones at 160Hz and 320Hz

% 100Hz 1s tone
cf = freq;                  % carrier frequency (Hz)              
d = dur;                    % duration (s)
n = sf * d;                 % number of samples
t = (0:n-1) / sf;             % sound data preparation
s100 = sin(2 * pi * cf * t);   % sinusoidal modulation
s101 = sin(2 * pi * (cf+8) * t);   % sinusoidal modulation

% prepare ramp
if dr==0
    dr = d / 10;
end
nr = floor(sf * dr);
r = sin(linspace(0, pi/2, nr));
r = [r, ones(1, n - nr * 2), fliplr(r)];

% make ramped sound
s100 = s100 .* r;
%s100 = (s100 + s101) .* r;


%add tones to stimulus vector
stim_vector = s100;
%stim_vector(100: (99 + length(s100))) = s100 * .6;
%wavwrite(stimulus_vector,sf,'200HzTone.wav');

%save output values
stim_freq = freq;
stim_samprate = samprate;
stim_dur = dur;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%function plotMicData(BK_voltage,KE_voltage,data,n)
function plotMicData(data)

figure(1); clf
rawfiles = dir(['C:\Users\Anthony Azevedo\Acquisition\',data.date,'\',...
    data.date,'_Mic',num2str(data.mic_number),'_E',...
    num2str(data.exp_number),'\RawMicCal_*',num2str(data.trial),'_Rep*']);

reps = length(rawfiles);

load(['C:\Users\Anthony Azevedo\Acquisition\',data.date,'\',...
    data.date,'_Mic',num2str(data.mic_number),'_E',...
    num2str(data.exp_number),'\',rawfiles(1).name]);

BK_voltagetraces = nan(length(BK_voltage),reps);
KE1_voltagetraces = nan(length(KE1_voltage),reps);
KE2_voltagetraces = nan(length(KE1_voltage),reps);
for r = 1:reps
    load(['C:\Users\Anthony Azevedo\Acquisition\',data.date,'\',...
        data.date,'_Mic',num2str(data.mic_number),'_E',...
        num2str(data.exp_number),'\',rawfiles(r).name]);
    BK_voltagetraces(:,r) = BK_voltage;
    KE1_voltagetraces(:,r) = KE1_voltage;
    KE2_voltagetraces(:,r) = KE2_voltage;
end
t_in = ((1:1:length(BK_voltage))-1)/data.fs_in;
t_out = ((1:1:length(stim))-1)/data.fs_out;
subplot(5,1,1); 
    plot(t_in,BK_voltagetraces,'color',[1 .7 .7],'linewidth',1); 
    hold on
    plot(t_in,mean(BK_voltagetraces,2),'color',[.7 0 0],'linewidth',1); 
%    xlim([t_in(1) t_in(end)]); set(gca,'TickDir','out'); box off;
    xlim([.1 .2]); set(gca,'TickDir','out'); box off;
    ylabel('BK Mic Output (V)');
subplot(5,1,2); 
    plot(t_in,KE1_voltagetraces,'color',[ .7 .7  1],'linewidth',1); 
    hold on
    plot(t_in,mean(KE1_voltagetraces,2),'color',[0 0 .7],'linewidth',1); 
%    xlim([t_in(1) t_in(end)]); set(gca,'TickDir','out'); box off;
    xlim([.1 .2]); set(gca,'TickDir','out'); box off;
    ylabel('KE Mic Output (V)');
subplot(5,1,3); 
    plot(t_in,KE1_voltagetraces,'color',[ .7 .7  1],'linewidth',1); 
    hold on
    plot(t_in,mean(KE1_voltagetraces,2),'color',[0 0 .7],'linewidth',1); 
    xlim([t_in(1) t_in(end)]); set(gca,'TickDir','out'); box off;
%    xlim([.1 .2]); set(gca,'TickDir','out'); box off;
    ylabel('KE Mic Output (V)');
subplot(5,1,4); 
    plot(t_in,mean(BK_voltagetraces,2),'r','linewidth',1); 
    hold on; 
    plot(t_in,mean(KE1_voltagetraces,2),'bo','linewidth',1); 
    plot(t_in,mean(KE2_voltagetraces,2),'b+','linewidth',1); 
    legend('BK_voltage','KE1_voltage','KE2_voltage');
    set(gca,'TickDir','out'); box off;
    ylabel('Microphone Output (V)');
subplot(5,1,5); 
    plot(t_out,stim,'c','linewidth',2); 
%    xlim([t_out(1) t_out(end)]); set(gca,'TickDir','out'); box off;
    xlim([.1 .2]); set(gca,'TickDir','out'); box off;
    ylabel('Stim (V)'); xlabel('Time (seconds)');


