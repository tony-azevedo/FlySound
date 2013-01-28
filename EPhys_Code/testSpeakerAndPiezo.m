function testSpeakerAndPiezo(protocol,numrepeats,fly_genotype,fly_number,cell_number,Vm_id,rec_mode)

% function rtestSpeakerAndPiezo(protocol,numrepeats,fly_genotype,fly_number,cell_number,Vm_id,rec_mode)
% 
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% function command
% put all experiment info in exp_info (for easily passing into acquisition code)
exp_info.fly_genotype = fly_genotype;
exp_info.fly_number = fly_number;
exp_info.cell_number = cell_number;
exp_info.Vm_id = Vm_id;
exp_info.protocol = protocol;
exp_info.rec_mode = rec_mode;
exp_info.piezo_type = 'Physik Instrumente, P-840.6, two piezos';

% protocol switchboard
if strcmp(protocol,'testRseal')
    % IN VOLTAGE CLAMP, BEFORE BREAKING IN TO CELL: Hold at -60 mV, and apply   
    % a smooth voltage ramp from -75 mV to -45 mV that lasts approximately 
    % three seconds.  The currents measured during this experiment will be 
    % used to form an I-V curve.  The linear part of this I-V curve will then 
    % give us the seal resistance for a given cell (calculated from the slope 
    % of the linear portion).  Nonlinearities may arise at depolarized potentials 
    % due to active conductances.
    for z = 1:numrepeats
        testRseal(exp_info);
    end
    close all;
elseif strcmp(protocol,'takeSweep')
    % Take a single sweep (2 seconds long) of the voltage and current.
    % Minimally, you should take one sweep when sealed on to the cell, one
    % sweep in I=0, and one sweep with a holding current.
    for z = 1:numrepeats
        takeSweep(exp_info);
    end
    close all;
elseif strcmp(protocol,'testPiezo')
    % check to make sure piezo is positioned at 5
    exp_info.piezoReady = input(['Piezo set to 5V? (1/0) >> ']);
    if isempty(exp_info.piezoReady)
        exp_info.piezoReady = 1;
    end

    for z = 1:numrepeats
        testPiezo(exp_info);
    end
    close all;
elseif strcmp(protocol,'testFmAndCS')
    for z = 1:numrepeats
        testFmAndCS(exp_info);
    end
    close all;
elseif strcmp(protocol,'testFc')
    for z = 1:numrepeats
        testFc(exp_info);
    end
    close all;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% testRseal
function testRseal(exp_info)
runSpeakerAndPiezo(exp_info);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% takeSweep
function takeSweep(exp_info)
runSpeakerAndPiezo(exp_info);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% testPiezo
function testPiezo(exp_info)
% configure AI and AO
[exp_info.AI exp_info.AO] = configureAIAO(exp_info.protocol);

% stimTypeOrder = [1 2 3];
stimTypeOrder = [1 2]; % determines pseudorandom order (stimulus
                       % waveforms were generated with this same pseudorandom order)
for j = stimTypeOrder
    exp_info.stimType = j;
    % stimType 1 corresponds to a single step that will vary in  magnitude
    % stimType 2 corresponds to an sAM stimulus with carrier
    % stimType 3 corresponds to the envelope of the AM stimulus (i.e., without carrier)
    
    if exp_info.stimType==1  % single step
        exp_info.step_dur = .25; % duration of step in seconds
        exp_info.stim_dur = exp_info.step_dur;
        exp_info.fc = [];
        exp_info.fm = [];
        
        intensity_vector = (1/9)*[-25 -3.125 -0.3906 0.3906 3.125 25];
        % intensities correspond to deflections in negative
        % (medial) and positive (lateral) directions
        
        stimOrder = intensity_vector([1 5 3 2 4 6]); % pseudorandom order
        % a single intensity (step magnitude) will be tested each trial
        % and will be used to locate and load the appropriate
        % stimulus waveform for that intensity
        
        for k = stimOrder
            exp_info.intensity = k;
            runSpeakerAndPiezo(exp_info);
        end
        
    elseif exp_info.stimType==2         % sinusoidal amplitude modulated stimulus with carrier
        exp_info.stim_dur = 1;          % stimulus duration in seconds
        exp_info.step_dur = exp_info.stim_dur;
        fc = [70 90];                   % carriers to test
        fm_vector = [8];                % sAM frequencies to test
        exp_info.fm = fm_vector(randi(length(fm_vector),1));
        exp_info.intensity = 1/9*3.125; % amplitude (peak-to-trough) will be 3.125um
        fcOrder = fc;
        for k = fcOrder
            exp_info.fc = k;
            runSpeakerAndPiezo(exp_info);
        end
        
        %             elseif exp_info.stimType==3 % sinusoidal amplitude modulated stimulus without carrier
        %                 exp_info.stim_dur = 1;     % stimulus duration in seconds
        %                 exp_info.step_dur = exp_info.stim_dur;
        %                 %exp_info.intensity = .04;  % corresponds to 360 nm displacement with PI piezo
        %                 fm_vector = [8];       % same sAM frequencies will be tested, but without carrier
        %                 exp_info.fm = fm_vector(randi(length(fm_vector),1));
        %                 exp_info.fc = [];          % stimulus has no carrier
        %                 intensity_vector = 1/9*[-0.3472 0.3472]; % amplitude will be 3.125um,
        %                                                          % corresponding to a loud sound
        %                 stimOrder = [1 2];
        %                 for k = stimOrder
        %                     exp_info.intensity = intensity_vector(k);
        %                     runSpeakerAndPiezo(exp_info);
        %                 end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% testFmAndCS
