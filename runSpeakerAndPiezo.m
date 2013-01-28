function data = runSpeakerAndPiezo(exp_info)

% function presents acoustic or piezoelectric stimuli and acquires voltage
% and current data

% make a directory if one does not exist
if ~isdir(['C:\Users\Anthony Azevedo\Acquisition',date,'\',...
        date,'_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number)])
    mkdir(['C:\Users\Anthony Azevedo\Acquisition',date,'\',...
        date,'_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number)]);
end

%% access data structure and count trials
% check whether a saved data file exists with today's date
D = dir(['C:\Users\Anthony Azevedo\Acquisition',date,'\',date,...
    '_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number),'\WCwaveform_',...
    date,'_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number),'.mat']);
if isempty(D)
    % if no saved data exists then this is the first trial
    n=1;
    disp(n);
else
    %load current data file
    load(['C:\Users\Anthony Azevedo\Acquisition',date,'\',date,...
        '_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number),'\WCwaveform_',...
        date,'_F',num2str(exp_info.fly_number),'_C',num2str(exp_info.cell_number),'.mat']','data');
    n = length(data)+1;
    disp(n);
end

%% assign default values of input parameters

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

%% run data acquisition
% calculate seal resistsance with voltage ramp
if strcmp(data(n).protocol,'testRseal')
    data(n).currentscale = 10; %200                               % scaling factor for current (pA)
    data(n).currentoffset = .1*data(n).currentscale;              % offset for current
    data(n).voltagescale = 20; %10.3 when output gain is 100;     % scaling factor for voltage (mV)
    data(n).voltageoffset = 0*data(n).voltagescale;               % offset for voltage
    data(n).durRamp = 5;    % duration of the voltage ramp (in seconds)
    rangeRamp = [-4 4];  % starting voltage and ending voltage of ramp
    data(n).rangeRamp = rangeRamp.*0.18*20; % 0.18 is voltage divider constant, 20 mv/V is axopatch scaling factor
    data(n).startRamp = .5;  % start of ramp (in seconds)
    data(n).endRamp = data(n).durRamp-.5;  % end of ramp (in seconds)
    [Vcomm,Vmeas,Imeas,data(n).trigdiff] = rampVoltage(data(n).durRamp,...
        rangeRamp,data(n).sampratein);
    
    % apply appropriate scaling to current
    Vcomm = Vcomm; 
    Imeas = Imeas*data(n).currentscale-data(n).currentoffset;
    Vmeas = Vmeas*data(n).voltagescale-data(n).voltageoffset;
    
    % plot voltage ramp and calculate seal resistance
    data(n).sealRes = calcRseal(data,Imeas,Vmeas,Vcomm,n);
    
    % save data
    save(['C:\Users\Anthony Azevedo\Acquisition\',data(n).date,'\',...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber),'\WCwaveform_', ...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber)],'data');
    save(['C:\Users\Anthony Azevedo\Acquisition\',data(n).date,'\', ...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber),'\Raw_WCwaveform_', ...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber),'_', ...
        num2str(n)],'Imeas','Vmeas','Vcomm');

    return;
    
% take a sweep of the voltage and current
elseif strcmp(data(n).protocol,'takeSweep')
    if strcmp(exp_info.rec_mode,'IClamp')
        %data(n).currentscale = 108; %200                           % scaling factor for current (pA)
        data(n).currentscale = 1000;
        data(n).voltagescale = 10.3; %10.3 when output gain is 100; % scaling factor for voltage (mV)
    elseif strcmp(exp_info.rec_mode,'VClamp')
        data(n).currentscale = 10; %200                             % scaling factor for current (pA)
        data(n).voltagescale = 20; %10.3 when output gain is 100;   % scaling factor for voltage (mV)
    end
    data(n).currentoffset= -0.0335;  
    data(n).voltageoffset = 0*data(n).voltagescale;                 % offset for voltage
    data(n).recMode= exp_info.rec_mode;
    data(n).durSweep = 2; % each sweep is two seconds
    
    % acquire
    [voltage,current] = takeSweep(data(n).recMode,data(n).durSweep,data(n).sampratein);
    
    % apply scaling factors
    current = (current-data(n).currentoffset)*data(n).currentscale;
    voltage = voltage*data(n).voltagescale-data(n).voltageoffset;
    
    % save data(n)
    save(['C:\Users\Anthony Azevedo\Acquisition\',data(n).date,'\',...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber),'\WCwaveform_', ...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber)],'data');
    save(['C:\Users\Anthony Azevedo\Acquisition\',data(n).date,'\', ...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber),'\Raw_WCwaveform_', ...
        data(n).date,'_F',num2str(data(n).flynumber),'_C',num2str(data(n).cellnumber),'_', ...
        num2str(n)],'current','voltage');
    
    % plot data
    figure(1); 
    t=[0:data(n).durSweep*data(n).sampratein-1]/data(n).sampratein;
    subplot(2,1,1); plot(t,voltage,'r','linewidth',1);
    box off; set(gca,'TickDir','out');
    ylabel('V_m (mV)'); xlim([0 max(t)]);
    subplot(2,1,2); plot(t,current,'b','linewidth',1);
    box off; set(gca,'TickDir','out'); xlabel('time (s)');
    ylabel('I (pA)'); xlim([0 max(t)]);
    
    return;
else  % for testPiezo, testFmAndCS, and testFc
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
    
    %% load and construct piezo or sound stimulus waveforms
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % load sculpted piezo commands
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmp(data(n).protocol,'testPiezo')
        data(n).piezo_type = exp_info.piezo_type;                   % piezo type (e.g., PI) and arrangement 
                                                                    % (e.g., lehnert butt-coupled)
        data(n).stimonset = 1;                                      % time before stim on (seconds)
        if exp_info.stimType==1 % stimType of 1 indicates step stimuli; in this case, set step duration
            data(n).step_dur = exp_info.step_dur;
        end
        data(n).stimpost = .5; % time after stim offset (seconds)
        data(n).stimType = exp_info.stimType;
        if data(n).stimType==1
            data(n).stimName = 'Single step';
        elseif data(n).stimType==2
            data(n).stimName = 'sAM with carrier';
        elseif data(n).stimType==3
            data(n).stimName = 'sAM without carrier';
        end
        
        % load sculpted piezo command
        if data(n).stimType==2
            load(['C:\Allison\Electrophysiology\EPhys_Codes\PiezoStim'...
                '\Gen3stimuli\sAMwithcarrier_',num2str(data(n).fc),'HzfiltStim'],'filtStim');
            stim=filtStim;
        else
            % determine step direction
            if data(n).intensity<0
                stepDir = 'Medial';
            else
                stepDir = 'Lateral';
            end
            if data(n).stimType==3
                load(['C:\Allison\Electrophysiology\EPhys_Codes\PiezoStim'...
                    '\Gen3stimuli\sAMnocarrier',stepDir,'_filtStim'],'filtStim');
                stim=filtStim;
            elseif data(n).stimType==1
                intensity = num2str(abs(data(n).intensity*9)); % display intensity in microns (intensity*9um/V)
                intensity(intensity=='.') = '-';
                load(['C:\Allison\Electrophysiology\EPhys_Codes\PiezoStim'...
                '\Gen3stimuli\',intensity,'um',stepDir,'_filtStim'],'filtStim');
                stim=filtStim;
            end
        end
        % timing calculations
        data(n).stimonsamp = floor(data(n).stimonset*data(n).samprateout)+1;
        data(n).stimoffsamp = floor(data(n).stimonset*data(n).samprateout)+(data(n).samprateout*data(n).stimdur);
        data(n).nsampout = data(n).stimoffsamp+floor(data(n).stimpost*data(n).samprateout);
        data(n).nsampin = ceil(data(n).nsampout/data(n).samprateout*data(n).sampratein);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % generate Fm and courtship song stimuli
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        if strcmp(data(n).protocol,'testFmAndCS')
            data(n).stimName = exp_info.stimName;
        end
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
%% plotData(data,Vrest_sofar,Ihold_sofar,Rin_sofar,voltage,current,stim,n)
function plotData(data,Vrest_sofar,Ihold_sofar,Rin_sofar,voltage,current,stim,n)

t_in=[1:data(n).nsampin]'/data(n).sampratein;
t_out = [1:data(n).nsampout]'/data(n).samprateout;

% plot Rin, Vrest, and Ihold throughout experiment
if n==1
    figure(1); scrsz = get(0,'ScreenSize');
    set(gcf,'Position',[50 scrsz(4)/2 scrsz(3)-100 scrsz(4)/2.5]);
end
figure(1);
	subplot(3,1,1); hold on; plot(1:length(Rin_sofar),10^-6*(Rin_sofar),'bo-'); 
        ylabel('Rin (megaohms)'); box off; set(gca,'TickDir','out','XTick',[]); xlim([0 n]);
	subplot(3,1,2); hold on; plot(1:length(Vrest_sofar),Vrest_sofar,'ro-'); 
        ylabel('Vrest (mV)'); box off; set(gca,'TickDir','out','XTick',[]); xlim([0 n]);
	subplot(3,1,3); hold on; plot(1:length(Ihold_sofar),Ihold_sofar,'ko-');
        ylabel('Ihold (pA)'); xlabel('time (sec)'); box off; set(gca,'TickDir','out'); xlim([0 n]);

% plot voltage and stim for each trial
figure(2); scrsz = get(0,'ScreenSize');
set(gcf,'Position',[1100 scrsz(4)/2 scrsz(3)-100 scrsz(4)/2.5]);
set(gcf,'PaperPositionMode','auto');
subplot(2,1,1); plot(t_in,voltage,'r','lineWidth',1); ylabel('V_m (mV)');
	set(gca,'Xlim',[data(n).stimonset-.2 max(t_in)],'XTick',[]);
%	ylim([min(voltage)-.1*max(voltage) max(voltage)+.1*max(voltage)]);
	box off; set(gca,'TickDir','out');
% subplot(3,1,2); plot(t_in,current,'g'); ylabel('I (pA)');
% 	xlim([0 max(t_in)]); box off; set(gca,'TickDir','out','XTick',[]);
subplot(2,1,2); plot(t_out,stim,'c','lineWidth',2); ylabel('stim');
	xlim([data(n).stimonset-.2 max(t_out)]);
	box off; set(gca,'TickDir','out','XTick',[]);
	set(gca,'Ylim',[min(stim)-(.1*max(stim)) max(stim)+(.1*max(stim))]);
	xlabel('time (seconds)');
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% function sealRes = calcRseal(data,Imeas,Vmeas,Vcomm)
function sealRes = calcRseal(data,Imeas,Vmeas,Vcomm,n)

% convert I and V to proper units
Vcomm = Vcomm.*.18.*20*(10^-3);  % Vcomm*voltage_divider*axopatch_scaling*mVtoVconversion
Imeas = Imeas.*(10^-12);  % Imeas*pAtoAconversion
t = [0:length(Imeas)-1]./data(n).sampratein;

% define what will most likely be the linear region of the IV curve
linearRegion = [(data(n).startRamp+.5)*data(n).sampratein:(data(n).endRamp-.5)*data(n).sampratein];

% calculate seal resistance
p = polyfit(Vcomm(linearRegion),Imeas(linearRegion),1);
%     fitFn = p(1).*([1:length(rampSamps)]./data(n).sampratein) + p(2);
%     subplot(2,4,[3 4 7 8]); plot(fitFn,'r','linewidth',2);
sealRes = 1/p(1);   % seal resistance = 1/slope
disp(['seal resistance = ',num2str(sealRes./10^9),' gigaohms']);

% plot IV curve with linear fit
createIVCurvewithLinFit(Vcomm(linearRegion),Imeas(linearRegion));
