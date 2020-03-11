classdef AxoPatch200B_EMG < Device
    
    properties 
        deviceName = 'AxoPatch200B_EMG';
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end

    properties (Hidden, SetAccess = protected)
        modeSession
        gainSession
    end

    
    events
        BadMode
        ModeChange
    end
    
    methods
        function obj = AxoPatch200B_EMG(varargin)
            obj = obj@Device(varargin{:});
            
            % This and the transformInputs function are hard coded
            % Currently using the AxoPatch as the extensor EMG, 
            % NO NEED FOR OUTPUTS
            obj.inputLabels = {'scaled'}; % ,'current','voltage'};
            obj.inputUnits = {'mV'}; %,'pA','mV'};
            obj.inputPorts = 16;

            % obj.setModeSession; % Currently does nothing
            obj.setmode('VClamp');
            % obj.getmode;
            % obj.setGainSession; % Currently does nothing
            obj.setgain(10);
            % obj.gain = 10;
        end
        
        function varargout = transformOutputs(obj,out,varargin)
            outlabels = fieldnames(out);
            for ol = 1:length(outlabels)
                % Do this only if the Device cares about this outlabel
                if ismember(obj.outputLabels,outlabels{ol})
                    %% There are currently no outputs. Don't run this
                    
                    % if ~isempty(strfind(outlabels{ol},'voltage'))
                    %     if sum(strcmp({'IClamp','IClamp_fast'},obj.mode))
                    %         %warning('In Current Clamp - removing current stim')
                    %         out = rmfield(out,'voltage');
                    %     else
                    %         obj.outputLabels{1} = 'voltage';
                    %         obj.outputUnits{1} = 'mV';
                    %         out.voltage = out.voltage/1000;  % mV, convert, this is the desired V injected
                    %         out.voltage = (out.voltage - obj.params.daqout_to_voltage_offset)/obj.params.daqout_to_voltage;
                    %         units.voltage = 'mV';
                    %     end
                    % end
                    % if ~isempty(strfind(outlabels{ol},'current'))
                    %     if sum(strcmp('VClamp',obj.mode))
                    %         %warning('In Voltage Clamp - removing current stim')
                    %         out = rmfield(out,'current');
                    %     else
                    %         obj.outputLabels{1} = regexprep('current';
                    %         obj.outputUnits{1} = 'pA';
                    %         out.current = (out.current - obj.params.daqout_to_current_offset)/obj.params.daqout_to_current;
                    %         DAQ_V_to_subtract_static_current = obj.params.daqCurrentOffset/obj.params.daqout_to_current;
                    %         out.current = out.current - DAQ_V_to_subtract_static_current;
                    %         units.current = 'pA';
                    %     end
                    % end
                end
            end
            %             if isempty(fieldnames(out))
            %                 notify(obj,'BadMode');
            %                 error('Amplifier in %s mode - No appropriate output',obj.mode);
            %             end
            varargout = {out};
        end
        
        function varargout = transformInputs(obj,inputstruct)
            inlabels = fieldnames(inputstruct);
            units = {};
            for il = 1:length(inlabels)
                switch inlabels{il}
                    case 'voltage_extEMG'
                        if sum(strcmp({'IClamp','IClamp_fast'},obj.mode))
                            obj.inputLabels{1} = 'voltage_extEMG';
                            obj.inputUnits{1} = 'mV';
                            inputstruct.voltage_extEMG = (inputstruct.(inlabels{il})-obj.params.scaledvoltageoffset)*obj.params.scaledvoltagescale_timesgain/obj.gain;
                        else
                            inputstruct.voltage_extEMG = (inputstruct.(inlabels{il})-obj.params.hardvoltageoffset)*obj.params.hardvoltagescale * 1000;
                        end
                        units{il} = 'mV'; 
                    case 'current_extEMG'
                        if sum(strcmp('VClamp',obj.mode))
                            obj.inputLabels{1} = 'current_extEMG';
                            obj.inputUnits{1} = 'pA';
                            inputstruct.current_extEMG = (inputstruct.(inlabels{il})-obj.params.scaledcurrentoffset)*obj.params.scaledcurrentscale_timesgain/obj.gain;
                        else
                            inputstruct.(inlabels{il}) = (inputstruct.(inlabels{il})-obj.params.hardcurrentoffset)*obj.params.hardcurrentscale * 1000;
                        end
                        units{il} = 'pA';
                end
            end
            varargout = {inputstruct,units};
        end
        
        function setModeSession(obj)
            % Currently, using only a single daq for this. I could use the
            % second (piezo) daq, but I think that's unwise.
            % so this method is empty
            
            % modeDev = getacqpref('AcquisitionHardware','modeDev');
            % obj.modeSession = daq.createSession('ni');
            % obj.modeSession.addAnalogInputChannel(modeDev,17, 'Voltage');
            % obj.modeSession.Channels(1).TerminalConfig = 'SingleEndedNonReferenced';
            % obj.modeSession.Rate = 10000;  % 10 kHz
            % obj.modeSession.DurationInSeconds = .01; % 2ms
        end
        
        function setGainSession(obj)
            % Currently, using only a single daq for this. I could use the
            % second (piezo) daq, but I think that's unwise.
            % so this method is empty
            
            % gainDev = getacqpref('AcquisitionHardware','gainDev');
            % obj.gainSession = daq.createSession('ni');
            % obj.gainSession.addAnalogInputChannel(gainDev,18, 'Voltage');
            % obj.modeSession.Channels(1).TerminalConfig = 'SingleEnded';
            % obj.gainSession.Rate = 10000;  % 10 kHz
            % obj.gainSession.DurationInSeconds = .02; % 2ms
        end
        
        function setmode(obj,newmode)
            if ~contains({'IClamp_fast','IClamp','I=0','VClamp'},newmode)
                error('Unknown mode: %s',newmode);
            else
                setacqpref('AxoPatch200B_EMG','mode',newmode);
                obj.getmode();
            end
        end
        
        function setgain(obj,newgain)
            if ~any([1,2,5,10,20,50,100,200,500],newgain)
                error('Unknown gain: %d',newgain);
            else
                setacqpref('AxoPatch200B_EMG','gain',newgain);
                obj.getgain();
            end
        end

        
        function newmode = getmode(obj)
            % Shortcut, no session.
            newmode = getacqpref('AxoPatch200B_EMG','mode');
            ntfy = 0;
            if ~strcmp(newmode,obj.mode)
                ntfy = 1;
            end
            obj.mode = newmode;
            if ntfy
                % not sure how this could happen
                notify(obj,'ModeChange');
            end

            % % [voltage,current] = readGain(recMode, durSweep, samprate)
            % mode_voltage = obj.modeSession.startForeground; %plot(x); drawnow
            % mode_voltage = mean(mode_voltage);
            %
            % if mode_voltage < 1.75
            % newmode = 'IClamp_fast';
            % elseif mode_voltage < 2.75
            % newmode = 'IClamp';
            % elseif mode_voltage < 3.75
            % newmode = 'I=0';
            % elseif mode_voltage < 4.75
            % newmode = 'Track';
            % elseif mode_voltage < 6.75
            % newmode = 'VClamp';
            % end
            % obj.mode = newmode;
            %
            if sum(strcmp('VClamp',obj.mode))
            %                     obj.outputLabels{1} = 'voltage';
            %                     obj.outputUnits{1} = 'mV';
                obj.inputLabels{1} = 'current_extEMG';
                obj.inputUnits{1} = 'pA';
            elseif sum(strcmp({'IClamp','IClamp_fast'},obj.mode))
            %                     obj.outputLabels{1} = 'current';
            %                     obj.outputUnits{1} = 'pA';
                obj.inputLabels{1} = 'voltage_extEMG';
                obj.inputUnits{1} = 'mV';
            end
            % notify(obj,'ModeChange');
        end
        function newgain = getgain(obj)
            % Shortcut, no session.
            newgain = getacqpref('AxoPatch200B_EMG','gain');
            obj.gain = newgain;
            
            % % [voltage,current] = readGain(recMode, durSweep, samprate)
            %
            % gain_voltage = obj.gainSession.startForeground; %plot(x); drawnow
            % gain_voltage = mean(gain_voltage);
            %
            % if gain_voltage < 2.2
            %     newgain = 0.5;
            % elseif gain_voltage < 2.7
            %     newgain = 1;
            % elseif gain_voltage < 3.2
            %     newgain = 2;
            % elseif gain_voltage < 3.7
            %     newgain = 5;
            % elseif gain_voltage < 4.2
            %     newgain = 10;
            % elseif gain_voltage < 4.7
            %     newgain = 20;
            % elseif gain_voltage < 5.2
            %     newgain = 50;
            % elseif gain_voltage < 5.7
            %     newgain = 100;
            % elseif gain_voltage < 6.2
            %     newgain = 200;
            % elseif gain_voltage < 6.7
            %     newgain = 500;
            % end
            % obj.gain = newgain;
        end
                
    end
    
    methods (Access = protected)
                
        function setupDevice(obj)
            %             cursensitivity = obj.params.headstagegain/obj.params.headstageresistorCC*1e12; % pA/V
            %             obj.params.daqout_to_current = 1/cursensitivity; % nA/V, multiply DAQ voltage to get nA injected
            %
            %             obj.params.daqout_to_voltage = 1/obj.params.cmdsensitivity; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            %
            %             obj.params.scaledcurrentscale_over_gainVC = 1e-12*obj.params.headstageresistorVC; % [V/pA] * gainsetting
            %             obj.params.scaledcurrentscale_over_gainCC = 1e-12*obj.params.headstageresistorCC; % [V/pA] * gainsetting
        end
        
        
        function defineParameters(obj)
            % create an amplifier class that implements these
            obj.params.filter = 1e4;
            obj.params.headstagegain = 1;
            
            obj.params.daqCurrentOffset = 0.0000; 
            obj.params.daqout_to_current = 2/obj.params.headstagegain; % m, multiply DAQ voltage to get nA injected
            obj.params.daqout_to_current_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            obj.params.daqout_to_voltage = .02; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            obj.params.daqout_to_voltage_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            obj.params.rearcurrentswitchval = 1; % [V/nA];
            obj.params.hardcurrentscale = 1/(obj.params.rearcurrentswitchval*obj.params.headstagegain); % [V]/current scal gives nA;
            obj.params.hardcurrentoffset = -6.6238/1000;
            obj.params.hardvoltagescale = 1/(10); % reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            obj.params.hardvoltageoffset = -6.2589/1000; % in V, reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            
            obj.params.scaledcurrentscale_timesgain = 1000/(obj.params.headstagegain); % [mV/V]/gainsetting gives pA
            obj.params.scaledcurrentoffset = 0; % [mV/V]/gainsetting gives pA
            obj.params.scaledvoltagescale_timesgain = 1000; % mV/gainsetting gives mV
            obj.params.scaledvoltageoffset = 0; % mV/gainsetting gives mV
        end
    end
end
