%% Amp modulation acquisition code

% Allows the user to present a variety of pure tones and AM stimuli.  The
% following functions are included:
%           (1) testPiezo - Presents 3 different piezo step stimuli (.3906
%           um, 3.125 um, and 25 um) in each direction (medial and
%           lateral).  Also presents a sAM piezo stimulus with a 90 Hz
%           carrier and 8 Hz AM, 3.125 um peak-to-trough amplitude.
%
%           (2) testFmAndCS - Presents AM sounds with a carrier frequency
%           of 200 Hz, duty cycle of 50%, modulation depth of 100%, 
%           duration of 2 seconds, and a range of modulation frequencies
%           (1, 2, 4, 8, and 16 Hz).  Also presents courtship song.
%           
%           (3) testFc - Presents a series of pure tones at different
%           frequencies and intensities.
%
%           (4) takeSweep - Simply takes a sweep of the neural activity in
%           either VClamp or IClamp mode.
%   
%           (5) testRseal - Applies a voltage ramp and calculates the seal
%           resistance.
%
% Inputs:
%       (1) protocol - choose from 'testPiezo','testFmAndCS', 'testFc', 'takeSweep',
%                    and 'testRseal' (string)
%       (2) numrepeats - number of times the protocol will be repeated
%                    (scalar)
%       (3) fly_genotype - genotype of the test fly (string; e.g., 'CD8-70G01')                
%       (4) fly_number - fly number for a given day (scalar)
%       (5) cell_number - cell number for a given fly (scalar)
%       (6) Vm_id - Which Vm is this of the Vms you are testing? (scalar,
%       use 0 if Vm_id is irrelevant, like during VRamp; use 1 for depolarized Vm, 
%       use 2 for "physiological" Vm, use 3 for hyperpolarized Vm)
%       (7) rec_mode - Are you in VClamp or IClamp? (string - state 'VClamp' or 'IClamp')
%       

exp_info.fly_genotype = '70G01';
exp_info.fly_number = 0;
exp_info.cell_number = 1;
exp_info.Vm_id = 1;     %   (6) Vm_id - Which Vm is this of the Vms you are testing? (0 for irrelevant, 1 for de-pol, 2 for hyp-pol)
exp_info.protocol = 'FmAndCS';
exp_info.rec_mode = 'VClamp';  % Figure this out from a voltage reading
exp_info.piezo_type = 'Physik Instrumente, P-840.2';

% [exp_info.AI exp_info.AO] = configureAIAO(exp_info.protocol);
testfm = [1 2 4 8 16];
exp_info.stim_dur = 2;           % stimulus duration
exp_info.fc = 200;               % carrier frequency (in Hz)
exp_info.particle_vel = 3*10^-2; % approximate particle velocity in m/s
exp_info.intensity = 2;       % voltage required for this intensity/fc combination
for k=testfm
    exp_info.fm = k;
    exp_info.stimName = ['Fc = ',num2str(exp_info.fc),' Hz, Fm = ',...
        num2str(exp_info.fm),' Hz'];
%     runSpeakerAndPiezo(exp_info);
end
exp_info.stimName = 'Courtship Song';
exp_info.fm = 0;
exp_info.stim_dur = 0;
exp_info.fc = 0;
exp_info.particle_vel = 0;
exp_info.intensity = 1; %1;       % scales down courtship song voltage output so that
                                        % sine song is ~0.4 V (corresponds
                                        % to ~3-4um antennal displacement,
                                        % like 90 Hz AM stimulus above),
                                        % and pulse song portion has a max
                                        % amplitude of ~0.75 V (corresponds
                                        % to ~8-10 um antennal
                                        % displacement)
