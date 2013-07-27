classdef SealAndLeak < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'SealAndLeak';
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
        
        function obj = SealAndLeak(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end

        function varargout = generateStimulus(obj,varargin)
            stim = obj.stim/1000;  % mV, convert, this is the desired V injected
            stim = (stim - obj.dataBoilerPlate.daqout_to_voltage_offset)/obj.dataBoilerPlate.daqout_to_voltage; 
            varargout = {stim,obj.x};
        end
        
        function run(obj,varargin)
            trialdata = runtimeParameters(obj,varargin{:});
            if ~strcmp(readMode(),'VClamp')
                error('Not in current clamp (VClamp)');
            end
            obj.writePrologueNotes()

            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;

            obj.aoSession.Rate = trialdata.samprateout;

            stim = nan(length(obj.generateStimulus()),length((obj.aoSession.Channels)));
            voltage = nan(size(obj.x));
            current = nan(size(obj.x));
            for repeat = 1:trialdata.repeats

                obj.writeTrialNotes();
                
                stim(:,1) = obj.generateStimulus();
                obj.aoSession.wait;

                obj.aoSession.queueOutputData(stim)                
                obj.aoSession.startBackground; % Start the session that receives start trigger first
                obj.y = obj.aiSession.startForeground; % both amp and signal monitor input
                if size(obj.y,1)~= length(obj.x)
                    obj.y = obj.y(2:1+length(obj.x),:);
                else
                    warning('***** vectors are same length!  aiSession produces variable input sizes')
                end
                current(:) = obj.y(:,1);
                voltage(:) = obj.y(:,3);
                
                % apply scaling factors
                current = (current-trialdata.scaledcurrentoffset)*trialdata.scaledcurrentscale;
                % Note: collecting hard voltage here, not scaled
                % current
                voltage = voltage*trialdata.hardvoltagescale - trialdata.hardvoltageoffset; % in V
                voltage = voltage*1000;
                
                obj.y(:,1) = current;
                obj.y(:,3) = voltage; % 'pA'

                obj.saveData(trialdata,current,voltage) % TODO: save signal monitor                
                obj.displayTrial()
            end
        end
                
        function displayTrial(obj)
            figure(1);
            redlines = findobj(1,'Color',[1, 0, 0]);
            set(redlines,'color',[1 .8 .8]);
            bluelines = findobj(1,'Color',[0, 0, 1]);
            set(bluelines,'color',[.8 .8 1]);
            greylines = findobj(1,'Color',[.6 .6 .6]);
            set(greylines,'color',[.8 .8 .8]);
            pinklines = findobj(1,'Color',[.5 1 1]);
            set(pinklines,'color',[.8 .8 .8]);
            
            % number of samples in a pulse
            % chop y down
            ppnts = obj.params.stepdur*obj.params.samprateout;
            stimx = obj.stimx(ppnts+1:end);
            % stimx = reshape(stimx,2*ppnts,obj.params.pulses);
            stimx = stimx(1:2*ppnts);
            x = obj.x(ppnts+1:end);
            % stimx = reshape(stimx,2*ppnts,obj.params.pulses);
            x = x(1:2*ppnts);
            
            stim = obj.stim;
            stim = stim(ppnts+1:end);
            %stim = reshape(stim,2*ppnts,obj.params.pulses);
            stim = stim(1:2*ppnts);

            y = obj.y(:,1);
            base = mean(y(1:ppnts));
            y = y(ppnts+1:end);
            y = reshape(y,2*ppnts,obj.params.pulses);
            
            y_bar = mean(y,2) - base;

            % R = V/I(at end of step);
            sealRes_Est1 = obj.params.stepamp/1000 / (y_bar(ppnts)*1e-12);
            
            start = x(10);
            finit = x(ppnts); %s
            pulse_t = x(x>start & x<finit);
            % TODO: handle the warnings
            Icoeff = nlinfit(...
                pulse_t - pulse_t(1),...
                y_bar(x>start & x<finit),...
                @exponential,...
                [max(y_bar)/3,max(y_bar),obj.params.stepdur]);
            RCcoeff = Icoeff; RCcoeff(1:2) = obj.params.stepamp/1000 ./(RCcoeff(1:2)*1e-12); % 5 mV step/I_i or I_f

            sealRes_Est2 = RCcoeff(1);
            % print dlg button reminding to write the value on the checklist in the lab notebook, or the form or in the google sheet.
            
            ax1 = subplot(3,1,3);
            line(stimx,stim,'parent',ax1,'color',[0 0 1],'linewidth',1);
            box off; set(gca,'TickDir','out');
            xlabel('Time (s)'); xlim([stimx(1) stimx(end)]);
            ylabel('mV'); %xlim([0 max(t)]);
            
            ax2 = subplot(3,1,[1 2]);
            plot(x,y,'parent',ax2,'color',[1 .7 .7],'linewidth',1); hold on
            line(x,y_bar+base,'parent',ax2,'color',[.7 0 0],'linewidth',1);
            line(x(x>start & x<finit),...
                exponential(Icoeff,pulse_t-pulse_t(1))+base,...
                'color',[0 1 1],'linewidth',1);

            box off; set(gca,'TickDir','out');
            xlabel('Time (s)'); xlim([stimx(1) stimx(end)]);
            ylabel('pA'); %xlim([0 max(t)]);
                        
            % write the value in the comments, make a guess based on value
            % whether it's electrode, seal, CA, whole cell resistance, just
            % for a checks
            if sealRes_Est2<100e6
                guess = '''trode';
            elseif sealRes_Est2<100e6
                guess = 'Cell-Attached';
            elseif sealRes_Est2<4e9
                guess = 'Whole-Cell';                
            else
                guess = 'Seal';                                
            end
            
            str = sprintf('R (ohms): \n\test 1 (step end) = %.2e; \n\test 2 (exp fit) = %.2e; \n\tGuessing: %s',...
                sealRes_Est1,...
                sealRes_Est2,...
                guess);
            obj.comment(str);
            obj.comment(sprintf('Ri=%.2e, Rs=%.2e, Cm = %.2e',RCcoeff(1),RCcoeff(2),RCcoeff(3)/RCcoeff(2)));
            msgbox(str);
        end

    end % methods
    
    methods (Access = protected)
                        
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage'); % from amp
            obj.aiSession.addAnalogInputChannel('Dev1',3, 'Voltage'); % from amp
            obj.aiSession.addAnalogInputChannel('Dev1',4, 'Voltage'); % Voltage
            
            % configure AO
            obj.aoSession = daq.createSession('ni');
            obj.aoSession.addAnalogOutputChannel('Dev1',0, 'Voltage'); % Output channel
            
            obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
            obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
        end

        function createDataStructBoilerPlate(obj)
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?            
            createDataStructBoilerPlate@FlySoundProtocol(obj);
        end
        
        function defineParameters(obj)
            obj.params.sampratein = 100000;
            obj.params.samprateout = 100000;
            obj.params.stepamp = 5; %mV;
            obj.params.stepdur = .0167; %sec;
            obj.params.pulses = 20;
            %             obj.params.stimDurInSec = 2;
            %             obj.params.preDurInSec = .5;
            %             obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses+2);
            
            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses+1);
            obj.stimx = (1:obj.params.samprateout*obj.params.durSweep)/obj.params.samprateout;
            obj.stimx = obj.stimx(:);
            
            stim = zeros(2*obj.params.pulses+1,obj.params.stepdur*obj.params.samprateout);
            stim(2:2:2*obj.params.pulses,:) = 1;
            stim = stim';
            stim = stim(:);
            
            obj.stim = stim * obj.params.stepamp;            
            obj.x = (1:obj.params.sampratein*obj.params.durSweep)/obj.params.sampratein;
            obj.x = obj.x(:);
            obj.y = obj.x;
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