function testFmAndCS(exp_info)
% configure AI and AO
[exp_info.AI exp_info.AO] = configureAIAO(exp_info.protocol);

% run data acquisition
for j=[1 2]
    if j==1
        testfm = [1 2 4 8 16];
        exp_info.stim_dur = 2;           % stimulus duration
        exp_info.fc = 2400;               % carrier frequency (in Hz)
        exp_info.particle_vel = 3*10^-2; % approximate particle velocity in m/s
        exp_info.intensity = 2;       % voltage required for this intensity/fc combination
        for k=testfm
            exp_info.fm = k;
            exp_info.stimName = ['Fc = ',num2str(exp_info.fc),' Hz, Fm = ',...
                num2str(exp_info.fm),' Hz'];
            runSpeakerAndPiezo(exp_info);
        end
    elseif j==2
        exp_info.stimName = 'Courtship Song';
        exp_info.fm = 0;
        exp_info.stim_dur = 0;
        exp_info.fc = 0;
        exp_info.particle_vel = 0;
        exp_info.intensity = 3; %1;       % scales down courtship song voltage output so that 
                                        % sine song is ~0.4 V (corresponds
                                        % to ~3-4um antennal displacement,
                                        % like 90 Hz AM stimulus above),
                                        % and pulse song portion has a max
                                        % amplitude of ~0.75 V (corresponds
                                        % to ~8-10 um antennal
                                        % displacement)
        runSpeakerAndPiezo(exp_info);
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% testFc
function testFc(exp_info)
% configure AI and AO
[exp_info.AI exp_info.AO] = configureAIAO(exp_info.protocol);

% define isointensity series for six frequencies (70,100,200,300,700,1000 Hz)
% for exp_info.sound_intensity matrix, each row corresponds to one particle
% velocity, and each column corresponds to one frequency
%
% note: a value of NaN means that the SNR during calibration was too poor
% (this explains NaNs for low intensity, low frequency stimuli), or there
% was too much distortion (explains NaNs for high intensity, low frequency
% stimuli)
sound_intensity = [.05   .15   .15  .1 ;
                   .1    .3    .3   .25 ;
                   .6    1     1    .5  ;];
% for particle_velocity, each row corresponds to the rows in
% sound_intensity
particle_velocities = [1; 1; 1];
frequencies = [90 300 700 1000];
exp_info.stim_dur = 2; % stimulus duration in seconds
exp_info.fm = 8;  % 2 Hz AM chosen because modulated stimuli seem to drive 
                       % the cell better than unmodulated stimuli; 2 Hz seems 
                       % to effectively drive all cells

% run data acquisition
for k = 1:3   % cycle through 4 different intensity series
    exp_info.particle_vel = particle_velocities(k);
    notNaN = ~isnan(sound_intensity(k,:));
    exp_info.fc_vector = frequencies(notNaN); % find which frequencies have non-NaN values
    intensity_vector = sound_intensity(k,notNaN); % find intensities for frequencies with non-NaN values
    
    for fc = exp_info.fc_vector % cycle through different frequencies
        exp_info.fc = fc;
                                % exp_info.intensity describes which voltage to use for the frequency being tested
        exp_info.intensity = intensity_vector(exp_info.fc_vector==fc); 
        runSpeakerAndPiezo(exp_info);
    end
end
