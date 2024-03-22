classdef Acquisition < handle
    
    properties (Constant) 
    end
    
    properties (Hidden, SetAccess = protected)
        n               % current trial
        expt_n          % current experiment trial
        block_n
        D               % main directory
        dataFileName    % filename for data struct
        notesFileName
        notesFileID
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = protected)
        modusOperandi   % simulate or run?
        flygenotype
        rig
        protocol % can I change this object if it's protected?
        analyzelistener
        flynumber
        cellnumber 
        amplifier1Device
        tags
        userData
    end
    
    properties (SetObservable, AbortSet)
        analyze
    end
    
    % Define an event called InsufficientFunds
    events
    end
    
    methods
        function obj = Acquisition(varargin)

            global acqprefdir
            acqprefdir = 'C:\Users\tony\Code\FlySound\Preferences';
            
            obj.setupDaqDevices;
            
            if ~isfield(obj.userData,'CameraBaslerPCState')
                obj.userData.CameraBaslerPCState = 0;
                h = findall(0,'type','uicontrol','tag','start_button');
                obj.userData.CameraControl = h;
            end
            
            if ~isempty(obj.userData.CameraControl) && get(obj.userData.CameraControl,'Value')
                set(obj.userData.CameraControl,'Value',0)
                PatchCameraBasler('start_button_Callback',obj.userData.CameraControl,[],[])
                obj.userData.CameraBaslerPCState = 1;
            end
            
            obj.tags = {};
            obj.setIdentifiers(varargin{:})
            obj.updateFileNames()
            
            addlistener(...
                obj,...
                'analyze',...
                'PostSet',@obj.setAnalysisFlag);

            obj.chooseDefaultProtocol;
            
            if obj.userData.CameraBaslerPCState
                set(obj.userData.CameraControl,'Value',1)
                PatchCameraBasler('start_button_Callback',obj.userData.CameraBaslerPCState,[],[])
                obj.userData.CameraBaslerPCState = 1;
            end


        end
        
        function run(obj,varargin)
            if nargin>1
                repeats = varargin{1};
            else
                repeats = 1;
            end
            
            if ~isfield(obj.userData,'CameraBaslerPCState')
                obj.userData.CameraBaslerPCState = 0;
                h = findall(0,'type','uicontrol','tag','start_button');
                obj.userData.CameraControl = h;
            end
            
            if ~isempty(obj.userData.CameraControl) && get(obj.userData.CameraControl,'Value')
                set(obj.userData.CameraControl,'Value',0)
                PatchCameraBasler('start_button_Callback',obj.userData.CameraControl,[],[])
                obj.userData.CameraBaslerPCState = 1;
            end
            
            if isa(obj.rig,'EPhysRig')
                obj.protocol.setParams('-q','mode',obj.rig.devices.amplifier.mode);
                obj.protocol.setParams('-q','gain',obj.rig.devices.amplifier.gain);
                if isa(obj.rig.devices.amplifier,'MultiClamp700B')
                    obj.protocol.setParams('-q','secondary_gain',obj.rig.devices.amplifier.secondary_gain);
                end
            end

            obj.block_n = obj.block_n+1;
            obj.protocol.reset;
            obj.rig.run(obj.protocol,repeats);
            if ~isa(obj.rig,'ContinuousRig')
                systemsound('Notify');
            end
            
            if obj.userData.CameraBaslerPCState
                set(obj.userData.CameraControl,'Value',1)
                PatchCameraBasler('start_button_Callback',obj.userData.CameraControl,[],[])
                obj.userData.CameraBaslerPCState = 1;
            end

        end
        
        function chooseDefaultProtocol(obj)
            % set a simple protocol
            obj.setProtocol('Sweep');
            obj.analyze = 0;
        end
            
        function setProtocol(obj,prot,varargin)
            if ~isfield(obj.userData,'CameraBaslerPCState')
                obj.userData.CameraBaslerPCState = 0;
                h = findall(0,'type','uicontrol','tag','start_button');
                obj.userData.CameraControl = h;
            end
            
            if ~isempty(obj.userData.CameraControl) && get(obj.userData.CameraControl,'Value')
                set(obj.userData.CameraControl,'Value',0)
                PatchCameraBasler('start_button_Callback',obj.userData.CameraControl,[],[])
                obj.userData.CameraBaslerPCState = 1;
            end
            
            if ~isempty(obj.rig) && obj.rig.IsContinuous
                obj.rig.stop
            end
            
            protstr = ['obj.protocol = ' prot '('];
            if nargin>2
                for i = 1:length(varargin)
                    protstr = [protstr '''' varargin{i} ''',']; %#ok<AGROW>
                end
                protstr = protstr(1:end-1);
            end
            eval([protstr ');']);
            obj.findPrevTrials();
            obj.setRig();
            addlistener(obj.protocol,'StimulusProblem',@obj.handleStimulusProblem);
            fprintf(1,'Protocol Set to: \n');
            obj.protocol.showParams          
            
        end
        
        function comment(obj,varargin)
            if nargin > 1
                com = varargin{1};
            else
                com = inputdlg('Enter comment:', 'Comment', [10 120]);
                com = strcat(com{:});
            end
            obj.notesFileID = fopen(obj.notesFileName,'a');
            fprintf(obj.notesFileID,'\n\t****************\n\t%s\n\t%s\n\t****************\n',datestr(clock,31),com);
            fprintf(1,'\n\t****************\n\t%s\n\t%s\n\t****************\n',datestr(clock,31),com);
            fclose(obj.notesFileID);

        end

        function tag(obj,varargin)
            if nargin > 1
                tag = varargin;
            else
                tag = inputdlg('Enter tag:', 'Tag', [1 50]);
            end
            for t = 1:length(tag)
                if ~sum(strcmp(obj.tags,tag{t}))
                    obj.tags{end+1} = tag{t};
                end
            end
            obj.comment(sprintf('%s; ',(obj.tags{:})));
        end
        
        function untag(obj,varargin)
            if nargin > 1
                untag = varargin;
            else
                untag = inputdlg('Enter tag:', 'Tag', [1 50]);
                untag = strcat(untag{:});
                if isempty(untag)
                    untag = obj.tags;
                end
            end
            
            for t = 1:length(untag)
                % convert nums or strings to strings
                untagel = num2str(untag{t});
                obj.tags = obj.tags(~strcmp(obj.tags,untagel));
            end

        end
        
        function clearTags(obj)
            obj.tags = {};
        end

        function showFileStem(obj)
            name = [obj.D,'\',obj.protocol.protocolName,'_Raw_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_', ...
                '%s.mat'];
            fprintf(1,'%s\n%s\n%s\n',obj.D,obj.dataFileName,name);
        end
        
        function name = getDataFileName(obj)
            name = obj.dataFileName;
        end
        
        function name = getRawFileStem(obj)
            name = [obj.D,'\',obj.protocol.protocolName,'_Raw_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_', ...
                '%d.mat'];
        end
        
        function acqDevices = setupDaqDevices(obj)
            % This function is the main function for ensuring that the
            % correct daq devices are connected and working.
            % This function is hard coded and will need to be edited for a
            % new installation
            fprintf('Setting up daq devices\n')
            ah = getacqpref('AcquisitionHardware');
            % ch = getacqpref('ControlHardware');
            
            daqs = daq.getDevices;
            if ~isfield(ah,'rigDev') || strcmp(ah.rigDev,'')
                daq.getDevices;
                yesorno = questdlg('No rigs have been setup. Proceed?');
                switch yesorno
                    case 'Yes'
                        setacqpref('AcquisitionHardware','rigDev','')
                        setacqpref('AcquisitionHardware','modeDev','')
                        setacqpref('AcquisitionHardware','gainDev','')
                        setacqpref('AcquisitionHardware','triggeredDev','')
                        setacqpref('ControlHardware','rigDev','')
                        
                    otherwise
                        error('Check daq devices, change setupDaqDevices function, then proceed')
                end
            end     
            ah = getacqpref('AcquisitionHardware');
            ch = getacqpref('ControlHardware');

            % This is the hard coded part
            for d = 1:length(daqs)
                % The USB device is the acquisition rig
                if ~isempty(regexp(daqs(d).Description,'USB','once'))
                    if ~strcmp(daqs(d).ID, ah.rigDev)
                        yesorno = questdlg(['Change Rig Device from ',ah.rigDev,' to ',daqs(d).ID,'?']);
                        switch yesorno
                            case 'Yes'
                                setacqpref('AcquisitionHardware','rigDev',daqs(d).ID)
                                setacqpref('AcquisitionHardware','modeDev',daqs(d).ID)
                                setacqpref('AcquisitionHardware','gainDev',daqs(d).ID)
                            otherwise
                                error('Check daq devices, change setupDaqDevices function, then proceed')
                        end
                    else
                        continue
                    end
                elseif length(daqs(d).Subsystems(2).ChannelNames)==4
                    % The device with 4 ao channels is the control rig    
                    if ~strcmp(daqs(d).ID, ch.rigDev)
                        yesorno = questdlg(['Change Control Rig Device from ',ch.rigDev,' to ',daqs(d).ID,'?']);
                        switch yesorno
                            case 'Yes'
                                setacqpref('ControlHardware','rigDev',daqs(d).ID)
                            otherwise
                                error('Check daq devices, change setupDaqDevices function, then proceed')
                        end
                    else
                        continue
                    end
                elseif length(daqs(d).Subsystems(2).ChannelNames)==2
                    % The device with the most outputs is the triggered piezo rig
                    if ~strcmp(daqs(d).ID, ah.triggeredDev)
                        yesorno = questdlg(['Change triggered device from ',ah.triggeredDev,' to ',daqs(d).ID,'?']);
                        switch yesorno
                            case 'Yes'
                                setacqpref('AcquisitionHardware','triggeredDev',daqs(d).ID)
                            otherwise
                                error('Check daq devices, change setupDaqDevices function, then proceed')
                        end
                    else
                        continue
                    end
                end
            end
            % review settings:
            acqDevices.rigDev = getacqpref('AcquisitionHardware','rigDev');
            acqDevices.modeDev = getacqpref('AcquisitionHardware','modeDev');
            acqDevices.gainDev = getacqpref('AcquisitionHardware','gainDev');
            acqDevices.triggeredDev = getacqpref('AcquisitionHardware','triggeredDev');
            acqDevices.cntrlRigDev = getacqpref('ControlHardware','rigDev');
            fprintf('Acquisition Hardware settings:\n')
            disp(acqDevices)
            
        end
        
        function setIdentifiers(obj,varargin)

            p = inputParser;
            p.PartialMatching = 0;

            p.addParameter('flygenotype','',@ischar);
            p.addParameter('flynumber',[],@isnumeric);
            %             p.addParameter('flyage',2,@isnumeric);
            %             p.addParameter('flysex','female',@ischar);
            p.addParameter('cellnumber',[],@isnumeric);
            p.addParameter('reset',0,@isnumeric);
            
            errorStr = 'Amp 1 Device must be ''MultiClamp700B'' or ''MultiClamp700BAux''';
            validationFcn = @(x) assert(logical(sum(strcmp(x,{'MultiClamp700B','MultiClamp700BAux'}))),errorStr);
            p.addParameter('amplifier1Device','',...
                validationFcn);           
            
            p.addParameter('aiSamprate',10000,@isnumeric);
            p.addParameter('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;
            
            obj.flygenotype = '';
            obj.flynumber = '';
            obj.cellnumber = '';
            obj.amplifier1Device = '';
            
            numlines = [1 1 1 1];
            defAns = {'','','','MultiClamp700A'};
            inputprompts{1} = 'Fly Genotype: ';
            if isfield(p.Results,'flygenotype') && ~isempty(p.Results.flygenotype)
                obj.flygenotype = p.Results.flygenotype;
                defAns{1} = obj.flygenotype;
            end
            
            inputprompts{2} = 'Fly Number: ';
            if isfield(p.Results,'flynumber') && ~isempty(p.Results.flynumber)
                obj.flynumber = num2str(p.Results.flynumber);
                defAns{2} = obj.flynumber;
            end
            
            inputprompts{3} = 'Cell Number: ';
            if isfield(p.Results,'cellnumber') && ~isempty(p.Results.cellnumber)
                obj.cellnumber = num2str(p.Results.cellnumber);
                defAns{3} = obj.cellnumber;
            end

            inputprompts{4} = 'Amp 1 Device: ';
            if isfield(p.Results,'amplifier1Device') && ~isempty(p.Results.amplifier1Device)
                obj.amplifier1Device = p.Results.amplifier1Device;
                defAns{4} = obj.amplifier1Device;
            end
            
            if isacqpref('AcquisitionPrefs')
                acquisitionPrefs = getacqpref('AcquisitionPrefs');
                
            else
                acquisitionPrefs.flygenotype = [];
                acquisitionPrefs.flynumber = [];
                acquisitionPrefs.cellnumber = [];
                acquisitionPrefs.amplifier1Device = [];
                acquisitionPrefs.last_timestamp = 0;
            end
            
            undefinedID = 0;
            usingAcqPrefs = 0;
            dlgtitle = 'Enter remaining IDs (integers please)';
            if isempty(obj.flygenotype)
                if datenum([0 0 0 1 0 0]) > (now-acquisitionPrefs.last_timestamp)
                    obj.flygenotype = acquisitionPrefs.flygenotype;
                    defAns{1} = acquisitionPrefs.flygenotype;
                    usingAcqPrefs = 1;
                else
                    if ~isempty(acquisitionPrefs.flygenotype)
                        defAns{1} = acquisitionPrefs.flygenotype;
                    end
                    undefinedID = 1;
                end
            end
            if isempty(obj.flynumber)
                if datenum([0 0 0 1 0 0]) > (now-acquisitionPrefs.last_timestamp)
                    obj.flynumber = acquisitionPrefs.flynumber;
                    defAns{2} = acquisitionPrefs.flynumber;
                    usingAcqPrefs = 1;
                else
                    if ~isempty(acquisitionPrefs.flynumber)
                        defAns{2} = acquisitionPrefs.flynumber;
                    end
                    undefinedID = 1;
                end
            end
            if isempty(obj.cellnumber)
                if datenum([0 0 0 1 0 0]) > (now-acquisitionPrefs.last_timestamp)
                    obj.cellnumber = acquisitionPrefs.cellnumber;
                    defAns{3} = num2str(acquisitionPrefs.cellnumber);
                    usingAcqPrefs = 1;
                else
                    if ~isempty(acquisitionPrefs.cellnumber)
                        defAns{3} = acquisitionPrefs.cellnumber;
                    end
                    undefinedID = 1;
                end
            end
            if isempty(obj.amplifier1Device)
                if datenum([0 0 0 1 0 0]) > (now-acquisitionPrefs.last_timestamp)
                    if ~sum(strcmp(acquisitionPrefs.amplifier1Device,{'MultiClamp700B','MultiClamp700BAux','MultiClamp700A','MultiClamp700AAux'}))
                        error('AcuisitionPrefs, ''amplifier1Device'', preference is invalid.  Must be: {''MultiClamp700B'',''MultiClamp700A''}')
                    end
                    obj.amplifier1Device = acquisitionPrefs.amplifier1Device;
                    defAns{4} = acquisitionPrefs.amplifier1Device;
                    usingAcqPrefs = 1;
                else
                    if ~isempty(acquisitionPrefs.amplifier1Device)
                        defAns{4} = acquisitionPrefs.amplifier1Device;
                    end
                    undefinedID = 1;
                end
            end
            if p.Results.reset
                undefinedID = 1;
            end                
            if undefinedID
                while undefinedID
                    answer = inputdlg(inputprompts,dlgtitle,numlines,defAns);

                    obj.flygenotype = answer{1};
                    obj.flynumber  = answer{2};
                    obj.cellnumber = answer{3};
                    obj.amplifier1Device = answer{4};
                    if ~sum(strcmp(obj.amplifier1Device,{'MultiClamp700B','MultiClamp700BAux','MultiClamp700A','MultiClamp700AAux'}))
                        error('AcuisitionPrefs, ''amplifier1Device'', preference is invalid.  Must be: {''MultiClamp700B'',''MultiClamp700BAux''}')
                    end

                    if ~isempty(obj.flynumber) && ~isempty(obj.cellnumber)
                        break
                    end
                end
                disp('****')
            else
                if usingAcqPrefs
                    fprintf('Identifiers are current: \nfly genotype - %s\nfly number - %s\ncell number - %s\namplifier 1 - %s\n',...
                        obj.flygenotype,...
                        obj.flynumber,...
                        obj.cellnumber,...
                        obj.amplifier1Device);
                end
            end
            
            % then set preferences to current values
            
            setacqpref('AcquisitionPrefs',...
                {'flygenotype','flynumber','cellnumber','amplifier1Device','last_timestamp'},...
                {obj.flygenotype,obj.flynumber,obj.cellnumber, obj.amplifier1Device, now});

            obj.updateFileNames();
            obj.openNotesFile();
            if ~isempty(obj.protocol)
                obj.setProtocol(obj.protocol.protocolName);
            end
        end
                
        function nfn = cleanUpAndExit(obj)
            fclose(obj.notesFileID);
            nfn = obj.notesFileName;
        end

        function delete(obj)
            try 
                fclose(obj.notesFileID);
                fprintf('Open notes file! Should be closed');
            catch e
                %disp(e)
            end
        end

        
    end % methods
    
    methods (Access = protected)
        
        function findPrevTrials(obj)
            % make a directory if one does not exist
            if ~isdir(obj.D)
                mkdir(obj.D);
            end
            
            % check whether a saved data file exists with today's date
            name = [obj.D,'\',obj.protocol.protocolName,'_Raw_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_*'];
            if contains(obj.protocol.requiredRig,'Continuous')
                name = [obj.D,'\',obj.protocol.protocolName,'_ContRaw_', ...
                    datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_*A.bin'];
            end

            rawtrials = dir(name);
            obj.n = length(rawtrials)+1;
            
            if contains(obj.protocol.requiredRig,'Continuous')
                todayname = [obj.D,'\',obj.protocol.protocolName,'_ContRaw_', ...
                    datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_*_A.bin'];
                rawtrials = dir(todayname);
                if isempty(rawtrials)
                    obj.n = 1;
                else
                    trials_sofar = zeros(size(rawtrials));
                    for t_idx = 1:length(trials_sofar)
                        nstr = regexp(rawtrials(t_idx).name,'_(\d+)_A.bin','match','once');
                        trials_sofar(t_idx) = str2double(nstr(2:regexp(nstr(2:end),'_')));
                    end
                    obj.n = max(trials_sofar)+1;
                end
            end
            
            expt_rawtrials = dir([obj.D,'\','*_Raw_*',...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_*']);
            if contains(obj.protocol.requiredRig,'Continuous')
                expt_rawtrials = dir([obj.D,'\','*_ContRaw_*',...
                    datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_*A.bin']);
            end
            if isempty(expt_rawtrials)
                obj.expt_n = 1;
                obj.block_n = 0;
            else
                obj.expt_n = length(expt_rawtrials)+1;
                % find latest expt_rawtrial to get the block number
                N = 1;
                dn = expt_rawtrials(1).datenum;
                for num = 1:length(expt_rawtrials)
                    if expt_rawtrials(num).datenum > dn
                        dn = expt_rawtrials(num).datenum;
                        N = num;
                    end
                end
                if ~contains(obj.protocol.requiredRig,'Continuous')
                    load(fullfile(obj.D,expt_rawtrials(N).name),'params');
                    obj.block_n = params.trialBlock;
                else
                    obj.block_n = obj.n;
                end
            end
                        
            fprintf('Fly %s, Cell %s currently has %d %s trials \n(Total: %d trials in %d blocks)\n',...
                obj.flynumber,obj.cellnumber,obj.n-1,obj.protocol.protocolName,obj.expt_n-1,obj.block_n);
        end
        
        function updateFileNames(obj)%,metprop,propevnt)
            % UPDATE 181003: installed an MVMe SSD drive, supposedly a ton
            % faster to save to. Now putting everything there.
            
            % UPDATE 211210: Computer died, have to reinstall, so now making it somewhat
            % easier to update.
            
            AcqDir = getacqpref('USERDIRECTORY','AcquisitionDir');
            if isempty(AcqDir)
                AcqDir = uigetdir('D:','Select Acquisition folder or directory');
                if isempty(regexp(AcqDir,'Acquisition','once'))
                    drv =  fileparts(AcqDir);
                    AcqDir = drv(1:3);
                    if ~exist(fullfile(AcqDir,'Acquisition'),'dir')
                        mkdir(fullfile(AcqDir,'Acquisition'))
                    end
                    AcqDir = fullfile(AcqDir,'Acquisition');
                end
                setacqpref('USERDIRECTORY','AcquisitionDir',AcqDir);
                AcqDir = getacqpref('USERDIRECTORY','AcquisitionDir');
            end
            obj.D = fullfile(AcqDir,datestr(date,'yymmdd'),...
                [datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber]);
            if ~isempty(obj.rig)
                obj.saveAcquisition();
                if isa(obj.rig,'ContinuousRig')
                    obj.rig.updateFileNames('directory',obj.D,'flynumber',obj.flynumber,'cellnumber',obj.cellnumber,'protocol',obj.protocol);
                end
            end
        end
                
        function setRig(obj,varargin)
            
            % Main Amp (amplifier1Device) may have changed
            if ~isempty(obj.rig)
                changeMainAmp = 0;
                devicenames = fieldnames(obj.rig.devices);
                mainamps = {'amplifier','amplifier_1'};
                for ma_ind = 1:length(mainamps)
                    if sum(strcmp(devicenames,mainamps(ma_ind)))
                        changeMainAmp = ~strcmp(obj.amplifier1Device,obj.rig.devices.(devicenames{strcmp(devicenames,mainamps(ma_ind))}).deviceName);
                    end
                end
            end
            
            if isempty(obj.rig) || ~strcmp(obj.protocol.requiredRig,obj.rig.rigName) || changeMainAmp
                
                if ~isempty(obj.rig)
                    delete(obj.rig);
                end
                if ~isempty(regexp(obj.protocol.requiredRig,'Continuous','once'))
                    % the ContinousRigs need different inputs.
                    eval(['obj.rig = ' obj.protocol.requiredRig ...
                            '(''amplifier1Device'',obj.amplifier1Device,''directory'',obj.D,''flynumber'',obj.flynumber,''cellnumber'',obj.cellnumber,''protocol'',obj.protocol);']);
                else
                    eval(['obj.rig = ' obj.protocol.requiredRig '(''amplifier1Device'',obj.amplifier1Device);']);
                end
                
                addlistener(obj.rig,'StartRun',@obj.writeRunNotes); % gets destroyed when rig is destroyed
                addlistener(obj.rig,'SaveData',@obj.saveData);
                addlistener(obj.rig,'SaveData',@obj.writeTrialNotes);
                addlistener(obj.rig,'IncreaseTrialNum',@obj.increaseTrialNum);
                if obj.analyze
                    obj.analyzelistener = addlistener(obj.rig,'DataSaved',@obj.runAnalyses);
                end
                                
                if isa(obj.rig,'CameraBaslerRig') || isa(obj.rig,'CameraBaslerTwoAmpRig') || isa(obj.rig,'CameraBaslerPairTwoAmpRig')
                    addlistener(obj.rig,'StartTrial',@obj.setCameraLogging);
                end
                
                
                
                if isa(obj.rig,'TwoPhotonRig')
                    %error('Do I need to clean up files?')
                    %addlistener(obj.rig,'StartTrial',@obj.cleanUpImages);
                end
                
                devs = fieldnames(obj.rig.devices);
                
                for d = 1:length(devs)
                    % if the device params change (eg filter cutoff), save the
                    % acquisition setup
                    addlistener(obj.rig.devices.(devs{d}),'ParamChange',@obj.saveAcquisition);
                end
                obj.writePrologueNotes
                obj.protocol.adjustRig(obj.rig);
                obj.saveAcquisition();
            else
                status = obj.protocol.adjustRig(obj.rig);                
                if status
                    obj.saveAcquisition();
                end
            end
        end
                
        function warn(obj,warning)
            obj.notesFileID = fopen(obj.notesFileName,'a');
            fprintf(obj.notesFileID,'\t\t\t%s\n',warning);
            fprintf(1,'\t\t\t%s\n',warning);
            fclose(obj.notesFileID);
        end
        
        function openNotesFile(obj)
            curnotesfn = [obj.D,'\notes_',...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'.txt'];

            newnoteslogical = isempty(dir(curnotesfn));
            if newnoteslogical && ~isempty(obj.notesFileID)
                try fclose(obj.notesFileID);
                catch
                end
            end

            obj.notesFileName = curnotesfn;
            if ~isdir(obj.D)
                mkdir(obj.D);
            end
            if newnoteslogical
                obj.askAboutTheExperiment;
            end            
            % obj.notesFileID = fopen(obj.notesFileName,'a');
        end
           
        function askAboutTheExperiment(obj)
            inputprompts = {
                'Purpose: ';
                'Fly Age: ';
                'Drugs and internal: ';
                'Equipment check (stuff fixed or need fixing); ';
                'Fly Movement: ';
                'Planned playtime: '};
            
            numlines = [2,40; 1,40; 1,40; 3,40; 2, 40;2,40];
            dlgtitle = 'Enter experiment information';
            answer = inputdlg(inputprompts,dlgtitle,numlines);
            
            obj.notesFileID = fopen(obj.notesFileName,'a');
            for i = 1:length(answer)
                fprintf(1,...
                    '%s %s\n', inputprompts{i},answer{i});
                fprintf(obj.notesFileID,...
                    '%s %s\n', inputprompts{i},answer{i});
            end
            fclose(obj.notesFileID);
        end
        
        function writePrologueNotes(obj)
            obj.notesFileID = fopen(obj.notesFileName,'a');
            fprintf(obj.notesFileID,...
                '%s - %s - %s; F%s_C%s\nRigName: %s\n',...
                datestr(date,'yymmdd'),datestr(clock,13),obj.flygenotype,...
                obj.flynumber,obj.cellnumber,...
                obj.rig.rigName);
            
            devs = obj.rig.devices;
            devnames = fieldnames(devs);
            for d = 1:length(devnames)
                fprintf(obj.notesFileID,...
                    '\t%s: %s\n',...
                    devnames{d},devs.(devnames{d}).deviceName);
            end
            
            fprintf(obj.notesFileID,...
                'For list of equipement run: equipmentSetupStruct(''%s'')\n',...
                datestr(date,'yymmdd'));
            fclose(obj.notesFileID);
        end
        
        function writeRunNotes(obj,varargin)
            obj.notesFileID = fopen(obj.notesFileName,'a');
            
            if ~isempty(obj.tags)
                tagstr = sprintf('%s; ',obj.tags{:});
            else
                tagstr = '';
            end
            fprintf(obj.notesFileID,'\n\t%s - %s - %s; F%s_C%s\n\tTrial Block %d - Tagged as {''%s''}\n ',...
                obj.protocol.protocolName,datestr(clock,13),...
                obj.flygenotype,obj.flynumber,obj.cellnumber,...
                obj.block_n,tagstr);
            fprintf(1,'\n\t%s - %s - %s; F%s_C%s\n\tTrial Block %d - Tagged as {''%s''}\n ',...
                obj.protocol.protocolName,datestr(clock,13),...
                obj.flygenotype,obj.flynumber,obj.cellnumber,...
                obj.block_n,tagstr);
            
            
            if isfield(obj.rig.devices,'amplifier')
                fprintf(obj.notesFileID,'\t%s',obj.rig.devices.amplifier.mode);
                fprintf(1,'\t%s',obj.rig.devices.amplifier.mode);
            end
            if isa(obj.rig,'TwoAmpRig')
                fprintf(obj.notesFileID,'\t{%s,%s}',...
                            obj.rig.devices.amplifier_1.mode,...
                            obj.rig.devices.amplifier_2.mode);
                fprintf(1,'\t{%s,%s}',...
                            obj.rig.devices.amplifier_1.mode,...
                            obj.rig.devices.amplifier_2.mode);
            end
            
            paramnames = fieldnames(obj.protocol.params);
            for i = 1:length(paramnames)
                val = obj.protocol.params.(paramnames{i});
                if iscell(val)
                    str = '{';
                    for val_idx = 1:length(val)
                        str = [str '[' num2str(val{val_idx}) ']']; %#ok<AGROW>
                    end
                    val = [str '}'];
                elseif length(val)>1
                    val = ['[' num2str(val) ']'];
                else
                    val = num2str(val);
                end
                fprintf(obj.notesFileID,', %s=%s', paramnames{i},val);
                fprintf(1,', %s=%s', paramnames{i},val);
            end
            fprintf(obj.notesFileID,'\n');
            fprintf(1,'\n');
            fclose(obj.notesFileID);
        end
        
        function writeTrialNotes(obj,varargin)
            obj.notesFileID = fopen(obj.notesFileName,'a');
            fprintf(obj.notesFileID,'\t\t%d, %s trial %d',...
                obj.expt_n,...
                obj.protocol.protocolName,...
                obj.n);
            fprintf(1,'\t\t%d, %s trial %d',obj.expt_n, obj.protocol.protocolName,obj.n);
            paramsToIter = obj.protocol.paramsToIter;
            for pti = 1:length(paramsToIter)
                pname = paramsToIter{pti};
                fprintf(obj.notesFileID,', %s=%.2f',pname(1:end-1),obj.protocol.params.(pname(1:end-1)));
                fprintf(1,', %s=%.2f',pname(1:end-1),obj.protocol.params.(pname(1:end-1)));
            end
            fprintf(obj.notesFileID,', %s',datestr(clock,13));
            fprintf(1,', %s',datestr(clock,13));
            
            if isa(obj.rig,'ContinuousRig')
                [~,name,ext] = fileparts(obj.rig.getFileName);
                fprintf(1,'\n\t\t%s%s\n',name,ext);
                fprintf(obj.notesFileID,'\t\t%s%s\n',name,ext);
            else
                [~,name] = fileparts(sprintf(regexprep(obj.getRawFileStem,'\\','\\\'),obj.n));
                fprintf(1,'\t%s\n',name);
                fprintf(obj.notesFileID,'\t%s\n',name);
            end
            
            if isa(obj.rig,'CameraBaslerRig') || isa(obj.rig,'CameraBaslerTwoAmpRig')
                fprintf(obj.notesFileID,'\t\tImageFile - %s\n',obj.rig.devices.camera.fileName);
                fprintf(1,'\t\tImageFile - %s\n',obj.rig.devices.camera.fileName);
            end
            if isa(obj.rig,'CameraBaslerPairTwoAmpRig')
                fprintf(obj.notesFileID,'\t\tImageFile - %s\n',obj.rig.devices.camera.fileName);
                fprintf(1,'\t\tImageFile - %s\n',obj.rig.devices.camera.fileName);
                fprintf(obj.notesFileID,'\t\tImageFile2 - %s\n',obj.rig.devices.cameratwin.fileName);
                fprintf(1,'\t\tImageFile2 - %s\n',obj.rig.devices.cameratwin.fileName);
            end
            fclose(obj.notesFileID);
        end

        
        function saveData(obj,varargin)
            if isa(obj.rig,'ContinuousRig')
                % continuous rigs save their data themselves
                return
            end
            data = obj.rig.inputs.data;
            data.params = obj.protocol.params;
            if isa(obj.rig,'EPhysRig')
                data.params.mode = obj.rig.devices.amplifier.mode;
                data.params.gain = obj.rig.devices.amplifier.gain;
                if isa(obj.rig.devices.amplifier,'MultiClamp700B')
                    data.params.secondary_gain = obj.rig.devices.amplifier.secondary_gain;
                end
            end
            if isa(obj.rig,'TwoAmpRig')
                data.params.mode_1 = obj.rig.devices.amplifier_1.mode;
                data.params.mode_2 = obj.rig.devices.amplifier_2.mode;
                data.params.gain_1 = obj.rig.devices.amplifier_1.gain;
                data.params.gain_2 = obj.rig.devices.amplifier_2.gain;
                if isa(obj.rig.devices.amplifier_1,'MultiClamp700B')
                    data.params.secondary_gain_1 = obj.rig.devices.amplifier_1.secondary_gain;
                end
                if isa(obj.rig.devices.amplifier_2,'MultiClamp700B')
                    data.params.secondary_gain_2 = obj.rig.devices.amplifier_2.secondary_gain;
                end
            end
            data.params.trial = obj.n;
            data.params.trialBlock = obj.block_n;
            data.timestamp = datetime('now');
            data.name = sprintf(regexprep(obj.getRawFileStem,'\\','\\\'),obj.n);
            data.tags = obj.tags;

            if isa(obj.rig,'CameraBaslerRig') || isa(obj.rig,'CameraBaslerTwoAmpRig')
                data.imageFile = obj.rig.devices.camera.fileName;
            end
            if isa(obj.rig,'CameraBaslerPairTwoAmpRig')
                data.imageFile = obj.rig.devices.camera.fileName;
                data.imageFile2 = obj.rig.devices.cameratwin.fileName;
            end
            
            save(data.name, '-struct', 'data');

            if isa(obj.rig,'TwoPhotonRig')
                obj.match2PImages(data);
            end
        end
        
        function increaseTrialNum(obj,varargin)
            obj.n = obj.n + 1;
            obj.expt_n = obj.expt_n+1;
            if isa(obj.rig,'ContinuousRig')
                if obj.n ~= obj.rig.n
                    warning('Somehow Acquisition and %s trial nums are off',obj.rig.rigName)
                    fprintf('%d vs %d\nNow %d\n',obj.n, obj.rig.n,obj.rig.n);
                    obj.n = obj.rig.n;
                end
            end
        end
       
 
        
        function match2PImages(obj,data,varargin)
            imagedir = regexprep(regexprep(data.name,'Raw','Images'),'.mat','');
            mkdir(imagedir);
            images = dir([obj.D,'\',obj.protocol.protocolName,'_Image_*']);
            if isempty(images)
                h = msgbox('No images. Save, Close Image?');
                set(h, 'position',[5 280 170 52.5])
                uiwait(h);
                %warning('There are no images to connect to this trial')
                images = dir([obj.D,'\',obj.protocol.protocolName,'_Image_*']);
                if isempty(images)
                    warning('There are no images to connect to this trial.  Data saved')
                end
            end
            if ~isempty(images)
                for im = 1:length(images)
                    [success,m,~] = movefile(fullfile(obj.D,images(im).name),imagedir);
                    if ~success
                        if strcmp(m,'The process cannot access the file because it is being used by another process.')
                            h = msgbox('Close the file!');
                            set(h, 'position',[1280 700 170 52.5])
                            uiwait(h);
                            [success,m,~] = movefile(fullfile(obj.D,images(im).name),imagedir);
                        end
                    end
                    if ~success
                        error('Image File %s not moved: %s\n',images(im).name,m);
                        
                    end
                end
                pattern = [obj.protocol.protocolName,'_Image_'];
                imnumstr = regexprep(regexp(images(im).name,[pattern '\d+'],'match'),pattern,'');
                data.imageNum = str2double(imnumstr{1});
            end
            save(data.name, '-struct', 'data');
        end
            
        function cleanUpImagesBeforeTrial(obj,varargin)
            pattern = [obj.protocol.protocolName,'_Image_' datestr(date,29) '-(\d+)-\d+.avi'];
            savedirmat = ls(obj.D)';
            savedirconts = savedirmat(:)';
            avifiles = regexp(savedirconts,pattern,'match');
            
            for im = 1:length(avifiles)
                imagedir = fullfile(obj.D,'archive');
                if ~isdir(imagedir)
                    mkdir(imagedir);
                end
                [success,m,~] = movefile(fullfile(obj.D,avifiles{im}),imagedir);
                if ~success
                    error('Image File %s not moved: %s\n',images(im).name,m);
                end
            end
        end
        
        function cleanUpImagesAfterRun(obj,varargin)
            pattern = [obj.protocol.protocolName,'_Image_' datestr(date,29) '-(\d+)-\d+.avi'];
            savedirmat = ls(obj.D)';
            savedirconts = savedirmat(:)';
            avifiles = regexp(savedirconts,pattern,'match');
            
            for im = 1:length(avifiles)
                imagedir = fullfile(obj.D,'archive');
                if ~isdir(imagedir)
                    mkdir(imagedir);
                end
                [success,m,~] = movefile(fullfile(obj.D,avifiles{im}),imagedir);
                if ~success
                    error('Image File %s not moved: %s\n',images(im).name,m);
                end
            end
        end

        
        function setCameraLogging(obj,varargin)
            name = fullfile(regexprep(sprintf(regexprep(obj.getRawFileStem,'\\','\\\'),obj.n),{'_Raw_','.mat'},{'_Image_','_%s'}));            
            obj.rig.devices.camera.setLogging(name);
            if isa(obj.rig,'CameraBaslerPairTwoAmpRig')
                % CameraBaslerPairTwoAmpRig sets name of file to cam2.avi
                obj.rig.devices.cameratwin.setLogging(name);
            end
        end
        
        function saveAcquisition(obj,varargin)
            if ~isdir(obj.D)
                mkdir(obj.D);
            end
            cd(obj.D)
            name = [obj.D,'\', class(obj),'_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber];
            acqStruct.flygenotype = obj.flygenotype;
            acqStruct.flynumber = obj.flynumber;
            acqStruct.cellnumber = obj.cellnumber;             
            acqStruct.amplifier1Device = obj.amplifier1Device;  %#ok<STRNU>            
            save(name,'acqStruct');
            
            rigStruct = obj.rig.getRigStruct(); %#ok<NASGU>
            name = [obj.D,'\' obj.rig.rigName '_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber];
            save(name,'rigStruct');           
        end
        
        function handleRigChange(obj,~,~,varargin)
            if ~strcmp(evntdata.rigName,obj.rigName)
                % destroy current ai/aoSessions
                obj.setRig(evntdata.rigName);
            end 
        end
        function handleStimulusProblem(obj,protocol,evntdata,varargin)
            obj.warn([protocol.protocolName ' has a problem: ' evntdata.Issue])
        end
        
        function setAnalysisFlag(obj,varargin)
            if obj.analyze
                obj.analyzelistener = addlistener(obj.rig,'DataSaved',@obj.runAnalyses);
            else
                delete(obj.analyzelistener)
            end
        end
        
        function runAnalyses(obj,~,~,varargin)
            for a = 1:length(obj.protocol.analyses)
                eval([obj.protocol.analyses{a}...
                    '(obj.rig.inputs.data,obj.protocol.params,obj.protocol.x,sprintf(regexprep(obj.getRawFileStem,''\\'',''\\\''),obj.n-1),obj.tags,obj.protocol);'])
            end
        end
            
    end
    
end % classdef