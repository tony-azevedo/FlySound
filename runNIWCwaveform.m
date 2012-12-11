function data = runNIWCwaveform(expnumber,odor,concentration,aircond,stimloc)
% data = runNIWCwaveform(expnumber,odor,concentration,aircond,stimloc)
%
% run whole cell trial with arbitrary stimulus pulse waveform
% expnumber = experiment (fly or cell) number
% odor = odor name (string)
% concentration = concentration (number)
% aircond = air conditions (string)
% stimloc = name of stimulus .mat file with  variables 'stim' and 'samprate'
%        'stim' should be a train of ones and zeros
%        'samprate' should be a single number with the sample rate in Hz
%
%   ch0 is odor (0-5V)
%
% Raw data sampled at 10kHz and saved as separate waveforms for each trial
%


% make a directory if one does not exist
if ~isdir(date)
    mkdir(date);
end

%% load stimulus and check stimulus values
load(['stimuli/',stimloc],'stim','samprate');
if ~isempty(find(stim(find(stim))~=1))
    fprintf('bad stimulus value\n');
    return;
end
stim = stim';  % make sure stim is a column vector

% % recharge odor vial if stim contains more than 500msec of odor
% if length(find(stim))/samprate*1000>500
%     DIOrecharge(find(stim))/samprate+1);
% end

%DIOrecharge(10);

%% access data structure and count trials
% check whether a saved data file exists with today's date
D = dir([date,'/WCwaveform_',date,'_E',num2str(expnumber),'.mat'])
if isempty(D)  
    % if no saved data exists then this is the first trial
    n=1
