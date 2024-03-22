classdef DoubleSessionRig < Rig
    % current hierarchy: 7/14/16
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> TwoTrodeRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig 
    %                   -> PGRCameraRig -> PGREPhysRig
    %                                   -> PGRPiezoRig % This setup is for
    %                                   a digital output that requires same
    %                                   session, and same input and output
    %                                   sample rates
    %       -> SingleSession -> BasicEPhysRigSS
    
    properties (Constant,Abstract)
        rigName;
        IsContinuous;
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = DoubleSessionRig(varargin)
            % setacqpref('AcquisitionHardware','Amplifier','MultiClamp700B') %
            % setacqpref('AcquisitionHardware','Amplifier','AxoPatch200B_2P') %
            % AxoPatch200B % AxoClamp2B % MultiClamp700B % AxoPatch200B_2P

            obj.aiSession = daq.createSession('ni');
            obj.aoSession = daq.createSession('ni');            

            %             triggerChannelIn = getacqpref('AcquisitionHardware','triggerChannelIn');
            %             triggerChannelOut = getacqpref('AcquisitionHardware','triggerChannelOut');
            %
            %             obj.aiSession.addTriggerConnection([rigDev '/' triggerChannelIn],'External','StartTrigger');
            %             obj.aoSession.addTriggerConnection('External',[rigDev '/' triggerChannelOut],'StartTrigger');

            ampDevices = {'MultiClamp700A','MultiClamp700AAux'};
            p = inputParser;
            p.PartialMatching = 0;
            p.addParameter('amplifier1Device','MultiClamp700A',@ischar);            
            parse(p,varargin{:});
            
            acqhardware = getacqpref('AcquisitionHardware');
            if isfield(acqhardware,'Amplifier') ...
                    && ~strcmp(acqhardware.Amplifier,'MultiClamp700B')...
                    && ~strcmp(acqhardware.Amplifier,'AxoPatch200B_2P');
                obj.addDevice('amplifier',acqhardware.Amplifier);
            elseif ~isfield(acqhardware,'Amplifier')
                ampDevices = {'MultiClamp700A','MultiClamp700AAux'};
                obj.addDevice('amplifier',ampDevices{strcmp(ampDevices,p.Results.amplifier1Device)});
            elseif strcmp(acqhardware.Amplifier,'AxoPatch200B_2P')
                obj.addDevice('amplifier',acqhardware.Amplifier,'Session',obj.aiSession);
            elseif strcmp(acqhardware.Amplifier,'MultiClamp700B')
                obj.addDevice('amplifier',ampDevices{strcmp(ampDevices,p.Results.amplifier1Device)});
            end
            addlistener(obj.devices.amplifier,'ModeChange',@obj.changeSessionsFromMode);
        end
                
        function in = run(obj,protocol,varargin)
            obj.devices.amplifier.getmode;
            obj.devices.amplifier.getgain;
            if nargin>2
                repeats = varargin{1};
            else
                repeats = 1;
            end
            if isprop(obj,'TrialDisplay') && ~isempty(obj.TrialDisplay)
                if ishandle(obj.TrialDisplay)
                    delete(obj.TrialDisplay);
                end
            end
            obj.setDisplay([],[],protocol);
            obj.setTestDisplay();

            obj.aiSession.Rate = protocol.params.sampratein;
            obj.aiSession.NumberOfScans = length(makeInTime(protocol));
            obj.aoSession.Rate = protocol.params.samprateout;
            
            if obj.params.interTrialInterval >0;
                t = timerfind('Name','ITItimer');
                if isempty(t)
                    t = timer;
                end
                t.StartDelay = obj.params.interTrialInterval;
                t.TimerFcn = @(tObj, thisEvent) ... 
                    fprintf('%.1f sec inter trial\n',tObj.StartDelay);
                set(t,'Name','ITItimer')
            end
            notify(obj,'StartRun');
            for n = 1:repeats
                while protocol.hasNext()
                    obj.setAOSession(protocol);
                    notify(obj,'StartTrial',PassProtocolData(protocol));
                    %disp(obj.aoSession)
                    obj.aoSession.startBackground; % Start the session that receives start trigger first
                    
                    %disp(obj.aiSession)
                    % Collect input
                    in = obj.aiSession.startForeground; % both amp and signal monitor input
                    %disp(obj.aiSession)
                    obj.transformInputs(in);
                    if obj.params.interTrialInterval >0;
                        t = timerfind('Name','ITItimer');
                        start(t)
                        wait(t)
                    end
                    notify(obj,'SaveData');
                    obj.displayTrial(protocol);
                    notify(obj,'DataSaved');
                end
                protocol.reset;
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
                for c = 1:length(obj.aoSession.Channels)
                    if strcmp(obj.aoSession.Channels(c).ID,['ai' num2str(amplifier.inputPorts(i))])
                        ch = obj.aoSession.Channels(c);
                        break
                    end
                end
                ch.Name = amplifier.inputLabels{i};
                obj.inputs.portlabels{amplifier.inputPorts(i)+1} = amplifier.inputLabels{i};
                obj.inputs.device{amplifier.inputPorts(i)+1} = amplifier;
                obj.inputs.data.(amplifier.inputLabels{i}) = [];
            end
        end
        
        function defineParameters(obj)
            obj.params.sampratein = 50000;
            fprintf('SingleSession Rigs must have identical input and output sampling rates');
            obj.params.samprateout = obj.params.sampratein;
            obj.params.testcurrentstepamp = -5;
            obj.params.testvoltagestepamp = -2.5;
            obj.params.teststep_start = 0.010;
            obj.params.teststep_dur = 0.050;
            obj.params.interTrialInterval = 0;
            
        end

        function setSessions(obj,varargin)
            % Establish all the output channels and input channels in one
            % place
            rigDev = getacqpref('AcquisitionHardware','rigDev');
            
            if nargin>1
                keys = varargin;
            else
                keys = fieldnames(obj.devices);
            end
            for k = 1:length(keys);
                dev = obj.devices.(keys{k});
                for i = 1:length(dev.outputPorts)
                    % configure AO
                    ch = obj.aoSession.addAnalogOutputChannel(rigDev,dev.outputPorts(i), 'Voltage');
                    ch.Name = dev.outputLabels{i};
                    obj.outputs.portlabels{dev.outputPorts(i)+1} = dev.outputLabels{i};
                    obj.outputs.device{dev.outputPorts(i)+1} = dev;
                    % use the current vals to apply to outputs
                end
                % obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
                
                for i = 1:length(dev.digitalOutputPorts)
                    ch = obj.aoSession.addDigitalChannel(rigDev,['Port0/Line' num2str(dev.digitalOutputPorts(i))], 'OutputOnly');
                    ch.Name = dev.digitalOutputLabels{i};
                    obj.outputs.digitalPortlabels{dev.digitalOutputPorts(i)+1} = dev.digitalOutputLabels{i};
                    obj.outputs.device{dev.digitalOutputPorts(i)+getacqpref('AcquisitionHardware','AnalogOutN')+1} = dev;
                end
                obj.outputs.datavalues = zeros(size(obj.aoSession.Channels));
                obj.outputs.datacolumns = obj.outputs.datavalues;
                
                for i = 1:length(dev.inputPorts)
                    ch = obj.aoSession.addAnalogInputChannel(rigDev,dev.inputPorts(i), 'Voltage');
                    ch.InputType = 'SingleEnded';
                    ch.Name = dev.inputLabels{i};
                    obj.inputs.portlabels{dev.inputPorts(i)+1} = dev.inputLabels{i};
                    obj.inputs.device{dev.inputPorts(i)+1} = dev;
                    % obj.inputs.data.(dev.inputLabels{i}) = [];
                end
            
                for i = 1:length(dev.digitalInputPorts)
                    ch = obj.aoSession.addDigitalChannel(rigDev,['Port0/Line' num2str(dev.digitalInputPorts(i))], 'InputOnly');
                    ch.Name = dev.digitalInputLabels{i};
                    obj.inputs.digitalPortlabels{dev.digitalInputPorts(i)+1} = dev.digitalInputLabels{i};
                    obj.inputs.device{dev.digitalInputPorts(i)+getacqpref('AcquisitionHardware','AnalogInN')+1} = dev;
                    % obj.inputs.data.(dev.inputLabels{i}) = [];
                end
                
            end
        end

        function chNames = getChannelNames(obj)
            for ch = 1:length(obj.aoSession.Channels)
                chNames.out{ch} = obj.aoSession.Channels(ch).Name;
            end
            for ch = 1:length(obj.aiSession.Channels)
                chNames.in{ch} = obj.aiSession.Channels(ch).Name;
            end
        end
        
    end
