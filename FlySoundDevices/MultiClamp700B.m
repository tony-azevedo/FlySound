classdef MultiClamp700B < Device
    
    properties (Constant)
        deviceName = 'MultiClamp700B';
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end

    properties (Hidden, SetAccess = protected)
        modeSession
        gainSession
        secondary_gain
    end

    
    events
        BadMode
        ModeChange
    end
    
    methods
        function obj = MultiClamp700B(varargin)
            % This and the transformInputs function are hard coded
            obj.inputLabels = {'primary','secondary'};
            obj.inputUnits = {'mV','pA'};
            obj.inputPorts = [0 1];
            obj.outputLabels = {'scaled'};
            obj.outputUnits = {'pA'};
            obj.outputPorts = 0;

            obj.setModeSession;
            obj.mode = 'VClamp';
            obj.getmode;
            obj.setGainSession;
            obj.getgain;
        end
        
        function varargout = transformOutputs(obj,out)
            outlabels = fieldnames(out);
            for ol = 1:length(outlabels)
                if strcmp(outlabels{ol},'voltage')
                    if sum(strcmp({'IClamp'},obj.mode))
                        %warning('In Current Clamp - removing current stim')
                        out = rmfield(out,'voltage');
                    else
                        % out.voltage = out.voltage/1000;  % mV, convert, this is the desired V injected
                        out.voltage = out.voltage * obj.params.daqout_to_voltage + obj.params.daqout_to_voltage_offset;
                    end
                end
                if strcmp(outlabels{ol},'current')
                    if sum(strcmp('VClamp',obj.mode))
                        %warning('In Voltage Clamp - removing current stim')
                        out = rmfield(out,'current');
                    else
                        out.current = out.current * obj.params.daqout_to_current + obj.params.daqout_to_current_offset;
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
                        % transfrom V to mV
                        if sum(strcmp({'IClamp'},obj.mode))
                            inputstruct.voltage =...
                                (inputstruct.(inlabels{il})-obj.params.scaledvoltageoffset) /...
                                (obj.params.scaledvoltagescale_over_gain * obj.gain);
                        else
                            inputstruct.voltage = ...
                                (inputstruct.(inlabels{il})-obj.params.scaledvoltageoffset) /...
                                (obj.params.scaledvoltagescale_over_gain * obj.secondary_gain);
                        end
                        units{il} = 'mV'; 
                    case 'current'
                        % transfrom V to pA
                        if sum(strcmp('VClamp',obj.mode))
                            inputstruct.current =...
                                (inputstruct.(inlabels{il})-obj.params.scaledcurrentoffset) /...
                                (obj.params.scaledcurrentscale_over_gain * obj.gain);
                        else
                            inputstruct.current = ...
                                (inputstruct.(inlabels{il})-obj.params.scaledcurrentoffset) /...
                                (obj.params.scaledcurrentscale_over_gain * obj.secondary_gain);
                        end
                        units{il} = 'pA';
                end
            end
            varargout = {inputstruct,units};
        end
        
        function setModeSession(obj)
            % Need to replace this with some interaction with the
            % Multiclamp commander.
            
            % add listener to the MC telegraphs...
        end
        
        function setGainSession(obj)
            % Need to replace this with some interaction with the
            % Multiclamp commander.
            
            % add listener to the MC telegraphs...
        end
        
        function newmode = getmode(obj)
            mccmode = MCCGetMode;
            % see AxMultiClampMsg.h mode constants
            if mccmode == 0
                obj.mode = 'VClamp';
            elseif mccmode == 1
                obj.mode = 'IClamp';
            elseif mccmode == 2
                obj.mode = 'I=0';
            end
            newmode = obj.mode;
            if sum(strcmp('VClamp',newmode))
                    obj.outputLabels{1} = 'voltage';
                    obj.outputUnits{1} = 'mV';
                    obj.inputLabels{1} = 'current';
                    obj.inputUnits{1} = 'pA';
                    obj.inputLabels{2} = 'voltage';
                    obj.inputUnits{2} = 'mV';
            elseif sum(strcmp({'IClamp'},newmode)) 
                    obj.outputLabels{1} = 'current';
                    obj.outputUnits{1} = 'pA';
                    obj.inputLabels{1} = 'voltage';
                    obj.inputUnits{1} = 'mV';
                    obj.inputLabels{2} = 'current';
                    obj.inputUnits{2} = 'pA';
            end
            notify(obj,'ModeChange');
        end
        
        function newgain = getgain(obj)
            [gain1,primarySignal,gain2,secondarySignal] = MCCGetGain;
            % see AxMultiClampMsg.h constants prim and secondary signal IDs
            
            obj.gain = gain1;
            newgain = obj.gain;
            obj.secondary_gain = gain2;
            
            % check that signal IDs are correct for this mode
            if sum(strcmp('VClamp',obj.mode))
                % have to record current and membrane potential
                
                if primarySignal ~= 0
                    errorstr = sprintf('In %s mode, but primary signal is not MCCMSG_PRI_SIGNAL_VC_MEMBCURRENT',obj.mode);
                    errordlg(errorstr,'Incorrect Signals','modal');
                    error(errorstr); %#ok<SPERR>
                end
                if secondarySignal ~= 1
                    errorstr = sprintf('In %s mode, but primary signal is not MCCMSG_SEC_SIGNAL_VC_MEMBPOTENTIAL',obj.mode);
                    errordlg(errorstr,'Incorrect Signals','modal');
                    error(errorstr); %#ok<SPERR>
                end
                    
                    
            elseif sum(strcmp({'IClamp','I=0'},obj.mode)) 
                if primarySignal ~= 7
                    errorstr = sprintf('In %s mode, but primary signal is not MCCMSG_PRI_SIGNAL_IC_MEMBPOTENTIAL',obj.mode);
                    errordlg(errorstr,'Incorrect Signals','modal');
                    error(errorstr); %#ok<SPERR>
                end
                if secondarySignal ~= 8
                    errorstr = sprintf('In %s mode, but primary signal is not MCCMSG_SEC_SIGNAL_IC_MEMBCURRENT',obj.mode);
                    errordlg(errorstr,'Incorrect Signals','modal');
                    error(errorstr); %#ok<SPERR>
                end
            end                
        end        
    end
    
    methods (Access = protected)
                
        function defineParameters(obj)
            % create an amplifier class that implements these
            % http://www.a-msystems.com/pub/manuals/2400manual.pdf page 42
            try rmpref('defaultsMultiClamp700B'), catch, end
            obj.params.filter = 1e4;
            obj.params.headstagegain = .2; % 1
            obj.params.headstageresistorCC = 500e6; % 50e6, 5e9
            
            cursensitivity = obj.params.headstagegain/obj.params.headstageresistorCC*1e12; % pA/V
            obj.params.daqout_to_current = 1/cursensitivity; % nA/V, multiply DAQ voltage to get nA injected
            obj.params.daqCurrentOffset = 0.0000;
            obj.params.daqout_to_current_offset = 0;  % b, add to DAQ voltage to get the right offset

            obj.params.cmdsensitivity = 20; % 100 mV/V
            obj.params.headstageresistorVC = 500e6; % 50e6, 5e9

            obj.params.daqout_to_voltage = 1/obj.params.cmdsensitivity; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            obj.params.daqout_to_voltage_offset = 0;  % b, add to DAQ voltage to get the right offset
                        
            obj.params.scaledcurrentscale_over_gain = 1e-12*obj.params.headstageresistorCC; % [V/pA] * gainsetting
            obj.params.scaledcurrentoffset = 0; 
            obj.params.scaledvoltagescale_over_gain = 10/1000; % 10Vm [mV/V] * gainsetting (Look at multiclamp prim output window
            obj.params.scaledvoltageoffset = 0; 
        end
    end
end
