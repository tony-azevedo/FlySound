classdef TwoTrodeRig < Rig
    
    properties (Constant)
        rigName = 'TwoTrodeRig';
        IsContinuous = false;
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = TwoTrodeRig(varargin)
            % acqhardware = getpref('AcquisitionHardware');
            % if isfield(acqhardware,'Amplifier')
            %    obj.addDevice('amplifier',acqhardware.Amplifier);
            
            ampDevices = {'MultiClamp700B','MultiClamp700BAux'};
            p = inputParser;
            p.PartialMatching = 0;
            p.addParamValue('amplifier1Device','MultiClamp700B',@ischar);            
            parse(p,varargin{:});
            
            obj.addDevice('amplifier_1',ampDevices{strcmp(ampDevices,p.Results.amplifier1Device)});
            obj.addDevice('amplifier_2',ampDevices{~strcmp(ampDevices,p.Results.amplifier1Device)});

            addlistener(obj.devices.amplifier_1,'ModeChange',@obj.changeSessionsFromMode);
            addlistener(obj.devices.amplifier_2,'ModeChange',@obj.changeSessionsFromMode);
            
            obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
            obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
        end
        
        function in = run(obj,protocol,varargin)
            obj.devices.amplifier_1.getmode;
            obj.devices.amplifier_1.getgain;

            obj.devices.amplifier_2.getmode;
            obj.devices.amplifier_2.getgain;
            
            in = run@Rig(obj,protocol,varargin{:});
        end        
                
        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@Rig(obj,fig,evnt,varargin{:})
            if nargin>3
                protocol = varargin{1};   
                if strcmp(protocol.protocolName,get(obj.TrialDisplay,'Name')) &&...
                        isequal(get(obj.TrialDisplay,'UserData'),protocol.params)
                    return
                end
                
                set(obj.TrialDisplay,'Name',protocol.protocolName)
                set(obj.TrialDisplay,'UserData',protocol.params)
                
                ax = subplot(3,1,[1 2],'Parent',obj.TrialDisplay,'tag','inputax');
                delete(findobj(ax,'tag','ampinput'));
                line(makeTime(protocol),makeTime(protocol),'parent',ax,'color',[1 0 0],'linewidth',1,'tag','ampinput','displayname','input');
                ylabel('Amp Input'); box off; set(gca,'TickDir','out');
                
                ax = subplot(3,1,3,'Parent',obj.TrialDisplay,'tag','outputax');
                delete(findobj(ax,'tag','ampinput_alt'));
                
                out = protocol.getStimulus;
                delete(findobj(ax,'tag','ampoutput'));
                outlabel = fieldnames(out);
                if ~isempty(outlabel)
                    line(makeOutTime(protocol),out.(outlabel{1}),'parent',ax,'color',[.8 .8 .8],'linewidth',1,'tag','ampoutput','displayname','output');
                    ylabel('out'); box off; set(gca,'TickDir','out');
                else
                    line(makeOutTime(protocol),makeOutTime(protocol),'parent',ax,'color',[.8 .8 .8],'linewidth',1,'tag','ampoutput','displayname','output');
                    box off; set(gca,'TickDir','out');
                end
                xlabel('Time (s)'); %xlim([0 max(t)]);

                line(makeTime(protocol),makeTime(protocol),'parent',ax,'color',[1 0 0],'linewidth',1,'tag','ampinput_alt','displayname','altinput');
                
                linkaxes(get(obj.TrialDisplay,'children'),'x');
            end
        end

        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end

            if strcmp(obj.devices.amplifier.mode,'VClamp')                
                invec = obj.inputs.data.current;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'current'));
                inunits = obj.devices.amplifier.inputUnits{ind(1)};

                invecalt = obj.inputs.data.voltage;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'voltage'));
                inaltunits = obj.devices.amplifier.inputUnits{ind(1)};
            elseif sum(strcmp({'IClamp','IClamp_fast'},obj.devices.amplifier.mode))
                invec = obj.inputs.data.voltage;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'voltage'));
                inunits = obj.devices.amplifier.inputUnits{ind(1)};
                
                invecalt = obj.inputs.data.current;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'current'));
                inaltunits = obj.devices.amplifier.inputUnits{ind(1)};
            end
            ylabel(findobj(obj.TrialDisplay,'tag','inputax'),inunits);
            ylabel(findobj(obj.TrialDisplay,'tag','outputax'),inaltunits);

            l = findobj(findobj(obj.TrialDisplay,'tag','inputax'),'tag','ampinput');
            set(l,'ydata',invec');

            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampinput_alt');
            set(l,'ydata',invecalt');
            
            out = protocol.getStimulus;
            outlabels = fieldnames(out);
            chnames = obj.getChannelNames;
            if ~isempty(outlabels)
                if strcmp(obj.devices.amplifier.mode,'VClamp')
                    outvec = out.voltage;
                    % outunits = obj.devices.amplifier.outputUnits{...
                    %     strcmp(obj.devices.amplifier.outputLabels,'voltage')};
                elseif sum(strcmp({'IClamp','IClamp_fast'},obj.devices.amplifier.mode))
                    outvec = out.current;
                    % outunits = obj.devices.amplifier.outputUnits{...
                    %     strcmp(obj.devices.amplifier.outputLabels,'current')};
                end
                %ylabel(findobj(obj.TrialDisplay,'tag','outputax'),outunits);

                l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampoutput');
                set(l,'ydata',outvec);                
            end

        end
    end
    
    methods (Access = protected)
        
        function changeSessionsFromMode(obj,amplifier,evnt)
            for i = 1:length(amplifier.outputPorts)
                % configure AO
                for c = 1:length(obj.aoSession.Channels)
                    if strcmp(obj.aoSession.Channels(c).ID,['ao' num2str(amplifier.outputPorts(i))])
                        ch = obj.aoSession.Channels(c);
                        break
                    end
                end
                ch.Name = amplifier.outputLabels{i};
                obj.outputs.portlabels{amplifier.outputPorts(i)+1} = amplifier.outputLabels{i};
                obj.outputs.device{amplifier.outputPorts(i)+1} = amplifier;
                % use the current vals to apply to outputs
            end
            % obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
            obj.outputs.datavalues = zeros(size(obj.aoSession.Channels));
            obj.outputs.datacolumns = obj.outputs.datavalues;
            
            for i = 1:length(amplifier.inputPorts)
                for c = 1:length(obj.aiSession.Channels)
                    if strcmp(obj.aiSession.Channels(c).ID,['ai' num2str(amplifier.inputPorts(i))])
                        ch = obj.aiSession.Channels(c);
                        break
                    end
                end
                ch.Name = amplifier.inputLabels{i};
                obj.inputs.portlabels{amplifier.inputPorts(i)+1} = amplifier.inputLabels{i};
                obj.inputs.device{amplifier.inputPorts(i)+1} = amplifier;
                obj.inputs.data.(amplifier.inputLabels{i}) = [];
            end
        end
        
        function obj = checkAmplifierModes(obj,out)
            % run a check for the mode of the amplifier and throw error
            % elegantly
            if sum(strcmp(fieldnames(out),'current_1')) &&...
                    sum(out.current_1 ~= out.current_1(1)) &&...
                    strcmp(obj.devices.amplifier_1.mode,'VClamp')
                error('Amplifier in VClamp but no current out')
            elseif sum(strcmp(fieldnames(out),'voltage')) &&...
                    sum(out.voltage ~= out.voltage(1)) &&...
                    strcmp(obj.devices.amplifier.mode,'IClamp')
                error('Amplifier in IClamp but voltage command')
            end
        end
        
    end
end