end


%% old rig stuff
% classdef Rig < handle
%     % current hierarchy: 7/14/16
%     %   Rig -> EPhysRig -> BasicEPhysRig
%     %                   -> TwoTrodeRig
%     %                   -> PiezoRig 
%     %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
%     %                                   -> TwoPhotonPiezoRig     
%     %                   -> CameraRig    -> CameraEPhysRig 
%     %                                   -> PiezoCameraRig 
%     %                   -> PGRCameraRig -> PGREPhysRig
%     %                                   -> PGRPiezoRig % This setup is for
%     %                                   a digital output that requires same
%     %                                   session, and same input and output
%     %                                   sample rates
%     
%     properties (Constant, Abstract)
%         rigName
%         IsContinuous;
%     end
%     
%     properties (Hidden, SetAccess = protected)
%         TrialDisplay
%         TestDisplay
%     end
%     
%     properties (SetAccess = protected)
%         devices
%         aiSession
%         aoSession
%         outputs
%         inputs
%         params
%     end
%     
%     properties (SetAccess = private)
%     end
%     
%     events
%         StimulusOutsideBounds
%         StartRun
%         StartTrial
%         SaveData
%         DataSaved
%     end
%     
%     methods
%         function obj = Rig(varargin)
%             if ~isacqpref('AcquisitionHardware','rigDev')
%                 setacqpref('AcquisitionHardware','rigDev','Dev1')
%                 setacqpref('AcquisitionHardware','modeDev','Dev1')
%                 setacqpref('AcquisitionHardware','gainDev','Dev1')
%                 setacqpref('AcquisitionHardware','triggerChannelIn','PFI0')
%                 setacqpref('AcquisitionHardware','triggerChannelOut','PFI2')
%                 disp(getacqpref('AcquisitionHardware'));
%                 error('The acquisition hardware preferences were not set. Check the above preferences for accuracy')
%             end
%             obj.aiSession = daq.createSession('ni');
%             obj.aoSession = daq.createSession('ni');            
%             obj.defineParameters();
%             obj.params = obj.getDefaults();
%         end
%         
%         function addDevice(obj,devicekey,deviceclass,varargin)
%             
%             eval(['obj.devices.(devicekey) = ' deviceclass '(varargin{:});']);
%             obj.setSessions(devicekey);
%         end
%         
%         function in = run(obj,protocol,varargin)
%             
%             if nargin>2
%                 repeats = varargin{1};
%             else
%                 repeats = 1;
%             end
%             if isprop(obj,'TrialDisplay') && ~isempty(obj.TrialDisplay)
%                 if ishandle(obj.TrialDisplay)
%                     delete(obj.TrialDisplay);
%                 end
%             end
%             obj.setDisplay([],[],protocol);
%             obj.setTestDisplay();
% 
%             obj.aiSession.Rate = protocol.params.sampratein;
%             obj.aiSession.NumberOfScans = length(makeInTime(protocol));
%             obj.aoSession.Rate = protocol.params.samprateout;
%             
%             if obj.params.interTrialInterval >0;
%                 t = timerfind('Name','ITItimer');
%                 if isempty(t)
%                     t = timer;
%                 end
%                 t.StartDelay = obj.params.interTrialInterval;
%                 t.TimerFcn = @(tObj, thisEvent) ... 
%                     fprintf('%.1f sec inter trial\n',tObj.StartDelay);
%                 set(t,'Name','ITItimer')
%             end
%             notify(obj,'StartRun');
%             for n = 1:repeats
%                 while protocol.hasNext()
%                     obj.setAOSession(protocol);
%                     notify(obj,'StartTrial',PassProtocolData(protocol));
%                     %disp(obj.aoSession)
%                     obj.aoSession.startBackground; % Start the session that receives start trigger first
%                     
%                     %disp(obj.aiSession)
%                     % Collect input
%                     in = obj.aiSession.startForeground; % both amp and signal monitor input
%                     %disp(obj.aiSession)
%                     obj.transformInputs(in);
%                     if obj.params.interTrialInterval >0;
%                         t = timerfind('Name','ITItimer');
%                         start(t)
%                         wait(t)
%                     end
%                     notify(obj,'SaveData');
%                     obj.displayTrial(protocol);
%                     notify(obj,'DataSaved');
%                 end
%                 protocol.reset;
%             end
%         end
%                         
%         function setAOSession(obj,protocol)
%             % figure out what the stim vector should be
%             obj.transformOutputs(protocol.next());
%             obj.aoSession.wait;
%             obj.aoSession.queueOutputData(obj.outputs.datacolumns);
%         end
%                         
%         function transformOutputs(obj,out)
%             
%             % check that amps are in the right modes
%             checkAmplifierModes(obj,out);
%             
%             % loop over devices, transforming data
%             devs = fieldnames(obj.devices);
%             for d = 1:length(devs)
%                 dev = obj.devices.(devs{d});
%                 if ~isempty(dev)
%                     out = dev.transformOutputs(out);
%                 end
%             end
%             
%             % make the stims the right size (keeping the array if it's the
%             % same
%             outnames = fieldnames(out);
%             if size(obj.outputs.datacolumns,1) ~= length(out.(outnames{1}))
%                 if sum(obj.outputs.datavalues ~= obj.outputs.datacolumns(end,:))
%                     obj.outputs.datavalues = obj.outputs.datacolumns(end,:);
%                 end
%                 % column array of outputs from the outvalues vector
%                 obj.outputs.datacolumns = repmat(obj.outputs.datavalues(:)',...
%                     length(out.(outnames{1})),1);
%             end
%             
%             % get outvals end values just in case
%             if sum(obj.outputs.datavalues ~= obj.outputs.datacolumns(end,:))
%                 obj.outputs.datavalues = obj.outputs.datacolumns(end,:);
%                 for c = 1:size(obj.outputs.datacolumns,2)
%                     obj.outputs.datacolumns(:,c) = obj.outputs.datavalues(c);
%                 end
%             end
%             
%             % add a little step to the beginning of trials
%             if strcmp(obj.devices.amplifier.mode,'IClamp')
%                 testoutname = 'current';
%             elseif strcmp(obj.devices.amplifier.mode,'VClamp')
%                 testoutname = 'voltage';
%             else 
%                 testoutname = '';
%             end
%             if ~isempty(testoutname) && obj.params.(['test' testoutname 'stepamp']) ~= 0
%                 teststep_start = obj.params.teststep_start*obj.params.samprateout;
%                 teststep_dur = obj.params.teststep_dur*obj.params.samprateout;
%                 
%                 teststep.(testoutname) = zeros(size(out.(outnames{1})));
%                 teststep.(testoutname)(teststep_start+1:teststep_start+teststep_dur) = obj.params.(['test' testoutname 'stepamp']);
%                 teststep = obj.devices.amplifier.transformOutputs(teststep);
%                 if ismember(testoutname,outnames)
%                     out.(testoutname) = out.(testoutname)+teststep.(testoutname);
%                 else
%                     out.(testoutname) = teststep.(testoutname);
%                 end
%             end
%             
%             for ch = 1:length(obj.aoSession.Channels)
%                 if isfield(out,obj.aoSession.Channels(ch).Name)
%                     obj.outputs.datacolumns(:,ch) = out.(obj.aoSession.Channels(ch).Name);
%                 end
%             end
%         end
%         
%         function transformInputs(obj,in)
%             for ch = 1:length(obj.aiSession.Channels)
%                 chids(ch) = str2double(regexprep(obj.aiSession.Channels(ch).ID,'ai',''));
%             end
%             [~,o] = sort(chids);
%             % go from highest channel id to lowest (ai7 -> ai0).  This
%             % enters scaled output (always ai0) for either V or I
%             for ch = length(o):-1:1
%                 obj.inputs.data.(obj.aiSession.Channels(o(ch)).Name) = in(:,o(ch));
%             end
%             devs = fieldnames(obj.devices);
%             for d = 1:length(devs)
%                 dev = obj.devices.(devs{d});
%                 if ~isempty(dev)
%                     obj.inputs.data = dev.transformInputs(obj.inputs.data);
%                 end
%             end
%             
%             if strcmp(obj.devices.amplifier.mode,'IClamp')
%                 testoutname = 'voltage';
%             elseif strcmp(obj.devices.amplifier.mode,'VClamp')
%                 testoutname = 'current';
%             else
%                 testoutname = '';
%             end
%             if ~isempty(testoutname) && obj.params.(['test' testoutname 'stepamp']) ~= 0
%                 teststep_start = obj.params.teststep_start*obj.params.samprateout;
%                 teststep_dur = obj.params.teststep_dur*obj.params.samprateout;
%                 if teststep_dur>0;
%                     
%                 testresp_i = mean(obj.inputs.data.(testoutname)(1:teststep_start));
%                 testresp_f = mean(obj.inputs.data.(testoutname)(teststep_start+teststep_dur-teststep_start+1:teststep_start+teststep_dur));
%                 testresp_min = min(obj.inputs.data.(testoutname)(teststep_start:teststep_start+teststep_dur/4));
%                 testresp_max = max(obj.inputs.data.(testoutname)(teststep_start+teststep_dur:teststep_start+teststep_dur+teststep_dur/4));
%                 
%                 if strcmp(obj.devices.amplifier.mode,'IClamp')
%                     R = (testresp_f-testresp_i)/obj.params.testcurrentstepamp;
%                     colr = [1 0 1];
%                     access = nan;
%                 elseif strcmp(obj.devices.amplifier.mode,'VClamp')
%                     R = obj.params.testvoltagestepamp/(testresp_f-testresp_i);
%                     colr = [0 1 1];
%                     access = obj.params.testvoltagestepamp/mean([(testresp_min-testresp_i) -abs(testresp_max-testresp_i)]);
%                 end
%                 
%                 ax = findobj(obj.TestDisplay,'type','axes');
%                 line(now,R,'linestyle','none','marker','o','markersize',3,'markerfacecolor',colr,'markeredgecolor',colr,'parent',ax);
%                 if ~isnan(access), line(now,access,'linestyle','none','marker','+','markersize',3,'markerfacecolor',colr,'markeredgecolor',colr,'parent',ax); end
% 
%                 bl = findobj(ax,'tag','baseline');
%                 x = get(bl,'xdata');
%                 x = [x(1) now];
%                 set(bl,'xdata',x);       
%                 end
%             end
% 
%         end
%                         
%         function setParams(obj,varargin)
%             p = inputParser;
%             p.PartialMatching = 0;
%             names = fieldnames(obj.params);
%             for i = 1:length(names)
%                 p.addParameter(names{i},obj.params.(names{i}),@(x) strcmp(class(x),class(obj.params.(names{i}))));
%             end
%             parse(p,varargin{:});
%             results = fieldnames(p.Results);
%             for r = 1:length(results)
%                 obj.params.(results{r}) = p.Results.(results{r});
%             end
%         end
%         
%         function defaults = getDefaults(obj)
%             % rmacqpref('defaultsTwoPhotonEPhysRig')
%             % rmacqpref('defaultsBasicEPhysRig')
%             % rmacqpref('defaultsPiezoRig')
%             
%             defaults = getacqpref(['defaults',obj.rigName]);
%             if isempty(defaults)
%                 defaultsnew = [fieldnames(obj.params),struct2cell(obj.params)]';
%                 obj.setDefaults(defaultsnew{:});
%                 defaults = obj.params;
%             end
%         end
%         
%         function applyDefaults(obj)
%             obj.params = obj.getDefaults();
%         end
%         
%         function setDefaults(obj,varargin)
%             p = inputParser;
%             names = fieldnames(obj.params);
%             for i = 1:length(names)
%                 addOptional(p,names{i},obj.params.(names{i}));
%             end
%             parse(p,varargin{:});
%             results = fieldnames(p.Results);
%             for r = 1:length(results)
%                 setacqpref(['defaults',obj.rigName],...
%                     [results{r}],...
%                     p.Results.(results{r}));
%             end
%         end
%         
%         function setDisplay(obj,fig,evnt,varargin)
%             if isempty(obj.TrialDisplay) || ~ishghandle(obj.TrialDisplay) 
%                 scrsz = get(0,'ScreenSize');
%                 obj.TrialDisplay = figure(...
%                     'Position',[8 320 560 420],...
%                     'NumberTitle', 'off',...
%                     'Name', 'Rig Display');%,...'DeleteFcn',@obj.setDisplay);
%             end
%         end
%         
%         function setTestDisplay(obj,fig,evnt,varargin)
%             if isempty(obj.TestDisplay) || ~ishghandle(obj.TestDisplay)
%                 obj.TestDisplay = findobj('type','figure','Name', 'Test Display');
%                 if isempty(obj.TestDisplay);                
%                     obj.TestDisplay = figure(...
%                         'Position',[8 832 560 165],...
%                         'NumberTitle', 'off',...
%                         'Name', 'Test Display',...
%                         'DeleteFcn',@saveDeletedFigure_callback);
%                 end
%                 ax = subplot(1,1,1,'parent',obj.TestDisplay);
%                 bl = findobj(ax,'tag','baseline');
%                 if isempty(bl)
%                     line([now,now+5],[0 0],'color',[.8 .8 .8],'parent',ax,'tag','baseline');
%                 end
%                 set(ax,'XTickLabel',{[]});
%                 ylabel('R (m -IC, c - VC)')
%                 ylim(ax,[-.5 1])
%             end
%         end
%         
%         function rigStruct = getRigStruct(obj)
%             rigStruct.rigConstructor = str2func(obj.rigName);
%             rigStruct.outputs = obj.outputs.portlabels;
%             rigStruct.inputs = obj.inputs.portlabels;
%             rigStruct.devices = obj.devices;
%             rigStruct.timestamp = now;
%         end
%         
%         function delete(obj)
%             close(obj.TrialDisplay)
%             fprintf('SESSIONS RELEASED\n');
%             fprintf('%s DELETED\n',obj.rigName);
%             release(obj.aiSession);
%             release(obj.aoSession);
%             delete(obj.aiSession);
%             delete(obj.aoSession);
%             delete@handle(obj)
%         end
%     end
%     
%     methods (Access = protected)
%         
%         function defineParameters(obj)
%             obj.params.sampratein = 50000;
%             obj.params.samprateout = 50000;
%             obj.params.testcurrentstepamp = -5;
%             obj.params.testvoltagestepamp = -2.5;
%             obj.params.teststep_start = 0.010;
%             obj.params.teststep_dur = 0.050;
%             obj.params.interTrialInterval = 0;
%         end
%         
%         function setSessions(obj,varargin)
%             % Establish all the output channels and input channels in one
%             % place
%             rigDev = getacqpref('AcquisitionHardware','rigDev');
%             
%             if nargin>1
%                 keys = varargin;
%             else
%                 keys = fieldnames(obj.devices);
%             end
%             for k = 1:length(keys);
%                 dev = obj.devices.(keys{k});
%                 for i = 1:length(dev.outputPorts)
%                     % configure AO
%                     ch = obj.aoSession.addAnalogOutputChannel(rigDev,dev.outputPorts(i), 'Voltage');
%                     ch.Name = dev.outputLabels{i};
%                     obj.outputs.portlabels{dev.outputPorts(i)+1} = dev.outputLabels{i};
%                     obj.outputs.device{dev.outputPorts(i)+1} = dev;
%                     % use the current vals to apply to outputs
%                 end
%                 % obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
%                 obj.outputs.datavalues = zeros(size(obj.aoSession.Channels));
%                 obj.outputs.datacolumns = obj.outputs.datavalues;
% 
%                 for i = 1:length(dev.inputPorts)
%                     ch = obj.aiSession.addAnalogInputChannel(rigDev,dev.inputPorts(i), 'Voltage'); 
%                     ch.InputType = 'SingleEnded';
%                     ch.Name = dev.inputLabels{i};
%                     obj.inputs.portlabels{dev.inputPorts(i)+1} = dev.inputLabels{i};
%                     obj.inputs.device{dev.inputPorts(i)+1} = dev;
%                     % obj.inputs.data.(dev.inputLabels{i}) = [];
%                 end
%             end
%         end
%         
%         function chNames = getChannelNames(obj)
%             for ch = 1:length(obj.aoSession.Channels)
%                 chNames.out{ch} = obj.aoSession.Channels(ch).Name;
%             end
%             for ch = 1:length(obj.aiSession.Channels)
%                 chNames.in{ch} = obj.aiSession.Channels(ch).Name;
%             end
%         end
%         
%         function obj = checkAmplifierModes(obj,out)
%             % run a check for the mode of the amplifier and throw error
%             % elegantly
%             if sum(strcmp(fieldnames(out),'current')) &&...
%                     sum(out.current ~= out.current(1)) &&...
%                     strcmp(obj.devices.amplifier.mode,'VClamp')
%                 error('Amplifier in VClamp but no current out')
%             elseif sum(strcmp(fieldnames(out),'voltage')) &&...
%                     sum(out.voltage ~= out.voltage(1)) &&...
%                     strcmp(obj.devices.amplifier.mode,'IClamp')
%                 error('Amplifier in IClamp but voltage command')
%             end
%         end
%     end
% end



