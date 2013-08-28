classdef Amplifier < Device
    
    properties (Constant)
        deviceName = 'Amplifier';
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        mode
        gain
    end

    properties (Hidden, SetAccess = protected)
        modeSession
        gainSession
    end

    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = Amplifier(varargin)
            % This and the transformInputs function are hard coded
            obj.inputLabels = {'scaled','current','voltage'};
            obj.inputUnits = {'mV','pA','mV'};
            obj.inputPorts = [0,3,4];
            obj.outputLabels = {'scaled'};
            obj.outputUnits = {'pA'};
            obj.outputPorts = 0;

            obj.setModeSession;
            obj.getmode;
            obj.setGainSession;
            obj.getgain;

            obj.createDeviceParameters();
        end
        
        function varargout = transformOutputs(obj,out)
            outlabels = fieldnames(out);
            for ol = 1:length(outlabels)
                port = obj.outputPorts(strcmp(obj.outputLabels,outlabels{ol}));
                if length(port) == 2
                    port = port(1);
                end
                if ~isempty(port)
                    switch port
                        case 0
                            switch obj.mode
                                case 'VClamp'
                                    obj.outputLabels{1} = 'voltage';
                                    obj.outputUnits{1} = 'mV';
                                    out.(outlabels{ol}) = obj.stim/1000;  % mV, convert, this is the desired V injected
                                    out.(outlabels{ol}) = (out.(outlabels{ol}) - obj.params.daqout_to_voltage_offset)/obj.params.daqout_to_voltage;
                                    units.(outlabels{ol}) = 'mV';
                                case 'IClamp'
                                    obj.outputLabels{1} = 'current';
                                    obj.outputUnits{1} = 'pA';
                                    out.(outlabels{ol}) = (out.(outlabels{ol})-obj.params.daqout_to_current_offset)/obj.params.daqout_to_current;
                                    DAQ_V_to_subtract_static_current = obj.params.daqCurrentOffset/obj.params.daqout_to_current;
                                    out.(outlabels{ol}) = out.(outlabels{ol}) - DAQ_V_to_subtract_static_current;
                                    units.(outlabels{ol}) = 'pA';
                                case 'IClamp_fast'
                                    obj.outputLabels{1} = 'current';
                                    obj.outputUnits{1} = 'pA';
                                    out.(outlabels{ol}) = (out.(outlabels{ol})-obj.params.daqout_to_current_offset)/obj.params.daqout_to_current;
                                    DAQ_V_to_subtract_static_current = obj.params.daqCurrentOffset/obj.params.daqout_to_current;
                                    out.(outlabels{ol}) = out.(outlabels{ol}) - DAQ_V_to_subtract_static_current;
                                    units.(outlabels{ol}) = 'pA';
                            end
                    end
                end
            end
            varargout = {out,units};
        end
        
        function varargout = transformInputs(obj,inputstruct)
            inlabels = fieldnames(inputstruct);
            for il = 1:length(inlabels)
                port = obj.inputPorts(strcmp(obj.inputLabels,inlabels{il}));
                if length(port) == 2
                    port = port(1);
                end
                if ~isempty(port)
                    switch port
                        case 0
                            switch obj.mode
                                case 'VClamp'
                                    obj.inputLabels{1} = 'current';
                                    obj.inputUnits{1} = 'pA';
                                    inputstruct.(inlabels{il}) = (inputstruct.(inlabels{il})-obj.params.scaledcurrentoffset)*obj.params.scaledcurrentscale;
                                case 'IClamp'
                                    obj.inputLabels{1} = 'voltage';
                                    obj.inputUnits{1} = 'mV';
                                    inputstruct.(inlabels{il}) = (inputstruct.(inlabels{il})-obj.params.scaledvoltageoffset)*obj.params.scaledvoltagescale;
                                case 'IClamp_fast'
                                    obj.inputLabels{1} = 'voltage';
                                    obj.inputUnits{1} = 'mV';
                                    inputstruct.(inlabels{il}) = (inputstruct.(inlabels{il})-obj.params.scaledvoltageoffset)*obj.params.scaledvoltagescale;
                            end
                        case 1
                        case 2
                        case 3
                            inputstruct.(inlabels{il}) = (inputstruct.(inlabels{il})-obj.params.hardcurrentoffset)*obj.params.hardcurrentscale * 1000;
                        case 4
                            inputstruct.(inlabels{il}) = (inputstruct.(inlabels{il})-obj.params.hardvoltageoffset)*obj.params.hardvoltagescale * 1000;
                    end
                end
            end
            varargout = {inputstruct,units};
        end
        
        function setModeSession(obj)
            obj.modeSession = daq.createSession('ni');
            obj.modeSession.addAnalogInputChannel('Dev1',2, 'Voltage');
            obj.modeSession.Channels(1).TerminalConfig = 'SingleEndedNonReferenced';
            obj.modeSession.Rate = 10000;  % 10 kHz
            obj.modeSession.DurationInSeconds = .01; % 2ms
        end
        
        function setGainSession(obj)
            obj.gainSession = daq.createSession('ni');
            obj.gainSession.addAnalogInputChannel('Dev1',1, 'Voltage');
            obj.gainSession.Rate = 10000;  % 10 kHz
            obj.gainSession.DurationInSeconds = .02; % 2ms
        end
        
        function newmode = getmode(obj)
            % [voltage,current] = readGain(recMode, durSweep, samprate)
            mode_voltage = obj.modeSession.startForeground; %plot(x); drawnow
            mode_voltage = mean(mode_voltage);
            
            if mode_voltage < 1.75
                newmode = 'IClamp_fast';
            elseif mode_voltage < 2.75
                newmode = 'IClamp';
            elseif mode_voltage < 3.75
                newmode = 'I=0';
            elseif mode_voltage < 4.75
                newmode = 'Track';
            elseif mode_voltage < 6.75
                newmode = 'VClamp';
            end
            obj.mode = newmode;
            
            switch obj.mode
                case 'VClamp'
                    obj.outputLabels{1} = 'voltage';
                    obj.outputUnits{1} = 'mV';
                    obj.inputLabels{1} = 'current';
                    obj.inputUnits{1} = 'pA';
                case 'IClamp'
                    obj.outputLabels{1} = 'current';
                    obj.outputUnits{1} = 'pA';
                    obj.inputLabels{1} = 'voltage';
                    obj.inputUnits{1} = 'mV';
                case 'IClamp_fast'
                    obj.outputLabels{1} = 'current';
                    obj.outputUnits{1} = 'pA';
                    obj.inputLabels{1} = 'voltage';
                    obj.inputUnits{1} = 'mV';
            end

        end
        function newgain = getgain(obj)
            % [voltage,current] = readGain(recMode, durSweep, samprate)
            
            gain_voltage = obj.gainSession.startForeground; %plot(x); drawnow
            gain_voltage = mean(gain_voltage);
            
            if gain_voltage < 2.2
                newgain = 0.5;
            elseif gain_voltage < 2.7
                newgain = 1;
            elseif gain_voltage < 3.2
                newgain = 2;
            elseif gain_voltage < 3.7
                newgain = 5;
            elseif gain_voltage < 4.2
                newgain = 10;
            elseif gain_voltage < 4.7
                newgain = 20;
            elseif gain_voltage < 5.2
                newgain = 50;
            elseif gain_voltage < 5.7
                newgain = 100;
            elseif gain_voltage < 6.2
                newgain = 200;
            elseif gain_voltage < 6.7
                newgain = 500;
            end
            obj.gain = newgain;
        end
                
    end
    
    methods (Access = protected)
                
        function createDeviceParameters(obj)
            % create an amplifier class that implements these
            % dbp.recgain = readGain();
            % dbp.recmode = readMode();
            dbp.filter = 1e4;
            dbp.headstagegain = 1;
            
            dbp.daqCurrentOffset = 0.0000; % 0.006; %nA There is some current offset when Vdaq = 0
            % to get this number, run  the zeroDAQOut routine and mess with
            % ext_offset
            
            % Current Injection = DAQ_voltage*m+b
            % DAQ_out_voltage = (nA-b)/m;  % to get these numbers, run the
            % currentInputCalibration routine
            dbp.daqout_to_current = 2/dbp.headstagegain; % m, multiply DAQ voltage to get nA injected
            dbp.daqout_to_current_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            dbp.daqout_to_voltage = .02; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            dbp.daqout_to_voltage_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            dbp.rearcurrentswitchval = 1; % [V/nA];
            dbp.hardcurrentscale = 1/(dbp.rearcurrentswitchval*dbp.headstagegain); % [V]/current scal gives nA;
            dbp.hardcurrentoffset = -6.6238/1000;
            dbp.hardvoltagescale = 1/(10); % reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            dbp.hardvoltageoffset = -6.2589/1000; % in V, reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            
            dbp.scaledcurrentscale = 1000/(obj.gain*dbp.headstagegain); % [mV/V]/gainsetting gives pA
            dbp.scaledcurrentoffset = 0; % [mV/V]/gainsetting gives pA
            dbp.scaledvoltagescale = 1000/(obj.gain); % mV/gainsetting gives mV
            dbp.scaledvoltageoffset = 0; % mV/gainsetting gives mV
            
            obj.params = dbp;
        end
    end
end
