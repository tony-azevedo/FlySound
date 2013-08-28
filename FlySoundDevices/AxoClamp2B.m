classdef AxoClamp2B < Amplifier
    
    properties (Constant)
        deviceName = 'AxoClamp2B';
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end

    properties (Hidden, SetAccess = protected)
    end

    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = AxoClamp2B(varargin)
            % This and the transformInputs function are hard coded
            obj.setModeSession;
            obj.getmode;
            obj.setGainSession;
            obj.getgain;

            obj.createDeviceParameters();

            obj.inputLabels = {'current','voltage'};
            obj.inputUnits = {'mV','pA'};
            obj.inputPorts = [0,1,2,3,4];
            obj.outputLabels = {'scaled'};
            obj.outputUnits = {'pA'};
            obj.outputPorts = 0;
        end
        
        function scaledinputs = transformInputs(obj,varargin)
            [inputs,ports] = obj.parseInputs(varargin{:});
            scaledinputs = inputs;
            for p = 1:length(ports)
                switch ports(p)
                    case 0
                        switch obj.recmode
                            case 'VClamp'
                                obj.inputLabels{1} = 'current';
                                obj.inputUnits{1} = 'pA';
                                scaledinputs(:,p) = (inputs(:,p)-obj.params.scaledcurrentoffset)*obj.params.scaledcurrentscale;
                            case 'IClamp'
                                obj.inputLabels{1} = 'voltage';
                                obj.inputUnits{1} = 'mV';
                                scaledinputs(:,p) = (inputs(:,p)-obj.params.scaledvoltageoffset)*obj.params.scaledvoltagescale;
                            case 'IClamp_fast'
                                obj.inputLabels{1} = 'voltage';
                                obj.inputUnits{1} = 'mV';
                                scaledinputs(:,p) = (inputs(:,p)-obj.params.scaledvoltageoffset)*obj.params.scaledvoltagescale;
                        end
                    case 1
                    case 2
                    case 3
                        scaledinputs(:,p) = (scaledinputs(:,p)-trialdata.hardcurrentoffset)*trialdata.hardcurrentscale * 1000;
                    case 4
                        scaledinputs(:,p) = (scaledinputs(:,p)-trialdata.hardvoltageoffset)*trialdata.hardvoltagescale * 1000;
                end
            end
        end
        function scaledoutputs = transformOutputs(obj,varargin)
            [outputs,ports] = obj.parsePorts(varargin{:});
            scaledoutputs = outputs;
            for p = 1:length(ports)
                switch ports(p)
                    case 0
                        switch obj.recmode
                            case 'VClamp'
                                obj.inputLabels{1} = 'current';
                                obj.inputUnits{1} = 'pA';
                                scaledoutputs(:,p) = (outputs(:,p)-obj.params.scaledcurrentoffset)*obj.params.scaledcurrentscale;
                            case 'IClamp'
                                obj.inputLabels{1} = 'voltage';
                                obj.inputUnits{1} = 'mV';
                                scaledoutputs(:,p) = (outputs(:,p)-obj.params.scaledvoltageoffset)*obj.params.scaledvoltagescale;
                        end
                    case 1
                        
                end
            end
        end
        
        function newmode = setmode(obj)
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
