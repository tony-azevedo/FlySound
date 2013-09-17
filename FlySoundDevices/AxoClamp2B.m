classdef AxoClamp2B < Device
    
    properties (Constant)
        deviceName = 'AxoClamp2B';
    end
    
    properties (Hidden, SetAccess = protected)
    end

    
    events
    end
    
    methods
        function obj = AxoClamp2B(varargin)
            % This and the transformInputs function are hard coded
            obj.inputLabels = {'current','voltage'};
            obj.inputUnits = {'pA','mV'};
            obj.inputPorts = [6,7];
            obj.outputLabels = {'voltage','current'};
            obj.outputUnits = {'mV','pA'};
            obj.outputPorts = [ 1 3];

            obj.mode = 'VClamp';
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
                        inputstruct.voltage = (inputstruct.(inlabels{il})-obj.params.hardvoltageoffset)*obj.params.hardvoltagescale * 1000;
                        units{il} = 'mV';
                    case 'current'
                        inputstruct.current = (inputstruct.(inlabels{il})-obj.params.hardcurrentoffset)*obj.params.hardcurrentscale * 1000;
                        units{il} = 'pA';
                end
            end
            varargout = {inputstruct,units};
        end
        
        function setmode(obj)
            obj.mode = ModeGUI(obj.mode);
            notify(obj,'ModeChange');
        end
        
        function newmode = getmode(obj)
            obj.mode = ModeGUI(obj.mode);
            newmode = obj.mode;
            notify(obj,'ModeChange');
        end
        
        function newgain = getgain(obj)           
            obj.gain = 1;
            newgain = obj.gain;
        end
                
        function setModeSession(obj)
        end
        
        function setGainSession(obj)
        end

    end
    
    methods (Access = protected)
                
        function defineParameters(obj)
            obj.params.filter = 1e4;            
            obj.params.rearcurrentswitchval = 1; % [V/nA];
                        
            obj.params.headstagegain = .01;
            obj.params.daqCurrentOffset = 0.0000;
            obj.params.daqout_to_current = 10*obj.params.headstagegain; % m, multiply DAQ voltage to get nA injected
            obj.params.daqout_to_current_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            obj.params.daqout_to_voltage = .02; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            obj.params.daqout_to_voltage_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            obj.params.hardcurrentscale = .010/(obj.params.rearcurrentswitchval*obj.params.headstagegain); % [V]/current scal gives nA;
            obj.params.hardcurrentoffset = -7e-3; % -6.6238/1000;
            obj.params.hardvoltagescale = 1/(10); % reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            obj.params.hardvoltageoffset = -0.01949; % -6.2589/1000; % in V, reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV

        end
    end
end
