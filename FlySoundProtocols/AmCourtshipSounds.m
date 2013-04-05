classdef AmCourtshipSounds < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'AmCourtshipSounds';
    end
    
    properties (Hidden)
        sensorMonitor
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = AmCourtshipSounds(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
            obj.stimx = ((1:obj.params.samprateout*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec)/obj.params.samprateout;
            obj.x = ((1:obj.params.sampratein*(obj.params.preDurInSec+obj.params.stimDurInSec+obj.params.postDurInSec))-obj.params.preDurInSec)/obj.params.sampratein;
        end
        
        function varargout = generateStimulus(obj,varargin)
            
            % define stimulus parameters and generate stimuli
            if strcmp(data(n).stimName,'Courtship Song')
                stimtrain = wavread('C:\Allison\Electrophysiology\EPhys_Codes\CourtshipSong.wav');
                data(n).stimdur = length(stimtrain)/data(n).samprateout;
                intensity = data(n).intensity;
                stimtrain = intensity*stimtrain;
            else
                [stimtrain intensity] = generateStim(data,n);
                stimname = ['AM tone, fc ', num2str(data(n).fc),' Hz, fm ', ...
                    num2str(data(n).fm), ' Hz, m = 100%, duration ',...
                    num2str(data(n).stimdur),' seconds'];
                AMtrain = amp_mod(1,data(n).fm,data(n).fc,.5,...
                    data(n).samprateout,data(n).stimdur,1,'with carrier');
                intensity = data(n).intensity; % set voltage scaling factor for stimulus output
                stimtrain = intensity.*AMtrain';  % make sure stim is a column vector
                
                t_temp = stimdur*samprate + samprate/fm; % extra samprate/fm is added
                                % to the initial signal
                                % that will later be cut out
                                % (in order to get a
                                % ramped, uniform signal)
                t_temp = 0:(1/samprate):t_temp/samprate-(1/samprate);
                
                % generate AM waveform (generate envelope and then multiply by carrier)
                envelope = [1+m*sin(2*pi*fm*t_temp)];
                if strcmp(directions,'envelope')
                    temp_AMsignal = envelope;
                else
                    temp_AMsignal =  envelope.*sin(2*pi*fc*t_temp);
                end
                
                % find first and last minima so that the signal can be clipped
                % at these two points
                [env_min ind_min] = find(envelope==min(envelope));
                ind_min = ind_min-1;
                clip(1) = (samprate/fm)-(length(envelope)-ind_min(end));
                clip(2) = ind_min(end);
                disp(['fm = ',num2str(fm),', clips = ',num2str(clip)]);
                
                % if clip(1) is negative, shift the clip frame by one envelope cycle
                if clip(1)<0
                    clip = clip+samprate/fm;
                end
                
                % if the clip length is longer or more than 10% shorter than the
                % desired stimulus length, display an error
                if diff(clip)>(stimdur*samprate)
                    disp('Stimulus is too long!');
                elseif diff(clip)<(.90*stimdur*samprate)
                    disp('Stimulus is much too short!');
                elseif clip(2)>length(envelope) % if the second clip exceeds the envelope length, display an error
                    disp('Clip exceeds envelope length!');
                end
                
                % clip AM_signal and normalize so that the peak amplitude is 1
                AM_signal = temp_AMsignal(clip(1):clip(2)-1);
                AM_signal = AM_signal.*(1/max(AM_signal));  % normalizes so that amplitude is -1
                
                if isempty(AMtrain)
                    fprintf('AM stimulus not generated');
                    return;
                end
                intensity = data(n).intensity; % set voltage scaling factor for stimulus output
                stimtrain = intensity.*AMtrain';  % make sure stim is a column vector
                
            end

            % timing calculations
            data(n).stimonsamp = floor(data(n).stimonset*data(n).samprateout)+1;
            data(n).stimoffsamp = floor(data(n).stimonset*data(n).samprateout)+(data(n).samprateout*data(n).stimdur);
            data(n).nsampout = data(n).stimoffsamp+floor(data(n).stimpost*data(n).samprateout);
            data(n).nsampin = ceil(data(n).nsampout/data(n).samprateout*data(n).sampratein);
            
            stim = zeros(data(n).nsampout,1);
            stim(data(n).stimonsamp:data(n).stimoffsamp) = stimtrain; %stimulus
        end
        
        % read data from engine
        
        %stim = repmat(data(n).stim',data(n).sampratein/data(n).samprateout,1); stim = stim(:);
        stim = stim';
        
        
        stim = globalPiezoChirpStimulus * obj.params.displacement; %*obj.dataBoilerPlate.displFactor;
        stim = stim + obj.params.displacementOffset;
        varargout = {stim,obj.x};
    end
    
    function run(obj,varargin)
    % Runtime routine for the protocol. obj.run(numRepeats)
    % preassign space in data for all the trialdata structs
    p = inputParser;
    addOptional(p,'repeats',1);
    addOptional(p,'vm_id',obj.params.Vm_id);
    parse(p,varargin{:});
    
    % stim_mat = generateStimFamily(obj);
    trialdata = appendStructure(obj.dataBoilerPlate,obj.params);
    trialdata.Vm_id = p.Results.vm_id;
    
    obj.aiSession.Rate = trialdata.sampratein;
    obj.aiSession.DurationInSeconds = trialdata.durSweep;
    
    obj.aoSession.Rate = trialdata.samprateout;
    
    stim = nan(length(obj.generateStimulus()),length((obj.aoSession.Channels)));
    
    for repeat = 1:p.Results.repeats
        
        fprintf('Trial %d\n',obj.n);
        
        stim(:,1) = obj.generateStimulus();
        stim(:,2) = obj.generateStimulus();
        
        obj.aoSession.queueOutputData(stim)
        obj.aoSession.startBackground; % Start the session that receives start trigger first
        obj.y = obj.aiSession.startForeground; % both amp and signal monitor input
        
        voltage = obj.y(:,1);
        current = obj.y(:,1);
        obj.sensorMonitor = obj.y(:,2);
        
        % apply scaling factors
        current = (current-trialdata.currentoffset)*trialdata.currentscale;
        voltage = voltage*trialdata.voltagescale-trialdata.voltageoffset;
        
        switch obj.recmode
            case 'VClamp'
                obj.y = current;
                obj.y_units = 'pA';
            case 'IClamp'
                obj.y = voltage;
                obj.y_units = 'mV';
        end
        
        obj.saveData(trialdata,current,voltage) % TODO: save signal monitor
        
        obj.displayTrial()
    end
    end
    
    function displayTrial(obj)
    figure(1);
    ax1 = subplot(4,4,[1 2 3 5 6 7 9 10 11]);
    
    redlines = findobj(1,'Color',[1, 0, 0]);
    set(redlines,'color',[1 .8 .8]);
    bluelines = findobj(1,'Color',[0, 0, 1]);
    set(bluelines,'color',[.8 .8 1]);
    
    line(obj.stimx,obj.generateStimulus,'parent',ax1,'color',[0 0 1],'linewidth',1);
    line(obj.x,obj.y(:,2),'parent',ax1,'color',[1 0 0],'linewidth',1);
    box off; set(gca,'TickDir','out');
    switch obj.recmode
        case 'VClamp'
            ylabel('I (pA)'); %xlim([0 max(t)]);
        case 'IClamp'
            ylabel('V_m (mV)'); %xlim([0 max(t)]);
    end
    xlabel('Time (s)'); %xlim([0 max(t)]);
    
    ax2 = subplot(4,4,[13 14 15]);
    line(obj.stimx,obj.generateStimulus,'parent',ax2,'color',[.7 .7 .7],'linewidth',1);
    %line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
    box off; set(gca,'TickDir','out');
    
    ax3 = subplot(1,4,4);
    
    sgsvalue = obj.y(:,2);
    sgsfft = real(fft(sgsvalue).*conj(fft(sgsvalue)));
    sgsf = obj.params.sampratein/length(sgsvalue)*[0:length(sgsvalue)/2]; sgsf = [sgsf, fliplr(sgsf(2:end-1))];
    
    stim = obj.generateStimulus;
    stimfft = real(fft(stim).*conj(fft(stim)));
    stimf = obj.params.samprateout/length(stim)*[0:length(stim)/2]; stimf = [stimf, fliplr(stimf(2:end-1))];
    
    [C,IA,IB] = intersect(sgsf,stimf);
    stimratio = sgsfft(IA)./stimfft(IB);
    
    loglog(stimf,stimfft/max(stimfft(stimf>obj.params.freqstart & stimf<obj.params.freqstop))), hold on;
    loglog(sgsf,sgsfft/max(sgsfft(sgsf>obj.params.freqstart & sgsf<obj.params.freqstop)),'r'), hold on;
    %             loglog(C,stimratio/max(stimratio(C>obj.params.freqstart & C<obj.params.freqstop/2)),'k'), hold on;
    
    %line(obj.x,obj.sensorMonitor,'parent',ax2,'color',[0 0 1],'linewidth',1);
    box off; set(gca,'TickDir','out');
    xlim([obj.params.freqstart obj.params.freqstop*.95])
    end
    
end % methods

methods (Access = protected)
    
    function createAIAOSessions(obj)
        % configureAIAO is to start an acquisition routine
        
        obj.aiSession = daq.createSession('ni');
        obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % from amp
        obj.aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % PZT Sensor monitor
        
        % configure AO
        obj.aoSession = daq.createSession('ni');
        obj.aoSession.addAnalogOutputChannel('Dev1',2, 'Voltage');
        obj.aoSession.addAnalogOutputChannel('Dev1',1, 'Voltage');
        
        obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
        obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
    end
    
    function createDataStructBoilerPlate(obj)
        % TODO, make this a map.Container array, so you can add
        % whatever keys you want.  Or cell array of maps?  Or a java
        % hashmap?
        createDataStructBoilerPlate@FlySoundProtocol(obj);
        obj.dataBoilerPlate.displFactor = 20/30; %V/um
    end
    
    function defineParameters(obj)
        defineParameters@FlySoundProtocol(obj);
        obj.params.displacementOffset = 0;
        obj.params.sampratein = 10000;
        obj.params.samprateout = 40000;
        obj.params.intensity = 1;
        obj.params.carrier = 0.1; %sec;
        obj.params.freqstart = 10; %Hz;
        obj.params.freqstop = 1000; %Hz
        obj.params.stimDurInSec = 5;
        obj.params.preDurInSec = .5;
        obj.params.postDurInSec = .5;
        obj.params.durSweep = obj.params.stimDurInSec+obj.params.preDurInSec+obj.params.postDurInSec;
        
        obj.params.Vm_id = 0;
        
        obj.setDefaults;
    end
    
    function stim_mat = generateStimFamily(obj)
        for paramsToVary = obj.params
            stim_mat = generateStimulus;
        end
    end
    
end % protected methods

methods (Static)
end
end % classdef


function AM_signal = amp_mod(m,fm,fc,dutycycle,samprate,stimdur,sine_env,directions)

% AM_signal = amp_mod(m,fm,fc,dutycycle,samprate,stimdur,sine_env)
%
% Generates an amplitude-modulated sine wave based on the function
% AM_signal = [1 + m*sin(2*pi*fm*t)]*sin(2*fc*t)
%
% Input:
%     (1) m - modulation depth (0<=m<=1)
%     (2) fm - modulation frequency (in Hz)
%     (3) fc - carrier frequency (in Hz)
%     (4) dutycycle - duty cycle (fraction of period spent in active state)
%     (5) samprate - sampling rate (typically between 32000 and 45000 Hz
%     for a sound stimulus)
%     (6) stimdur - duration of signal (in seconds)
%     (7) sine_env - is the AM envelope sinusoidal? (1=yes,0=no)
%     (8) directions - 'pulse' or 'pause' (pertains to stimuli in which the
%     duty cycle is varied)
%
% Output:
%     (1) AM_signal - amplitude modulated sine wave

%% check inputs
if m>1 || m<0
    disp('Enter a value for m that is between 0 and 1!');
end

% if dutycycle>1 || dutycycle<0
%     disp('Enter a value for dutycycle that is between 0 and 1!');
% end
%
% if(~isreal(fc) || ~isscalar(fc) || fc<=0 || ~isnumeric(fc) )
%     disp('fc must be a real, positive scalar!');
% end
%
% if(~isreal(fm) || ~isscalar(fm) || fc<=0 || ~isnumeric(fm) )
%     disp('fm must be a real, positive scalar!');
% end
%
% if(~isreal(samprate) || ~isscalar(samprate) || samprate<=0 || ~isnumeric(samprate))
%     disp('samprate must be a real, positive scalar!');
% end
%
% % check that Fs must be greater than 2*Fc
% if(samprate<2*fc)
%     disp('Error: Fs must be at least 2*Fc! (NYQUIST!!)');
% end

%% generate signal
AM_signal = zeros(1,(stimdur*samprate));
if sine_env==1
    t_temp = stimdur*samprate + samprate/fm; % extra samprate/fm is added
    % to the initial signal
    % that will later be cut out
    % (in order to get a
    % ramped, uniform signal)
    t_temp = 0:(1/samprate):t_temp/samprate-(1/samprate);
    
    % generate AM waveform (generate envelope and then multiply by carrier)
    envelope = [1+m*sin(2*pi*fm*t_temp)];
    if strcmp(directions,'envelope')
        temp_AMsignal = envelope;
    else
        temp_AMsignal =  envelope.*sin(2*pi*fc*t_temp);
    end
    
    % find first and last minima so that the signal can be clipped
    % at these two points
    [env_min ind_min] = find(envelope==min(envelope));
    ind_min = ind_min-1;
    clip(1) = (samprate/fm)-(length(envelope)-ind_min(end));
    clip(2) = ind_min(end);
    disp(['fm = ',num2str(fm),', clips = ',num2str(clip)]);
    
    % if clip(1) is negative, shift the clip frame by one envelope cycle
    if clip(1)<0
        clip = clip+samprate/fm;
    end
    
    % if the clip length is longer or more than 10% shorter than the
    % desired stimulus length, display an error
    if diff(clip)>(stimdur*samprate)
        disp('Stimulus is too long!');
    elseif diff(clip)<(.90*stimdur*samprate)
        disp('Stimulus is much too short!');
    elseif clip(2)>length(envelope) % if the second clip exceeds the envelope length, display an error
        disp('Clip exceeds envelope length!');
    end
    
    % clip AM_signal and normalize so that the peak amplitude is 1
    AM_signal = temp_AMsignal(clip(1):clip(2)-1);
    AM_signal = AM_signal.*(1/max(AM_signal));  % normalizes so that amplitude is -1
    
elseif sine_env==0   % NOTE: WHEN VARYING THE DUTY CYCLE, THE ENVELOPE IS NO LONGER SINUSOIDAL
    %     AM_signal(floor((dutycycle*(samprate/fm))/2):floor(samprate/fm):floor(stimdur*samprate)) = 1;
    %     AM_sigfilt = hanningsmooth(AM_signal,dutycycle*(samprate/fm));
    %     norm_factor = 1/max(AM_sigfilt);
    %     AM_sigfiltnorm = AM_sigfilt*norm_factor;
    %     if length(AM_sigfiltnorm)~=stimdur*samprate
    %         signal_diff = length(AM_sigfiltnorm)-(stimdur*samprate);
    %         if signal_diff==1
    %             AM_sigfiltnorm(end) = [];
    %         elseif signal_diff>1
    %             disp('signal length is more than 2 indices too long');
    %         end
    %     end
    %     s = AM_sigfiltnorm.*sin(2*pi*fc*t);
    %     AM_signal = s;
    t=[0:1/samprate:stimdur-(1/samprate)];
    min_pulse = 1/(fm/.25);  % the minimum pulse duration used in the dutycycle stimulus
    % set is determined by the 25% duty cycle
    if strcmp(directions,'pulse')
        pulse_dur = 1/(fm/dutycycle);
        pause_dur = (pulse_dur/dutycycle)-pulse_dur;
        pulsepluspause = pulse_dur+pause_dur;
        numones = (pulse_dur-min_pulse)*samprate; % determines number of samples in "plateau portion" of pulse
        for z = (min_pulse/2*samprate):(ceil(pulsepluspause*samprate)):ceil(length(AM_signal)-(min_pulse/2)*samprate)
            %             if z==min_pulse/2*samprate
            AM_signal(floor(z):floor(z+floor(numones))) = 1;
            %             else
            %                 AM_signal(floor(z-numones/2):floor((z+numones/2)-1)) = 1;
            %             end
        end
    elseif strcmp(directions,'pause')
        % all stimuli using pause duration to vary the dutycycle will
        % keep the same pulse duration (which is the pulse dur set with the
        % minimum dutycycle, 25%)
        pause_dur = (min_pulse/dutycycle)-min_pulse;
        pulsepluspause = min_pulse+pause_dur;
        AM_signal((min_pulse/2)*samprate:(ceil(pulsepluspause*samprate)):ceil(length(AM_signal)-(min_pulse/2)*samprate)) = 1;
    end
    
    filtwindow = min_pulse*samprate; % for all duty cycle stimuli, the filter window
    % will be the size of the shortest pulse
    AM_sigfilt = hanningsmooth(AM_signal,filtwindow);
    norm_factor = 1/max(AM_sigfilt);
    AM_sigfiltnorm = AM_sigfilt*norm_factor;
    if length(AM_sigfiltnorm)~=stimdur*samprate
        signal_diff = length(AM_sigfiltnorm)-(stimdur*samprate);
        if signal_diff==1
            AM_sigfiltnorm(end) = [];
        elseif signal_diff>1
            disp('signal length is more than 2 indices too long');
        end
    end
    AM_signal = AM_sigfiltnorm.*sin(2*pi*fc*t);
    figure; plot(AM_signal);
end