% runSpeakerAndPiezo(exp_info);
% make a directory if one does not exist
if ~isdir(['C:\Users\Anthony Azevedo\Acquisition\',date,'\',...
        date,'_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number)])
    mkdir(['C:\Users\Anthony Azevedo\Acquisition\',date,'\',...
        date,'_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number)]);
end

% access data structure and count trials
% check whether a saved data file exists with today's date
D = dir(['C:\Users\Anthony Azevedo\Acquisition\',date,'\',date,...
    '_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number),'\WCwaveform_',...
    date,'_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number),'.mat']);
if isempty(D)
    % if no saved data exists then this is the first trial
    n=1;
    disp(n);
else
    %load current data file
    load(['C:\Users\Anthony Azevedo\Acquisition\',date,'\',date,...
        '_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number),'\WCwaveform_',...
        date,'_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number),'.mat']','data');
    n = length(data)+1;
    disp(n);
end

% experiment information
data(n).protocol = exp_info.protocol;                           % protocol (string conveying what parameter is being varied)
data(n).date = date;                                            % experiment date
data(n).flynumber = exp_info.fly_number;                        % fly number
data(n).flygenotype = exp_info.fly_genotype;                    % fly genotype (e.g., CD8-70G01)
data(n).cellnumber = exp_info.cell_number;                      % cell number
data(n).trial = n;                                              % trial number
data(n).sampratein = 10000;                                     % input sample rate
data(n).recMode= exp_info.rec_mode;                             % recording mode ('VClamp' or 'IClamp')
if strcmp(data(n).protocol,'testPiezo')
    data(n).samprateout = 10000;                                % output sample rate if driving a piezo
else
    data(n).samprateout = 40000;                                % output sample rate if driving a speaker
end

data(n).Vm_id = exp_info.Vm_id;                                 % which Vm is this of the Vms you are testing?
                                                                % (set to 0 if Vm is irrelevant or you are too lazy)

if ~strcmp(data(n).protocol,'testRseal') && ~strcmp(data(n).protocol,'takeSweep')
    AI = exp_info.AI; AO = exp_info.AO; 
end

% set trial parameters
if strcmp(exp_info.rec_mode,'IClamp')
    data(n).currentscale = 1000;
    %data(n).currentscale = 108; %200                           % scaling factor for current (pA)
    data(n).voltagescale = 10.3; %10.3 when output gain is 100; % scaling factor for voltage (mV)
elseif strcmp(exp_info.rec_mode,'VClamp')
    data(n).currentscale = 10; %200                             % scaling factor for current (pA)
    data(n).voltagescale = 20; %10.3 when output gain is 100;   % scaling factor for voltage (mV)
end
data(n).currentoffset= -0.0335;
data(n).voltageoffset = 0*data(n).voltagescale;                 % offset for voltage

%data(n).currentscale = 2000; %200                              % scaling factor for current (pA)
%data(n).currentoffset = .007*data(n).currentscale;             % offset for current
%data(n).voltagescale = 10.2; %10.2 when output gain is 100;    % scaling factor for voltage (mV)
data(n).voltageoffset = 0*data(n).voltagescale;                 % offset for voltage
data(n).intensity = exp_info.intensity;                         % scaling factor for output voltage
data(n).fc = exp_info.fc;                                       % carrier frequency (Hz)
data(n).fm = exp_info.fm;                                       % modulation frequency (Hz)
data(n).stimdur = exp_info.stim_dur;                            % stimulus duration (seconds)
data(n).Ihpulse = -0.0111;                                      % hyperpolarizing pulse should give a
% 4 pA hyperpolarizing signal

data(n).stimName = exp_info.stimName;
data(n).stimonset = 1;                                  % time before stim on (seconds)
data(n).stimpost = .5;                                  % time after stim offset (seconds)
data(n).particle_velocity = exp_info.particle_vel;      % particle velocity tested
        
        % define stimulus parameters and generate stimuli
        if strcmp(data(n).stimName,'Courtship Song')
            stimtrain = wavread('C:\Users\Anthony Azevedo\Code\FlySounds\CourtshipSong.wav');
            data(n).stimdur = length(stimtrain)/data(n).samprateout;
            intensity = data(n).intensity;
            stimtrain = intensity*stimtrain;
        else
            [stimtrain intensity] = generateStim(data,n);
        end
        
        % timing calculations
        data(n).stimonsamp = floor(data(n).stimonset*data(n).samprateout)+1;
        data(n).stimoffsamp = floor(data(n).stimonset*data(n).samprateout)+(data(n).samprateout*data(n).stimdur);
        data(n).nsampout = data(n).stimoffsamp+floor(data(n).stimpost*data(n).samprateout);
        data(n).nsampin = ceil(data(n).nsampout/data(n).samprateout*data(n).sampratein);
        
        stim = zeros(data(n).nsampout,1); 
        stim(data(n).stimonsamp:data(n).stimoffsamp) = stimtrain; %stimulus
    end
    
    % check that stim is a column vector
    if size(stim,1)==1; stim=stim'; end

    data(n).trigdiff = 0;    % time between input and output triggers
    data(n).Ihold = 0;
    data(n).Vrest = 0;
    data(n).Rin = 0;
    
    %% generate hyperpolarizing test pulse
    hpulseon = floor(data(n).sampratein*0.05);  % test pulse begins at .05 seconds
    hpulseoff = floor(data(n).sampratein*0.25); % test pulse ends at .25 seconds
    Iin = zeros(data(n).nsampout,1);
    Iin(floor(hpulseon*data(n).samprateout/data(n).sampratein):...
        floor(hpulseoff*data(n).samprateout/data(n).sampratein)) = data(n).Ihpulse; % hyperpolarizing pulse
                                                                                    % should be 4 pA
    
    %% begin acquisition
    % load stimulus (zero-pad by 100 samples)
    if strcmp(data(n).protocol,'testPiezo')
        ch0out = [stim;5*ones(100,1)]; % "set point" for piezo is 5 V
    else
        ch0out = [stim;zeros(100,1)];
    end
    ch1out = [Iin;zeros(100,1)];
    putdata(AO,[ch0out, ch1out]);
        
    %% run trial
    % start playback
    start([AI AO]);
    trigger([AI AO]);
    
    % wait for playback/recording to finish
    nsampin = AI.SamplesAcquired;
    nsampout = AO.SamplesOutput;
    while (nsampin<data(n).nsampin)
        nsampin = AI.SamplesAcquired;
        nsampout = AO.SamplesOutput;
    end
    
    % stop playback
    stop([AI AO]);
    
    % record difference in AI/AO start times
    data(n).trigdiff = AO.InitialTriggerTime-AI.InitialTriggerTime;
    
    % read data from engine
    x = getdata(AI,data(n).nsampin);
    if strcmp(data(n).recMode,'VClamp')
        voltage = x(:,1); voltage = voltage';  % acquire voltage from 10Vm (channel ACH0)
        current = x(:,3); current = current';  % acquire current from scaled output (channel ACH3)
    elseif strcmp(data(n).recMode,'IClamp')
        current = x(:,2); current = current';  % acquire current from Iout (channel ACH2)
        voltage = x(:,3); voltage = voltage';  % acquire voltage from scaled output (channel ACH3)
    end
    
    % apply scaling factors
    current=current*data(n).currentscale-data(n).currentoffset;
    voltage=voltage*data(n).voltagescale-data(n).voltageoffset;
    %stim = repmat(data(n).stim',data(n).sampratein/data(n).samprateout,1); stim = stim(:);
    stim = stim';
    
    % calculate Ihold, Vrest, Rin
    % (mean holding current and resting potential are calculated between .2 and .4 seconds)
    data(n).Ihold = mean(current((hpulseoff+(.1*data(n).sampratein)):...
        (hpulseoff+(.3*data(n).sampratein)))); 
    data(n).Vrest = mean(voltage((hpulseoff+(.1*data(n).sampratein)):...
        (hpulseoff+(.3*data(n).sampratein))));
    
    % input resistance (Rin) is calculated from the change in voltage and the
    % change in current during the hyperpolarizing pulse
    Ipulse = 10^-9*(data(n).Ihpulse*.18*2);  % 0.18 is voltage divider transformation, 
                                             % and 2 is ext. command transformation
    Vpulse =  10^-3*(data(n).Vrest-mean(voltage(hpulseon*2:hpulseoff))); % calculate Vpulse over 
                                                                         % 0.1 to 0.25 seconds
    
    % disp(['Rin = Vpulse (',num2str(Vpulse),') / Ipulse (',num2str(Ipulse),')']);
    data(n).Rin = Vpulse/Ipulse;
    Rin_sofar = [data.Rin];
    Ihold_sofar = [data.Ihold];
    Vrest_sofar = [data.Vrest];
    
    disp(['Rin = ',num2str(data(n).Rin),', Vrest = ',num2str(data(n).Vrest),...
        ', Ihold = ',num2str(data(n).Ihold)]);
    
    %% save data(n)
    save(['C:\Users\Anthony Azevedo\Acquisition\',data(n).date,'\',...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber),'\WCwaveform_', ...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber)],'data');
    save(['C:\Users\Anthony Azevedo\Acquisition\',data(n).date,'\', ...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber),'\Raw_WCwaveform_', ...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber),'_', ...
        num2str(n)],'current','voltage','stim');
    
    %% plot Rin, Vrest, and Ihold
    plotData(data,Vrest_sofar,Ihold_sofar,Rin_sofar,voltage,current,stim,n);
end

return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [stimtrain intensity] = generateStim(data,n)

if strcmp(data(n).protocol,'testFmAndCS') || strcmp(data(n).protocol,'testFc')
    stimname = ['AM tone, fc ', num2str(data(n).fc),' Hz, fm ', ...
        num2str(data(n).fm), ' Hz, m = 100%, duration ',...
        num2str(data(n).stimdur),' seconds'];
    AMtrain = amp_mod(1,data(n).fm,data(n).fc,.5,...
        data(n).samprateout,data(n).stimdur,1,'with carrier');
    if isempty(AMtrain)
        fprintf('AM stimulus not generated');
        return;
    end
    intensity = data(n).intensity; % set voltage scaling factor for stimulus output
    stimtrain = intensity.*AMtrain';  % make sure stim is a column vector 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%