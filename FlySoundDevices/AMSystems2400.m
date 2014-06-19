classdef AMSystems2400 < Device
    
    properties (Constant)
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
        function obj = AMSystems2400(varargin)
            obj = obj@Device(varargin{:});
            obj.deviceName = 'AMSystems2400';

            % This and the transformInputs function are hard coded
            obj.inputLabels = {'scaled','current','voltage'};
            obj.inputUnits = {'mV','pA','mV'};
            obj.inputPorts = [6,7,16];
            obj.outputLabels = {'scaled'};
            obj.outputUnits = {'pA'};
            obj.outputPorts = 1;

            obj.setModeSession;
            obj.mode = 'VClamp';
            obj.getmode;
            obj.setGainSession;
            obj.getgain;
            obj.gain = 1;
        end
        
        function varargout = transformOutputs(obj,out)
            outlabels = fieldnames(out);
            for ol = 1:length(outlabels)
                if strcmp(outlabels{ol},'voltage')
                    if sum(strcmp({'IClamp','IClamp_fast'},obj.mode))
                        %warning('In Current Clamp - removing current stim')
                        out = rmfield(out,'voltage');
                    else
                        obj.outputLabels{1} = 'voltage';
                        obj.outputUnits{1} = 'mV';
                        out.voltage = out.voltage/1000;  % mV, convert, this is the desired V injected
                        out.voltage = (out.voltage - obj.params.daqout_to_voltage_offset)/obj.params.daqout_to_voltage;
                        units.voltage = 'mV';
                    end
                end
                if strcmp(outlabels{ol},'current')
                    if sum(strcmp('VClamp',obj.mode))
                        %warning('In Voltage Clamp - removing current stim')
                        out = rmfield(out,'current');
                    else
                        obj.outputLabels{1} = 'current';
                        obj.outputUnits{1} = 'pA';
                        out.current = (out.current - obj.params.daqout_to_current_offset)/obj.params.daqout_to_current;
                        DAQ_V_to_subtract_static_current = obj.params.daqCurrentOffset/obj.params.daqout_to_current;
                        out.current = out.current - DAQ_V_to_subtract_static_current;
                        units.current = 'pA';
                    end
                end
            end
            if isempty(fieldnames(out))
                notify(obj,'BadMode');
                error('Amplifier in %s mode - No appropriate output',obj.mode);
            end
            varargout = {out};
        end
        
        function varargout = transformInputs(obj,inputstruct)
            inlabels = fieldnames(inputstruct);
            units = {};
            for il = 1:length(inlabels)
                switch inlabels{il}
                    case 'voltage'
                        if sum(strcmp({'IClamp','IClamp_fast'},obj.mode))
                            obj.inputLabels{1} = 'voltage';
                            obj.inputUnits{1} = 'mV';
                            inputstruct.voltage = (inputstruct.(inlabels{il})-obj.params.scaledvoltageoffset)*obj.params.scaledvoltagescale_timesgain/obj.gain * 1000;
                        else
                            inputstruct.voltage = (inputstruct.(inlabels{il})-obj.params.hardvoltageoffset)*obj.params.hardvoltagescale * 1000;
                        end
                        units{il} = 'mV'; 
                    case 'current'
                        if sum(strcmp('VClamp',obj.mode))
                            obj.inputLabels{1} = 'current';
                            obj.inputUnits{1} = 'pA';
                            inputstruct.current = (inputstruct.(inlabels{il})-obj.params.scaledcurrentoffset)*obj.params.scaledcurrentscale_timesgain/obj.gain * 1000;
                        else
                            inputstruct.(inlabels{il}) = (inputstruct.(inlabels{il})-obj.params.hardcurrentoffset)*obj.params.hardcurrentscale * 1000;
                        end
                        units{il} = 'pA';
                end
            end
            varargout = {inputstruct,units};
        end
        
        function setModeSession(obj)
            modeDev = getpref('AcquisitionHardware','modeDev');
            obj.modeSession = daq.createSession('ni');
            obj.modeSession.addAnalogInputChannel(modeDev,17, 'Voltage');
            obj.modeSession.Channels(1).TerminalConfig = 'SingleEndedNonReferenced';
            obj.modeSession.Rate = 100000;  % 100 kHz
            obj.modeSession.DurationInSeconds = .001; 
        end
        
        function setGainSession(obj)
            gainDev = getpref('AcquisitionHardware','gainDev');
            obj.gainSession = daq.createSession('ni');
            obj.gainSession.addAnalogInputChannel(gainDev,18, 'Voltage');
            obj.gainSession.Rate = 100000;  % 100 kHz
            obj.gainSession.DurationInSeconds = .001; 
        end
        
        function newmode = getmode(obj)
            % [voltage,current] = readGain(recMode, durSweep, samprate)
            mode_voltage = obj.modeSession.startForeground; %plot(x); drawnow
            mode_voltage1 = mean(mode_voltage);
            pause(.01)
            mode_voltage = obj.modeSession.startForeground; %plot(x); drawnow
            mode_voltage2 = mean(mode_voltage);
            while abs(mode_voltage2-mode_voltage1)>0.01
                mode_voltage1 = mode_voltage2;
                mode_voltage = obj.modeSession.startForeground; %plot(x); drawnow
                mode_voltage2 = mean(mode_voltage);
            end
                
            if mode_voltage2 < 1
                newmode = 'Vtest';
            elseif mode_voltage2 < 2
                newmode = 'VClamp'; % Vcomp, test pulse ignored
            elseif mode_voltage2 < 3
                newmode = 'VClamp';
            elseif mode_voltage2 < 4
                newmode = 'I=0';
            elseif mode_voltage2 < 5
                newmode = 'IClamp';
            elseif mode_voltage2 < 6
                newmode = 'IClamp'; % Iresist, test pulse ignored
            elseif mode_voltage2 < 7
                newmode = 'IClamp'; % Ifollow, test pulse ignored
            end
            
            if sum(strcmp('VClamp',newmode))
                    obj.outputLabels{1} = 'voltage';
                    obj.outputUnits{1} = 'mV';
                    obj.inputLabels{1} = 'current';
                    obj.inputUnits{1} = 'pA';
            elseif sum(strcmp({'IClamp'},newmode)) 
                    obj.outputLabels{1} = 'current';
                    obj.outputUnits{1} = 'pA';
                    obj.inputLabels{1} = 'voltage';
                    obj.inputUnits{1} = 'mV';
            end
            oldmode = obj.mode;
            obj.mode = newmode;
            if ~strcmp(obj.mode,oldmode)
                notify(obj,'ModeChange');
            end
            
            
        end
        
        function newgain = getgain(obj)
            % [voltage,current] = readGain(recMode, durSweep, samprate)
            
            gain_voltage = obj.gainSession.startForeground; %plot(x); drawnow
            gain_voltage1 = mean(gain_voltage);
            pause(.01)
            gain_voltage = obj.gainSession.startForeground; %plot(x); drawnow
            gain_voltage2 = mean(gain_voltage);
            while abs(gain_voltage2-gain_voltage1)>0.01
                gain_voltage1 = gain_voltage2;
                gain_voltage = obj.gainSession.startForeground; %plot(x); drawnow
                gain_voltage2 = mean(gain_voltage);
            end
            
            mode_voltage = obj.modeSession.startForeground; %plot(x); drawnow
            mode_voltage2 = mean(mode_voltage);
            
            if mode_voltage2 < 2.7
                gain_voltage2 = gain_voltage2+1.5;
            end
            
            if gain_voltage2 < 3.2
                newgain = 1;
            elseif gain_voltage2 < 3.7
                newgain = 2;
            elseif gain_voltage2 < 4.2
                newgain = 5;
            elseif gain_voltage2 < 4.7
                newgain = 10;
            elseif gain_voltage2 < 5.2
                newgain = 20;
            elseif gain_voltage2 < 5.7
                newgain = 50;
            elseif gain_voltage2 < 6.2
                newgain = 100;
            end
            obj.gain = newgain;
        end
                
    end
    
    methods (Access = protected)
                
        function defineParameters(obj)
            % create an amplifier class that implements these
            % http://www.a-msystems.com/pub/manuals/2400manual.pdf page 42
            obj.params.filter = 1e4;
            obj.params.headstageresistor = 100;
            obj.params.headstagegain = 1/10; %low
            % obj.params.headstagegain = 1/100; %high
            obj.params.extcmdswitch = 1/10; 
            % obj.params.extcmdswitch = 1/50;
            
            obj.params.daqCurrentOffset = 0.0000; 
            obj.params.daqout_to_current = obj.params.headstagegain*obj.params.headstageresistor*100; % nA/V, multiply DAQ voltage to get nA injected
            obj.params.daqout_to_current_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            obj.params.daqout_to_voltage = obj.params.extcmdswitch; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            obj.params.daqout_to_voltage_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            obj.params.hardcurrentscale = 1000 / 1000; % [mV]/[nA] - [V daq]*1000 / ([mV]/[nA])  -  1000 [pA]/[nA] in code;
            obj.params.hardcurrentoffset = -8.6716/1000; 
            obj.params.hardvoltagescale = 1/(10); % reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            obj.params.hardvoltageoffset = -7.374/1000; % in V, reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            
            obj.params.scaledcurrentscale_timesgain = obj.params.hardcurrentscale*10; % [mV/V]/gainsetting gives pA
            obj.params.scaledcurrentoffset = -6.898/1000; % [mV/V]/gainsetting gives pA
            obj.params.scaledvoltagescale_timesgain = 1; % mV/gainsetting gives mV
            obj.params.scaledvoltageoffset = -7.1479/1000 + -17.1563/1000/50; % mV/gainsetting gives mV
        end
    end
end