else
    %load current data file
    load([date,'/WCwaveform_',date,'_E',num2str(expnumber),'.mat']','data');
    n = length(data)+1   
end



%% assign default values of input parameters
if nargin < 5, igortoggle = 0; end

%% set trial parameters

% experiment information
data(n).date = date;                   % experiment date
data(n).expnumber = expnumber;         % experiment number
data(n).trial = n;                     % trial number
data(n).odorname = odor;               % odor name
data(n).conc = concentration;          % odor concentration
data(n).aircond = aircond;             % air conditions
data(n).stimname = stimloc;            % stimulus name/location
data(n).sampratein = 10000;            % input sample rate 
data(n).samprateout = samprate;        % output sample rate
data(n).stimdur = length(stim);        % stimulus duration (samples)
data(n).stimonset = 4;                 % time before odor on (seconds)
data(n).stimpost = 4;                  % time after stim offset (seconds)
data(n).currentscale = 200;            % scaling factor for picoamps
data(n).currentoffset = 0; %0.3828;        % offset for current
data(n).voltagescale = 5; %20;             % scaling factor for millivolts extra (intra)
data(n).voltageoffset = 0;             % offset for voltage

% timing calculations
data(n).stimonsamp = floor(data(n).stimonset*data(n).samprateout)+1;
data(n).stimoffsamp = floor(data(n).stimonset*data(n).samprateout)+length(stim);
data(n).nsampout = data(n).stimoffsamp+floor(data(n).stimpost*data(n).samprateout);
data(n).nsampin = ceil(data(n).nsampout/data(n).samprateout*data(n).sampratein);

% command signals
data(n).odor = zeros(data(n).nsampout,1); data(n).odor(data(n).stimonsamp:data(n).stimoffsamp) = 5*stim;    %odor pulse
data(n).Iin = zeros(data(n).nsampout,1); data(n).Iin(round(0.1*data(n).samprateout):round(0.5*data(n).samprateout)) = -1;
% pulse = [2*ones(100,1);zeros(400,1)]; q = length(data(n).Iin)-data(n).samprateout;
% data(n).Iin(data(n).samprateout+1:end)= repmat(pulse,q/500,1);
%data(n).Iin = zeros(data(n).nsampout,1); %data(n).Iin(1) = 5;

% data
data(n).trigdiff = 0;                           % time between input and output triggers
data(n).Ihold = 0;
data(n).Vrest = 0;
data(n).Rin = 0;


%% reset aquisition engines
daqreset;

%% configure analog input
AI = analoginput ('nidaq', 'Dev1');
addchannel (AI, 2:3);
set(AI, 'SampleRate', data(n).sampratein);
set(AI, 'SamplesPerTrigger', inf);
set(AI, 'InputType', 'Differential');
set(AI, 'TriggerType', 'Manual'); 
set(AI, 'ManualTriggerHwOn','Trigger');

%% configure analog output
AO = analogoutput ('nidaq', 'Dev1');
addchannel (AO, 0:1);
set(AO, 'SampleRate', data(n).samprateout);
set(AO, 'TriggerType', 'Manual');

%% create and load stimulus (zero-pad by 100 samples)
ch0out = [data(n).Iin;zeros(100,1)];
ch1out = [data(n).odor;zeros(100,1)];
putdata(AO,[ch0out, ch1out]);

%% run trial
% start playback
start([AI AO]);
trigger([AI AO]);

% wait for playback/recording to finish
nsampin = AI.SamplesAcquired
nsampout = AO.SamplesOutput
while (nsampin<data(n).nsampin)
    nsampin = AI.SamplesAcquired
    nsampout = AO.SamplesOutput
end; 

% stop playback
stop([AI AO]);

%% collect and analyse data(n)
% record difference in AI/AO start times
data(n).trigdiff = AO.InitialTriggerTime-AI.InitialTriggerTime;

% read data from engine
x = getdata(AI,data(n).nsampin); 
current=x(:,1)*data(n).currentscale-data(n).currentoffset; 
voltage=x(:,2)*data(n).voltagescale-data(n).voltageoffset; 
odor = repmat(data(n).odor',data(n).sampratein/data(n).samprateout,1); odor = odor(:);

% calculate Ihold, Vrest, Rin
hpulseon = floor(data(n).sampratein*0.15);
hpulseoff = floor(data(n).sampratein*0.5);
data(n).Ihold = mean(current(data(n).sampratein:data(n).sampratein*data(n).stimonset));
data(n).Vrest = mean(voltage(data(n).sampratein:data(n).sampratein*data(n).stimonset));
Ipulse = data(n).Ihold-mean(current(hpulseon:hpulseoff));
Vpulse =  data(n).Vrest-mean(voltage(hpulseon:hpulseoff));
data(n).Rin = Vpulse/Ipulse;

%% save data(n)
save([date,'/WCwaveform_' data(n).date,'_E',num2str(expnumber)],'data');
save([date,'/Raw_WCwaveform_' data(n).date,'_E',num2str(expnumber),'_',num2str(n)],'current','voltage','odor');

%% delete AI/AO objects
delete([AI AO]);
clear AI AO;

%% plot results
    figure(1);
    set(gcf,'Position',[49 465 1025  470]);
    set(gcf,'PaperPositionMode','auto');
    t=[1:data(n).nsampin]'/data(n).sampratein;
    
    subplot(2,1,1); hold off; plot(t,voltage,'r','lineWidth',1); ylabel('V_m (mV)');
        set(gca,'Xlim',[0 max(t)]);
        %set(gca,'Ylim',[-60 -20]);
        box off; set(gca,'TickDir','out');
    subplot(4,1,3); hold off; plot(t,current,'g'); ylabel('I (pA)');
        set(gca,'Xlim',[0 max(t)]);
        box off; set(gca,'TickDir','out');
    subplot(4,1,4); hold off; plot(t,odor,'c','lineWidth',2); ylabel('odor');
        set(gca,'Xlim',[0 max(t)]);
        box off; set(gca,'TickDir','out');
        set(gca,'Ylim',[-0.5 5.5]);
        xlabel('time (seconds)');
        
    
    subplot(2,1,1); title(sprintf('Whole Cell: %s %d %s, Exp %d %s',data(n).odorname,data(n).conc,data(n).aircond,data(n).expnumber,data(n).date));

