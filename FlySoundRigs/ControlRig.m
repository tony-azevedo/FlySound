classdef ControlRig < handle
    % current hierarchy:
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig
    %       -> TwoAmpRig -> TwoTrodeRig
    %                   -> Epi2TRig
    %                   -> CameraTwoAmpRig    -> CameraEpi2TRig
    %                                         -> Camera2TRig
    %                   -> CameraBaslerTwoAmpRig    -> CameraBaslerEpi2TRig
    %                                               -> CameraBasler2TRig
    %                                               -> CameraBaslerPiezoEpi2TRig    
    
    
    properties (Constant, Abstract)
        rigName
        IsContinuous;
    end
    
    properties (Hidden, SetAccess = protected)
        TrialDisplay
        TestDisplay
    end
    
    properties (SetAccess = protected)
        devices
        % aiSession
        inputchannelidx
        aoSession
        outputchannelidx
        outputs
        inputs
        params
    end
    
    properties (SetAccess = private)
    end
    
    events
        StimulusOutsideBounds
        StartRun_Control
        StartTrial_Control
        StartTrialCamera_Control
        EndTrial_Control
        SaveData_Control
        DataSaved_Control
        IncreaseTrialNum_Control
        EndRun_Control
        EndTimer_Control
    end
    
    methods
        function obj = ControlRig(varargin)
            if ~isacqpref('ControlHardware','rigDev')
                setacqpref('ControlHardware','rigDev','Dev2')
                disp(getacqpref('ControlHardware'));
                error('The control hardware preferences were not set. Check the above preferences for accuracy')
            end
            if isempty(obj.aoSession)
                obj.aoSession = daq.createSession('ni');
            else
                fprintf(1,'%s: Daq object already created\n',obj.rigName);
            end
            obj.defineParameters();
            obj.params = obj.getDefaults();
        end
        
        function addDevice(obj,devicekey,deviceclass,varargin)
            
            eval(['obj.devices.(devicekey) = ' deviceclass '(varargin{:});']);
            obj.setSessions(devicekey);
        end
        
        function in = run(obj,protocol,varargin)
            
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
            
            protocol.setParams('-q','samprateout',protocol.params.sampratein);
            obj.aoSession.Rate = protocol.params.samprateout;
            
            if obj.params.interTrialInterval >0
                t = timerfind('Name','ITItimer');
                if isempty(t)
                    t = timer;
                end
                t.StartDelay = obj.params.interTrialInterval;
                t.TimerFcn = @(tObj, thisEvent) ... 
                    fprintf('%.1f sec inter trial\n',tObj.StartDelay);
                set(t,'Name','ITItimer')
            end
            notify(obj,'StartRun_Control');
            for n = 1:repeats
                while protocol.hasNext()
                    obj.setAOSession(protocol);
                    
                    % setup the data logger
                    notify(obj,'StartTrial_Control',PassProtocolData(protocol));
                    % start the videoinput object
                    % notify(obj,'StartTrialCamera');
                    
                    in = obj.aoSession.startForeground; % both amp and signal monitor input
                    wait(obj.aoSession);
                    notify(obj,'EndTrial_Control');
                    
                    % disp(obj.aiSession)
                    % obj.transformInputs(in);
                    if obj.params.interTrialInterval >0
                        t = timerfind('Name','ITItimer');
                        start(t)
                        wait(t)
                    end
                    notify(obj,'SaveData_Control');
                    % obj.displayTrial(protocol);
                    notify(obj,'DataSaved_Control');
                    notify(obj,'IncreaseTrialNum_Control');
                    obj.params.trialnum = obj.params.trialnum+1;
                end
                protocol.reset;
            end
            notify(obj,'EndRun_Control');
        end
                        
        function setAOSession(obj,protocol)
            % figure out what the stim vector should be
            obj.transformOutputs(protocol.next());
            obj.aoSession.wait;
            obj.aoSession.queueOutputData(obj.outputs.datacolumns);
            % in case you need to flip a bit or something
            obj.aoSession.UserData.CurrentOutput = obj.outputs.datacolumns(end,:);
        end
                        
        function transformOutputs(obj,out)
            
            % check that amps are in the right modes
            % checkAmplifierModes(obj,out);
            
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
            
            if isfield(obj.devices,'amplifier')
                % add a little step to the beginning of trials
                if strcmp(obj.devices.amplifier.mode,'IClamp')
                    testoutname = 'current';
                elseif strcmp(obj.devices.amplifier.mode,'VClamp')
                    testoutname = 'voltage';
                else
                    testoutname = '';
                end
                if ~isempty(testoutname) && obj.params.(['test' testoutname 'stepamp']) ~= 0
                    teststep_start = obj.params.teststep_start*obj.params.samprateout;
                    teststep_dur = obj.params.teststep_dur*obj.params.samprateout;
                    
                    teststep.(testoutname) = zeros(size(out.(outnames{1})));
                    teststep.(testoutname)(teststep_start+1:teststep_start+teststep_dur) = obj.params.(['test' testoutname 'stepamp']);
                    teststep = obj.devices.amplifier.transformOutputs(teststep);
                    if ismember(testoutname,outnames)
                        out.(testoutname) = out.(testoutname)+teststep.(testoutname);
                    else
                        out.(testoutname) = teststep.(testoutname);
                    end
                end
            end
            
            for ch = 1:length(obj.outputchannelidx)
                if isfield(out,obj.aoSession.Channels(obj.outputchannelidx(ch)).Name)
                    obj.outputs.datacolumns(:,ch) = out.(obj.aoSession.Channels(obj.outputchannelidx(ch)).Name);
                end
            end
        end
                        
        function setParams(obj,varargin)
            p = inputParser;
            p.PartialMatching = 0;
            names = fieldnames(obj.params);
            for i = 1:length(names)
                p.addParameter(names{i},obj.params.(names{i}),@(x) strcmp(class(x),class(obj.params.(names{i}))));
            end
            parse(p,varargin{:});
            results = fieldnames(p.Results);
            for r = 1:length(results)
                obj.params.(results{r}) = p.Results.(results{r});
            end
        end
        
        function defaults = getDefaults(obj)
            defaults = getacqpref(['defaults',obj.rigName]);
            if isempty(defaults)
                defaultsnew = [fieldnames(obj.params),struct2cell(obj.params)]';
                obj.setDefaults(defaultsnew{:});
                defaults = obj.params;
            end
        end
        
        function applyDefaults(obj)
            obj.params = obj.getDefaults();
        end
        
        function setDefaults(obj,varargin)
            p = inputParser;
            names = fieldnames(obj.params);
            for i = 1:length(names)
                addOptional(p,names{i},obj.params.(names{i}));
            end
            parse(p,varargin{:});
            results = fieldnames(p.Results);
            for r = 1:length(results)
                setacqpref(['defaults',obj.rigName],...
                    [results{r}],...
                    p.Results.(results{r}));
            end
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            if isempty(obj.TrialDisplay) || ~ishghandle(obj.TrialDisplay) 
                scrsz = get(0,'ScreenSize');
                obj.TrialDisplay = figure(...
                    'Position',[8 320 560 420],...
                    'NumberTitle', 'off',...
                    'Name', 'Rig Display');%,...'DeleteFcn',@obj.setDisplay);
            end
        end
        
        function setTestDisplay(obj,fig,evnt,varargin)
            if isempty(obj.TestDisplay) || ~ishghandle(obj.TestDisplay)
                obj.TestDisplay = findobj('type','figure','Name', 'Test Display');
                if isempty(obj.TestDisplay);                
                    obj.TestDisplay = figure(...
                        'Position',[8 832 560 165],...
                        'NumberTitle', 'off',...
                        'Name', 'Test Display',...
                        'CloseRequestFcn',@saveDeletedFigure_callback);
                end
                ax = subplot(1,1,1,'parent',obj.TestDisplay);
                bl = findobj(ax,'tag','baseline');
                if isempty(bl)
                    line([now,now+5],[0 0],'color',[.8 .8 .8],'parent',ax,'tag','baseline');
                end
                set(ax,'XTickLabel',{[]});
                ylabel('R (m -IC, c - VC)')
                ylim(ax,[-.5 1])
            end
        end
        
        function rigStruct = getRigStruct(obj)
            rigStruct.rigConstructor = str2func(obj.rigName);
            rigStruct.outputs = obj.outputs.portlabels;
            if isfield(obj.outputs,'digitalPortlabels')
                if length(rigStruct.outputs)<getacqpref('AcquisitionHardware','AnalogOutN')
                    rigStruct.outputs{getacqpref('AcquisitionHardware','AnalogOutN')} = [];
                end
                rigStruct.outputs = [rigStruct.outputs obj.outputs.digitalPortlabels];
            end
            % rigStruct.inputs = obj.inputs.portlabels;
            % if isfield(obj.inputs,'digitalPortlabels')
            %     if length(rigStruct.inputs)<getacqpref('AcquisitionHardware','AnalogInN')
            %         rigStruct.inputs{getacqpref('AcquisitionHardware','AnalogInN')} = [];
            %     end
            %     rigStruct.inputs = [rigStruct.inputs obj.inputs.digitalPortlabels];
            % end
            dnames = fieldnames(obj.devices);
            for i = 1:length(dnames)              
                rigStruct.devices.(dnames{i}) = obj.devices.(dnames{i}).deviceName;
            end
            rigStruct.timestamp = now;
        end
        
        function delete(obj)
            close(obj.TrialDisplay)
            fprintf('SESSIONS RELEASED\n');
            fprintf('%s DELETED\n',obj.rigName);
            release(obj.aoSession);
            delete(obj.aoSession);
            delete@handle(obj)
        end
    end
    
    methods (Access = protected)
        
        function defineParameters(obj)
            % obj.params.sampratein = 10000;
            obj.params.samprateout = 50000;
            obj.params.testcurrentstepamp = -5;
            obj.params.testvoltagestepamp = -2.5;
            obj.params.teststep_start = 0.010;
            obj.params.teststep_dur = 0.050;
            obj.params.interTrialInterval = 0;
            obj.params.trialnum = 0;
        end
        
        function setSessions(obj,varargin)
            % Establish all the output channels and input channels in one
            % place
            rigDev = getacqpref('ControlHardware','rigDev');
            
            if nargin>1
                keys = varargin;
            else
                keys = fieldnames(obj.devices);
            end
            for k = 1:length(keys)
                fprintf('\tAdding %s\n',keys{k}) 
                dev = obj.devices.(keys{k});
                for i = 1:length(dev.outputPorts)
                    % configure AO
                    fprintf('\t\t%s\n',dev.outputLabels{i}) 
                    ch = obj.aoSession.addAnalogOutputChannel(rigDev,dev.outputPorts(i), 'Voltage');
                    ch.TerminalConfig = 'SingleEnded';
                    ch.Name = dev.outputLabels{i};
                    obj.outputs.portlabels{dev.outputPorts(i)+1} = dev.outputLabels{i};
                    obj.outputs.device{dev.outputPorts(i)+1} = dev;
                    % use the current vals to apply to outputs
                end
                % obj.outputs.labels = obj.outputs.portlabels(strncmp(obj.outputs.portlabels,'',0));
                
                for i = 1:length(dev.digitalOutputPorts)
                    fprintf('\t\t%s\n',dev.digitalOutputLabels{i}) 
                    ch = obj.aoSession.addDigitalChannel(rigDev,['Port0/Line' num2str(dev.digitalOutputPorts(i))], 'OutputOnly');
                    ch.Name = dev.digitalOutputLabels{i};
                    obj.outputs.digitalPortlabels{dev.digitalOutputPorts(i)+1} = dev.digitalOutputLabels{i};
                    obj.outputs.device{dev.digitalOutputPorts(i)+getacqpref('AcquisitionHardware','AnalogOutN')+1} = dev;
                end
                if contains(dev.deviceName,'_Control')
                    for i = 1:length(dev.digitalInputPorts)
                        fprintf('\t\t%s\t',dev.digitalInputLabels{i})
                        tic
                        ch = obj.aoSession.addDigitalChannel(rigDev,['Port0/Line' num2str(dev.digitalInputPorts(i))], 'InputOnly');
                        toc
                        ch.Name = dev.digitalInputLabels{i};
                        obj.inputs.digitalPortlabels{dev.digitalInputPorts(i)+1} = dev.digitalInputLabels{i};
                        obj.inputs.device{dev.digitalInputPorts(i)+getacqpref('AcquisitionHardware','AnalogInN')+1} = dev;
                        % obj.inputs.data.(dev.inputLabels{i}) = [];
                    end
                end
            end
            obj.sessionColumnsAndIndices();

        end
        
        function sessionColumnsAndIndices(obj)
            obj.outputs.datavalues = [];
            obj.outputchannelidx = [];
            obj.inputchannelidx = [];
            for ch = 1:length(obj.aoSession.Channels)
                aord = obj.aoSession.Channels(ch).ID(1);
                switch aord
                    case 'p'
                        switch obj.aoSession.Channels(ch).MeasurementType
                            case 'OutputOnly'
                                obj.outputs.datavalues(end+1) = 0;
                                obj.outputchannelidx(end+1) = ch;
                            case 'InputOnly'
                                % fprintf('ControlRigs should not have inputs\n')
                                obj.inputchannelidx(end+1) = ch;
                                % error('ControlRigs should not have inputs')
                            otherwise
                                error('Not able to deal with Bidirectional Digital channels')
                        end
                    case 'a'
                         switch obj.aoSession.Channels(ch).ID(2)
                             case 'o'
                                obj.outputs.datavalues(end+1) = 0;
                                obj.outputchannelidx(end+1) = ch;
                             case 'i'
                                error('ControlRigs should not have inputs')
                             otherwise
                         end
                end
            end
            obj.outputs.datacolumns = obj.outputs.datavalues;
        end
        
        function [chNames,avsd] = getChannelNames(obj)
            for ch = 1:length(obj.outputchannelidx)
                chNames.out{ch} = obj.aoSession.Channels(obj.outputchannelidx(ch)).Name;
                avsd.out(ch) = strcmp('ao',obj.aoSession.Channels(obj.outputchannelidx(ch)).ID(1:2));
            end
            for ch = 1:length(obj.inputchannelidx)
                chNames.in{ch} = obj.aoSession.Channels(obj.inputchannelidx(ch)).Name;
                avsd.in(ch) = strcmp('ai',obj.aoSession.Channels(obj.inputchannelidx(ch)).ID(1:2));
            end

        end
        
    end
end
