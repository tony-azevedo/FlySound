classdef MultiClamp700A_Control < Device
    
    properties (SetAccess = protected)
    end
    
    properties 
        deviceName = 'MultiClamp700A_Control';
    end

    properties (Hidden, SetAccess = protected)
        modeGainGUI
        secondary_gain
        amplifierDevNumber = '_1';
        partOfSet = false;
    end

    
    events
        BadMode
        ModeChange
    end
    
    methods
        function obj = MultiClamp700A_Control(varargin)
            obj = obj@Device();

            % This and the transformInputs function are hard coded
            % obj.inputLabels = {'primary','secondary'};
            % obj.inputUnits = {'mV','pA'};
            % obj.inputPorts = [0 1];
            obj.outputLabels = {'scaled'};
            obj.outputUnits = {'pA'};
            obj.outputPorts = 0;

            obj.setModeSession;
            obj.mode = 'VClamp';
            obj.getmode;
            obj.setGainSession;
            obj.getgain;
            obj.countTests;
        end
        
        function obj = setOrder(obj,varargin)
            p = inputParser;
            p.PartialMatching = 0;
            p.addParameter('amplifierDevNumber',1,@isnumeric);
            p.parse(varargin{:});
            
            obj.amplifierDevNumber = ['_' num2str(p.Results.amplifierDevNumber)];
            obj.partOfSet = true;
        end
        
        function varargout = transformOutputs(obj,out,varargin)
            outlabels = fieldnames(out);
            for ol = 1:length(outlabels)
                
                % Do this only if the Device cares about this outlabel
                if ismember(obj.outputLabels,outlabels{ol})
                                      
                    % If part of a set of Multiclamps, make sure it's the
                    % right voltage_? trace
                    if ~isempty(strfind(outlabels{ol},'voltage')) && ...
                        (~obj.partOfSet || ~isempty(strfind(outlabels{ol},obj.amplifierDevNumber)))
                        if sum(strcmp({'IClamp'},obj.mode))
                            %warning('In Current Clamp - removing voltage stim')
                            out = rmfield(out,outlabels{ol});
                        else
                            % out.voltage = out.voltage/1000;  % mV, convert, this is the desired V injected
                            out.(outlabels{ol}) = out.(outlabels{ol}) * obj.params.daqout_to_voltage + obj.params.daqout_to_voltage_offset;
                        end
                    end

                    % If part of a set of Multiclamps, make sure it's the
                    % right current_? trace
                    if ~isempty(strfind(outlabels{ol},'current')) && ...
                        (~obj.partOfSet || ~isempty(strfind(outlabels{ol},obj.amplifierDevNumber)))
                        if sum(strcmp('VClamp',obj.mode))
                            %warning('In Voltage Clamp - removing current stim')
                            out = rmfield(out,outlabels{ol});
                        else
                            out.(outlabels{ol}) = out.(outlabels{ol}) * obj.params.daqout_to_current + obj.params.daqout_to_current_offset;
                        end
                    end
                    
                end
            end
            % if some field were removed, we were in the wrong mode
            if length(fieldnames(out)) < length(outlabels)
                notify(obj,'BadMode');
                error('%s in %s mode - No appropriate output',obj.deviceName,obj.mode);
            end
            varargout = {out};
        end
        
        function varargout = transformInputs(obj,inputstruct,varargin)
            ... No inputs on the control device
                %             inlabels = fieldnames(inputstruct);
            %             units = {};
            %             for il = 1:length(inlabels)
            %                 if sum(strcmp(obj.inputLabels,inlabels{il}))
            %                     if ~isempty(strfind(inlabels{il},'voltage')) && ...
            %                             (~obj.partOfSet || ~isempty(strfind(inlabels{il},obj.amplifierDevNumber)))
            %
            %                         % transfrom V to mV
            %                         if sum(strcmp({'IClamp'},obj.mode))
            %                             inputstruct.(inlabels{il}) =...
            %                                 (inputstruct.(inlabels{il})-obj.params.scaledvoltageoffset) /...
            %                                 (obj.params.scaledvoltagescale_over_gain * obj.gain);
            %                         else
            %                             inputstruct.(inlabels{il}) = ...
            %                                 (inputstruct.(inlabels{il})-obj.params.scaledvoltageoffset) /...
            %                                 (obj.params.scaledvoltagescale_over_gain * obj.secondary_gain);
            %                         end
            %                         units{il} = 'mV';
            %
            %                     end
            %
            %
            %                     if ~isempty(strfind(inlabels{il},'current')) && ...
            %                             (~obj.partOfSet || ~isempty(strfind(inlabels{il},obj.amplifierDevNumber)))
            %                         % transfrom V to pA
            %                         if sum(strcmp('VClamp',obj.mode))
            %                             inputstruct.(inlabels{il}) =...
            %                                 (inputstruct.(inlabels{il})-obj.params.scaledcurrentoffset) /...
            %                                 (obj.params.scaledcurrentscale_over_gainVC * obj.gain);
            %                         else
            %                             inputstruct.(inlabels{il}) = ...
            %                                 (inputstruct.(inlabels{il})-obj.params.scaledcurrentoffset) /...
            %                                 (obj.params.scaledcurrentscale_over_gainCC * obj.secondary_gain);
            %                         end
            %                         units{il} = 'pA';
            %                     end
            %
            %                 end
            %             end
            %             varargout = {inputstruct,units};
        end
        
        function setModeSession(obj)            
            st = getacqpref('MC700AGUIstatus','status');
            if ~st
                MultiClamp700AGUI;
            end
        end
        
        function setGainSession(obj)
            % add listener to the MC telegraphs...
        end
                    
        function newmode = getmode(obj)
            st = getacqpref('MC700AGUIstatus','status');
            if ~st
                error('Open MultiClamp700AGUI')
            end
            
            modeorder = obj.subclassModeFunction();
            % % see AxMultiClampMsg.h mode constants
            % if mccmode == 0
            %     obj.mode = 'VClamp';
            % elseif mccmode == 1
            %     obj.mode = 'IClamp';
            % elseif mccmode == 2
            %     obj.mode = 'I=0';
            % end
            % newmode = obj.mode;
            newmode = getacqpref('MC700AGUIstatus',modeorder);

            obj.mode = newmode;
            if sum(strcmp('VClamp',newmode))
                    obj.outputLabels{1} = 'voltage';
                    obj.outputUnits{1} = 'mV';
                    % obj.inputLabels{1} = 'current';
                    % obj.inputUnits{1} = 'pA';
                    % obj.inputLabels{2} = 'voltage';
                    % obj.inputUnits{2} = 'mV';
            elseif sum(strcmp({'IClamp','IClamp2'},newmode)) 
                    obj.outputLabels{1} = 'current';
                    obj.outputUnits{1} = 'pA';
                    % obj.inputLabels{1} = 'voltage';
                    % obj.inputUnits{1} = 'mV';
                    % obj.inputLabels{2} = 'current';
                    % obj.inputUnits{2} = 'pA';
            end
            if obj.partOfSet
                for o_ind = 1:length(obj.outputLabels)
                    obj.outputLabels{o_ind} = [obj.outputLabels{o_ind} obj.amplifierDevNumber];
                end
                for i_ind = 1:length(obj.inputLabels)
                    obj.inputLabels{i_ind} = [obj.inputLabels{i_ind} obj.amplifierDevNumber];
                end
            end
            
            notify(obj,'ModeChange');
        end
        
        function newgain = getgain(obj)
            %[gain1,primarySignal,gain2,secondarySignal] = obj.subclassGainFunction;
            % see AxMultiClampMsg.h constants prim and secondary signal IDs
            st = getacqpref('MC700AGUIstatus','status');
            if ~st
                error('Open MultiClamp700AGUI')
            end
            
            gainorder = obj.subclassGainFunction;
            %% TODO:
            % currently gain is defined in Device. Find out where this is
            % defined and root it out.
            obj.gain = str2double(getacqpref('MC700AGUIstatus',gainorder));
            newgain = obj.gain;
            obj.secondary_gain = 1;
            
            % check that signal IDs are correct for this mode
            if sum(strcmp('VClamp',obj.mode))
                % have to record current and membrane potential
                primarySignal = 0;
                secondarySignal =  1;

                if primarySignal ~= 0
                    errorstr = sprintf('In %s mode, but primary signal is not MCCMSG_PRI_SIGNAL_VC_MEMBCURRENT',obj.mode);
                    errordlg(errorstr,'Incorrect Signals','modal');
                    error(errorstr); %#ok<SPERR>
                end
                if ~(secondarySignal == 1 || secondarySignal == 3)
                    errorstr = sprintf('In %s mode, but primary signal is not MCCMSG_SEC_SIGNAL_VC_MEMBPOTENTIAL',obj.mode);
                    errordlg(errorstr,'Incorrect Signals','modal');
                    error(errorstr); %#ok<SPERR>
                end
                    
                    
            elseif sum(strcmp({'IClamp','I=0'},obj.mode)) 
                primarySignal = 2;
                secondarySignal = 8;
                
                if primarySignal ~= 2
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
        
        % 170830 Moved these functions to normal methods rather than
        % static
        function mccmode = subclassModeFunction(obj)
            %             tic
            %             fprintf(1,'\nGetting %s mode:\n',mfilename);
            %             mccmode = MCCGetMode;
            %             toc
            mccmode = 'mode';
        end
        
        function varargout = subclassGainFunction(obj)
            %             tic
            %             fprintf(1,'\nGetting %s gain:\n',mfilename);
            %             [gain1,primarySignal,gain2,secondarySignal] = MCCGetGain;
            %             varargout = {gain1,primarySignal,gain2,secondarySignal};
            %             toc
            varargout = {[obj.mode '_gain']};
        end

        function countTests(obj)
            if obj.params.testFreq > 0
                if obj.params.testcnt == 0
                    % Reset test if testcnt has counted down
                    obj.params.testcnt = obj.params.testFreq;
                end
                obj.params.testcnt = obj.params.testcnt -1;
            else
                obj.params.testcnt = 1;
            end
        end

    end
    
    methods (Static)
    end
    
    methods (Access = protected)
                
        function setupDevice(obj)
            cursensitivity = obj.params.headstagegain/obj.params.headstageresistorCC*1e12; % pA/V
            obj.params.daqout_to_current = 1/cursensitivity; % nA/V, multiply DAQ voltage to get nA injected

            obj.params.daqout_to_voltage = 1/obj.params.cmdsensitivity; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV

            obj.params.scaledcurrentscale_over_gainVC = 1e-12*obj.params.headstageresistorVC; % [V/pA] * gainsetting
            obj.params.scaledcurrentscale_over_gainCC = 1e-12*obj.params.headstageresistorCC; % [V/pA] * gainsetting
        end
        
        function defineParameters(obj)
            % create an amplifier class that implements these
            % http://www.a-msystems.com/pub/manuals/2400manual.pdf page 42
            % try rmacqpref('defaultsMultiClamp700A_Control'), catch, end
            
            % Don't know why, but I've found that the command sensitivity
            % in the Multiclamp software was wrong! Check that!
            obj.params.filter = 1e4;
            obj.params.headstagegain = .2; % This converts resistor to currentsentitivity
            obj.params.headstageresistorCC = 500e6; % 50e6, 5e9
            
            cursensitivity = obj.params.headstagegain/obj.params.headstageresistorCC*1e12; % pA/V
            obj.params.daqout_to_current = 1/cursensitivity; % nA/V, multiply DAQ voltage to get nA injected
            obj.params.daqCurrentOffset = 0.0000;
            obj.params.daqout_to_current_offset = 0;  % b, add to DAQ voltage to get the right offset

            obj.params.cmdsensitivity = 20; % 100 mV/V
            obj.params.headstageresistorVC = 500e6; % 50e6, 5e9

            obj.params.daqout_to_voltage = 1/obj.params.cmdsensitivity; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            obj.params.daqout_to_voltage_offset = 0;  % b, add to DAQ voltage to get the right offset
                        
            obj.params.scaledcurrentscale_over_gainVC = 1e-12*obj.params.headstageresistorVC; % [V/pA] * gainsetting
            obj.params.scaledcurrentscale_over_gainCC = 1e-12*obj.params.headstageresistorCC; % [V/pA] * gainsetting
            obj.params.scaledcurrentoffset = 0; 
            obj.params.scaledvoltagescale_over_gain = 1/1000; % 10Vm [mV/V] * gainsetting (Look at multiclamp prim output window
            obj.params.scaledvoltageoffset = 0; 
            obj.params.testcnt = 0;
            obj.params.testFreq = 0;
            
            obj.params = obj.getDefaults;
        end
    end
   
end
