%% stimulus generation, 02_05_2016 JCT 
%  edited 08_2016 to include camera triggering and saving
% now just triggering, saving not working in matlab...
clear all;close all; %imaqreset;

%% initialize params
dpath = 'E:\Dropbox (Tuthill Lab)\imaging data\';
% fileTag = 'camppoke_03_01_08252016';
% vid = videoinput('pointgrey', 1, 'F7_Mono8_1288x964_Mode0');
% src = getselectedsource(vid);
% triggerconfig(vid, 'hardware', 'risingEdge', 'externalTriggerMode15-Source3');
% vid.TriggerRepeat = 0;
% vid.FramesPerTrigger = 100;
% vid.LoggingMode = 'disk&memory';
% src.ShutterMode = 'auto';
% src.Shutter = 50;

abf_file = '2016_11_02_0001';
stim_function = 'square_ao_func_trigger_08_2016';

framerate = 10; %fps, trigger rate for frames from camera

% Strobe stuff
% % src.Strobe2 = 'On';
% src.Strobe1Polarity = 'High';
% set(src,'FrameRate','25')


% preview(vid)

%%
% stoppreview(vid)

%%
% diskLogger = VideoWriter([dpath fileTag '_'  '.avi'], 'Uncompressed AVI');

lengths_off = [2000]; %%(ms of stimulus off)
lengths_on = [500]; %%(ms of stimulus on)
movements = [-1.0, -0.5, -1.5]%, -1.5, -2.0]; %% in microns
reps = 2;%% number of times to repeat all trials
pause_time = 5; %% pause between trials in sec
num_cycles = 10; %% number of reps per trial
plot_flag = 1; %% if 0, don't plot the data;

num_conditions = length(lengths_on)*length(lengths_off)*length(movements);
cond_sigs = [1 2.6 4.2 5.8 7.4 9 ];%% scale cond sig between 1 and 9 volts

all_lengths = meshgrid(lengths_off, lengths_on)+meshgrid(lengths_on, lengths_off)';
total_length = reps*((pause_time*num_conditions)+length(movements)*num_cycles*sum(all_lengths(:)/1000));%% in secs
display(['total exp length = ' num2str(total_length) ' secs']);

%% make and save conditions matrix  
conds_mat = [];cond_num = 1;conds = [];
for ii = 1:length(lengths_on)
  for  kk = 1:length(lengths_off)
    for jj = 1:length(movements)
        conds(cond_num).cond= cond_num;
        conds(cond_num).on = lengths_on(ii);
        conds(cond_num).off = lengths_off(kk);
        conds(cond_num).move = movements(jj);
        conds(cond_num).reps = reps;
        conds(cond_num).pause = pause_time;
        conds(cond_num).cycles = num_cycles;
        conds(cond_num).cs = cond_sigs(cond_num);
        conds(cond_num).func = stim_function;
        conds(cond_num).time = datestr(datetime('now','TimeZone','local'), 'yy_MM_dd_HH_mm_ss');
        conds(cond_num).abf = abf_file;
        cond_num= cond_num+1;
    end 
  end
end

%% initialize ao and set all channels to zero
global nisesh;
nisesh = daq.createSession('ni');
addAnalogOutputChannel(nisesh,'Dev1',[0:1],'Voltage');
nisesh.addDigitalChannel('Dev1','port0/line0','OutputOnly')
queueOutputData(nisesh,[0 0 0]);%% first 2 channels are AO to the piezo and the daq; third is condition signal; fourth is to trigger camera
nisesh.Rate = 2000;
nisesh.startForeground;

%% play stimuli in a randomized order

% vid.DiskLogger = diskLogger;
% src.Strobe2 = 'On';
% vid.TriggerRepeat = Nframes-1; % s.DurationInSeconds*src.FrameRate
% start(vid);

for ii = 1:reps
  rand_conds = randperm(length(conds));

  for jj = 1:length(conds)
      
    cond_num = rand_conds(jj);
    pause(conds(cond_num).pause);
    
    display(['starting trial ' num2str(jj) ' of ' num2str(length(conds)) ', rep ' num2str(ii)...
    ' of ' num2str(reps) '; condition = ' num2str(cond_num)]);

%     ramp_ao_func_03_15_2016(conds(cond_num).move, conds(cond_num).cycles, conds(cond_num).on, ...
%     conds(cond_num).off, conds(cond_num).cs ,plot_flag); 

    square_ao_func_trigger_08_2016(conds(cond_num).move, conds(cond_num).cycles, conds(cond_num).on, ...
    conds(cond_num).off, conds(cond_num).cs ,framerate, plot_flag); 

  end
end

% stop(vid)

display('all done'); beep;