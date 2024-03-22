classdef TwoAmpRig < Rig
    % current hierarchy:
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> TwoTrodeRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig 
    
    properties (Constant, Abstract)
        rigName
        IsContinuous
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = TwoAmpRig(varargin)
            %% Note for future applications:
            % The TwoTrodeRig establishes 1 amp as the main one, and a
            % second as amplifier_2. If a protocol is going to stimulate
            % one cell then the next, make sure to use the protocol to
            % establish output one, then output 2, etc.
            % Don't switch amp designations just to use 
            % the same protocol on the second amp.
            % this means once the TwoRig Structure is saved, the same
            % electrode is always associated with the same output.
            
            %%
            ampDevices = {'MultiClamp700A','MultiClamp700AAux'};
            p = inputParser;
            p.PartialMatching = 0;
            p.addParameter('amplifier1Device','MultiClamp700A',@ischar);            
            parse(p,varargin{:});
            
            obj.addDevice('amplifier_1',ampDevices{strcmp(ampDevices,p.Results.amplifier1Device)});
            obj.addDevice('amplifier_2',ampDevices{~strcmp(ampDevices,p.Results.amplifier1Device)});

            % Adding a new, passive extensor EMG input. Not elegant, but
            % working fine
            obj.addDevice('extEMGAmplifier','AxoPatch200B_EMG');
            
            obj.devices.amplifier_1.setOrder('amplifierDevNumber',1);
            obj.devices.amplifier_2.setOrder('amplifierDevNumber',2);
            
            addlistener(obj.devices.amplifier_1,'ModeChange',@obj.changeSessionsFromMode);
            addlistener(obj.devices.amplifier_2,'ModeChange',@obj.changeSessionsFromMode);
            addlistener(obj.devices.extEMGAmplifier,'ModeChange',@obj.changeSessionsFromMode);

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
                
                ax = subplot(3,1,1,'Parent',obj.TrialDisplay);
                set(ax,'tag','inputax1');
                delete(findobj(ax,'tag','ampinput1'));
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[.5 0 0],'linewidth',1,'tag','ampinput1','displayname','input1');
                ylabel('Amp 1 Input'); box off; set(gca,'TickDir','out');
                
                ax = subplot(3,1,2,'Parent',obj.TrialDisplay);
                set(ax,'tag','inputax2');
                delete(findobj(ax,'tag','ampinput2'));
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[1 .5 .5],'linewidth',1,'tag','ampinput2','displayname','input2');
                ylabel('Amp 2 Input'); box off; set(gca,'TickDir','out');

                ax = subplot(3,1,3,'Parent',obj.TrialDisplay);
                set(ax,'tag','outputax');
                delete(findobj(ax,'tag','ampinput_alt1'));
                delete(findobj(ax,'tag','ampinput_alt2'));
                
                out = protocol.getStimulus;
                delete(findobj(ax,'tag','ampoutput1'));
                delete(findobj(ax,'tag','ampoutput2'));
                
                outlabel = fieldnames(out);
                if ~isempty(outlabel)
                    line(makeOutTime(protocol),zeros(size(out.(outlabel{1}))),'parent',ax,'color',[.8 .8 .8],'linewidth',1,'tag','ampoutput1','displayname','output1');
                    line(makeOutTime(protocol),zeros(size(out.(outlabel{1}))),'parent',ax,'color',[.8 .8 .8],'linewidth',1,'tag','ampoutput2','displayname','output2');
                    ylabel('out'); box off; set(gca,'TickDir','out');
                else
                    line(makeOutTime(protocol),makeOutTime(protocol),'parent',ax,'color',[.8 .8 .8],'linewidth',1,'tag','ampoutput1','displayname','output1');
                    line(makeOutTime(protocol),makeOutTime(protocol),'parent',ax,'color',[.8 .8 .8],'linewidth',1,'tag','ampoutput2','displayname','output2');
                    box off; set(gca,'TickDir','out');
                end
                xlabel('Time (s)'); %xlim([0 max(t)]);

                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[.5 0 0],'linewidth',1,'tag','ampinput_alt1','displayname','altinput');
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[1 .5 .5],'linewidth',1,'tag','ampinput_alt2','displayname','altinput');
                
                linkaxes(get(obj.TrialDisplay,'children'),'x');
            end
        end

        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end
            
            %% Amplifier #1
            if strcmp(obj.devices.amplifier_1.mode,'VClamp')
                
                invec = obj.inputs.data.current_1;
                ind = find(strcmp(obj.devices.amplifier_1.inputLabels,'current_1'));
                inunits = obj.devices.amplifier_1.inputUnits{ind(1)};
                
                invecalt = obj.inputs.data.voltage_1;
                ind = find(strcmp(obj.devices.amplifier_1.inputLabels,'voltage_1'));
                inaltunits = obj.devices.amplifier_1.inputUnits{ind(1)};
                
            elseif sum(strcmp({'IClamp','IClamp_fast'},obj.devices.amplifier_1.mode))
                
                invec = obj.inputs.data.voltage_1;
                ind = find(strcmp(obj.devices.amplifier_1.inputLabels,'voltage_1'));
                inunits = obj.devices.amplifier_1.inputUnits{ind(1)};
                
                invecalt = obj.inputs.data.current_1;
                ind = find(strcmp(obj.devices.amplifier_1.inputLabels,'current_1'));
                inaltunits = obj.devices.amplifier_1.inputUnits{ind(1)};
                
            end
            
            ylabel(findobj(obj.TrialDisplay,'tag','inputax1'),inunits);
            ylabel(findobj(obj.TrialDisplay,'tag','outputax'),inaltunits);
            
            l = findobj(findobj(obj.TrialDisplay,'tag','inputax1'),'tag','ampinput1');
            set(l,'ydata',invec');
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampinput_alt1');
            set(l,'ydata',invecalt');
            
            %% Amplifier #2
            if strcmp(obj.devices.amplifier_2.mode,'VClamp')
                
                invec = obj.inputs.data.current_2;
                ind = find(strcmp(obj.devices.amplifier_2.inputLabels,'current_2'));
                inunits = obj.devices.amplifier_2.inputUnits{ind(1)};
                
                invecalt = obj.inputs.data.voltage_2;
                
            elseif sum(strcmp({'IClamp','IClamp_fast'},obj.devices.amplifier_2.mode))
                
                invec = obj.inputs.data.voltage_2;
                ind = find(strcmp(obj.devices.amplifier_2.inputLabels,'voltage_2'));
                inunits = obj.devices.amplifier_2.inputUnits{ind(1)};
                
                invecalt = obj.inputs.data.current_2;
                
            end
            
            ylabel(findobj(obj.TrialDisplay,'tag','inputax2'),inunits);
            
            l = findobj(findobj(obj.TrialDisplay,'tag','inputax2'),'tag','ampinput2');
            set(l,'ydata',invec');
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampinput_alt2');
            set(l,'ydata',invecalt');
            
            out = protocol.getStimulus;
            outlabels = fieldnames(out);
            if ~isempty(outlabels)
                outvec = out.(outlabels{1});
                l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampoutput1');
                set(l,'ydata',outvec);
            end
            
        end
        
        
        function transformOutputs(obj,out)
            
            % check that amps are in the right modes
            checkAmplifierModes(obj,out);
            
            % loop over devices, transforming data
            devs = fieldnames(obj.devices);
            for d = 1:length(devs)
                dev = obj.devices.(devs{d});
                if ~isempty(dev)
                    out = dev.transformOutputs(out,obj);
                end
            end
            
            % make the stims the right size (keeping the array if it's the
            % same
            outnames = fieldnames(out);
            if size(obj.outputs.datacolumns,1) ~= length(out.(outnames{1}))
                if sum(obj.outputs.datavalues ~= obj.outputs.datacolumns(end,:))
                    obj.outputs.datavalues = obj.outputs.datacolumns(end,:);
                end
                % column array of outputs from the outvalues vector
                obj.outputs.datacolumns = repmat(obj.outputs.datavalues(:)',...
                    length(out.(outnames{1})),1);
            end
            
            % get outvals end values just in case
            if sum(obj.outputs.datavalues ~= obj.outputs.datacolumns(end,:))
                obj.outputs.datavalues = obj.outputs.datacolumns(end,:);
                for c = 1:size(obj.outputs.datacolumns,2)
                    obj.outputs.datacolumns(:,c) = obj.outputs.datavalues(c);
                end
            end
            
            % add a little step to the beginning of trials
            if strcmp(obj.devices.amplifier_1.mode,'IClamp')
                testoutname = 'current';
                outname = 'current_1';
            elseif strcmp(obj.devices.amplifier_1.mode,'VClamp')
                testoutname = 'voltage';
                outname = 'voltage_1';
            else
                testoutname = '';
            end
            if ~isempty(testoutname) && obj.params.(['test' testoutname 'stepamp']) ~= 0
                teststep_start = obj.params.teststep_start*obj.params.samprateout;
                teststep_dur = obj.params.teststep_dur*obj.params.samprateout;
                
                teststep.(outname) = zeros(size(out.(outnames{1})));
                teststep.(outname)(teststep_start+1:teststep_start+teststep_dur) = obj.params.(['test' testoutname 'stepamp']);
                teststep = obj.devices.amplifier_1.transformOutputs(teststep);
                if ismember(outname,outnames)
                    out.(outname) = out.(outname)+teststep.(outname);
                else
                    out.(outname) = teststep.(outname);
                end
            end
            
            for ch = 1:length(obj.outputchannelidx)
                if isfield(out,obj.daq.Channels(obj.outputchannelidx(ch)).Name)
                    obj.outputs.datacolumns(:,ch) = out.(obj.daq.Channels(obj.outputchannelidx(ch)).Name);
                end
            end
        end
        
        function transformInputs(obj,in)
            chids = obj.inputchannelidx;
            [~,o] = sort(chids);
            % go from highest channel id to lowest (ai7 -> ai0).  This
            % enters scaled output (always ai0) for either V or I
            for ch = length(o):-1:1
                obj.inputs.data.(obj.daq.Channels(chids(ch)).Name) = in.(obj.daq.Channels(chids(ch)).Name);
            end
            devs = fieldnames(obj.devices);
            for d = 1:length(devs)
                dev = obj.devices.(devs{d});
                if ~isempty(dev)
                    obj.inputs.data = dev.transformInputs(obj.inputs.data);
                end
            end
            
            if strcmp(obj.devices.amplifier_1.mode,'IClamp')
                testoutname = 'voltage';
                inname = 'voltage_1';
            elseif strcmp(obj.devices.amplifier_1.mode,'VClamp')
                testoutname = 'current';
                inname = 'current_1';
            else
                testoutname = '';
            end
            if ~isempty(testoutname) && obj.params.(['test' testoutname 'stepamp']) ~= 0
                teststep_start = obj.params.teststep_start*obj.params.samprateout;
                teststep_dur = obj.params.teststep_dur*obj.params.samprateout;
                if teststep_dur>0
                    
                    testresp_i = mean(obj.inputs.data.(inname)(1:teststep_start));
                    testresp_f = mean(obj.inputs.data.(inname)(teststep_start+teststep_dur-teststep_start+1:teststep_start+teststep_dur));
                    testresp_min = min(obj.inputs.data.(inname)(teststep_start:teststep_start+teststep_dur/4));
                    testresp_max = max(obj.inputs.data.(inname)(teststep_start+teststep_dur:teststep_start+teststep_dur+teststep_dur/4));
                    
                    if strcmp(obj.devices.amplifier_1.mode,'IClamp')
                        R = (testresp_f-testresp_i)/obj.params.testcurrentstepamp;
                        colr = [1 0 1];
                        access = nan;
                    elseif strcmp(obj.devices.amplifier_1.mode,'VClamp')
                        R = obj.params.testvoltagestepamp/(testresp_f-testresp_i);
                        colr = [0 1 1];
                        access = obj.params.testvoltagestepamp/mean([(testresp_min-testresp_i) -abs(testresp_max-testresp_i)]);
                    end
                    
                    ax = findobj(obj.TestDisplay,'type','axes');
                    line(datetime('now'),R,'linestyle','none','marker','o','markersize',3,'markerfacecolor',colr,'markeredgecolor',colr,'parent',ax);
                    if ~isnan(access), line(datetime('now'),access,'linestyle','none','marker','+','markersize',3,'markerfacecolor',colr,'markeredgecolor',colr,'parent',ax); end
                    
                    bl = findobj(ax,'tag','baseline');
                    x = get(bl,'xdata');
                    x = [x(1) datetime('now')];
                    set(bl,'xdata',x);
                end
            end
            
        end
        
    end


    methods (Access = protected)
        
        function changeSessionsFromMode(obj,amplifier,evnt)
            for i = 1:length(amplifier.outputPorts)
                % configure AO
                for c = 1:length(obj.daq.Channels)
                    if strcmp(obj.daq.Channels(c).ID,['ao' num2str(amplifier.outputPorts(i))])
                        ch = obj.daq.Channels(c);
                        break
                    end
                end
                ch.Name = amplifier.outputLabels{i};
                obj.outputs.portlabels{amplifier.outputPorts(i)+1} = amplifier.outputLabels{i};
                obj.outputs.device{amplifier.outputPorts(i)+1} = amplifier;
                % use the current vals to apply to outputs
            end
            % obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
            obj.outputs.datavalues = zeros(size(obj.outputchannelidx));
            obj.outputs.datacolumns = obj.outputs.datavalues;
            
            for i = 1:length(amplifier.inputPorts)
                for c = 1:length(obj.daq.Channels)
                    if strcmp(obj.daq.Channels(c).ID,['ai' num2str(amplifier.inputPorts(i))])
                        ch = obj.daq.Channels(c);
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
            elseif any(strcmp(fieldnames(out),'voltage_1')) &&...
                    any(out.voltage_1 ~= out.voltage_1(1)) &&...
                    strcmp(obj.devices.amplifier_1.mode,'IClamp')
                error('Amplifier in IClamp but voltage command')
            end
        end
        
    end
end

