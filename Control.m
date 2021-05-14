classdef Control < Acquisition
    
    properties (Constant)
    end
    
    events
    end
    
    methods
        function obj = Control(varargin)
            obj = obj@Acquisition(varargin{:});
        end
        
        function run(obj,varargin)
            if nargin>1
                repeats = varargin{1};
            else
                repeats = 1;
            end
            
            obj.block_n = obj.block_n+1;
            obj.protocol.reset;
            obj.rig.run(obj.protocol,repeats,obj);
            if ~isa(obj.rig,'ContinuousRig')
                systemsound('Notify');
            end
            
        end
        
        function chooseDefaultProtocol(obj)
            % set a simple protocol
            obj.setProtocol('SealAndLeakControl');
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
            
            if isacqpref('ControlPrefs')
                controlPrefs = getacqpref('ControlPrefs');
                acqPrefs = getacqpref('AcquisitionPrefs');
            else
                controlPrefs.flygenotype = [];
                controlPrefs.flynumber = [];
                controlPrefs.cellnumber = [];
                controlPrefs.amplifier1Device = [];
                controlPrefs.last_timestamp = 0;
            end
                            
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
            
            % Acquisition may be running, have to make sure the control and
            % acquisition are saving to the same place
            prompt_on_acq = 0;
            if datenum([0 0 0 2 0 0]) > (now-acqPrefs.last_timestamp)
                % acq was started within 2 hours
                prompt_on_acq = 1;
                inputprompts{2} = ['Fly Number: (F' acqPrefs.flynumber '?)'];
                inputprompts{3} = ['Cell Number: (C' acqPrefs.cellnumber '?)'];
            end
            
            undefinedID = 0;
            usingAcqPrefs = 0;
            dlgtitle = 'Enter remaining IDs (integers please)';
            if isempty(obj.flygenotype)
                if datenum([0 0 0 1 0 0]) > (now-controlPrefs.last_timestamp)
                    obj.flygenotype = controlPrefs.flygenotype;
                    defAns{1} = controlPrefs.flygenotype;
                    usingAcqPrefs = 1;
                else
                    if ~isempty(controlPrefs.flygenotype)
                        defAns{1} = controlPrefs.flygenotype;
                    end
                    undefinedID = 1;
                end
            end
            if isempty(obj.flynumber)
                if prompt_on_acq
                    obj.flynumber = acqPrefs.flynumber;
                    defAns{2} = acqPrefs.flynumber;
                    undefinedID = 1; % prompts the acquisition id, but allows user to change
                elseif datenum([0 0 0 1 0 0]) > (now-controlPrefs.last_timestamp)
                    obj.flynumber = controlPrefs.flynumber;
                    defAns{2} = controlPrefs.flynumber;
                    usingAcqPrefs = 1;
                else
                    if ~isempty(controlPrefs.flynumber)
                        defAns{2} = controlPrefs.flynumber;
                    end
                    undefinedID = 1;
                end
            end
            if isempty(obj.cellnumber)
                if prompt_on_acq
                    obj.cellnumber = acqPrefs.cellnumber;
                    defAns{3} = acqPrefs.cellnumber;
                    undefinedID = 1; % prompts the acquisition id, but allows user to change
                elseif datenum([0 0 0 1 0 0]) > (now-controlPrefs.last_timestamp)
                    obj.cellnumber = controlPrefs.cellnumber;
                    defAns{3} = num2str(controlPrefs.cellnumber);
                    usingAcqPrefs = 1;
                else
                    if ~isempty(controlPrefs.cellnumber)
                        defAns{3} = controlPrefs.cellnumber;
                    end
                    undefinedID = 1;
                end
            end
            if isempty(obj.amplifier1Device)
                if datenum([0 0 0 1 0 0]) > (now-controlPrefs.last_timestamp)
                    if ~sum(strcmp(controlPrefs.amplifier1Device,{'MultiClamp700B','MultiClamp700BAux','MultiClamp700A','MultiClamp700AAux'}))
                        error('AcquisitionPrefs, ''amplifier1Device'', preference is invalid.  Must be: {''MultiClamp700B'',''MultiClamp700A''}')
                    end
                    obj.amplifier1Device = controlPrefs.amplifier1Device;
                    defAns{4} = controlPrefs.amplifier1Device;
                    usingAcqPrefs = 1;
                else
                    if ~isempty(controlPrefs.amplifier1Device)
                        defAns{4} = controlPrefs.amplifier1Device;
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
                        error('AcquisitionPrefs, ''amplifier1Device'', preference is invalid.  Must be: {''MultiClamp700B'',''MultiClamp700BAux''}')
                    end
                    
                    if ~isempty(obj.flynumber) && ~isempty(obj.cellnumber) && ...
                            (obj.flynumber ~= acqPrefs.flynumber || ...
                            obj.cellnumber ~= acqPrefs.cellnumber)
                        a = questdlg('Acquisition object and Control object fly or cell numbers are different. Proceed?','Alert!','No');
                        switch a
                            case 'Yes'
                                break
                            case 'No'
                                continue
                            case 'Cancel'
                                continue
                        end
                    elseif ~isempty(obj.flynumber) && ~isempty(obj.cellnumber)
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
            
            setacqpref('ControlPrefs',...
                {'flygenotype','flynumber','cellnumber','amplifier1Device','last_timestamp'},...
                {obj.flygenotype,obj.flynumber,obj.cellnumber, obj.amplifier1Device, now});
            
            obj.updateFileNames();
            obj.openNotesFile();
            if ~isempty(obj.protocol)
                obj.setProtocol(obj.protocol.protocolName);
            end
        end
        
    end % methods
    
    methods (Access = protected)

        function openNotesFile(obj)
            curnotesfn = [obj.D,'\notes_control_',...
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
                
                addlistener(obj.rig,'StartRun_Control',@obj.writeRunNotes); % gets destroyed when rig is destroyed
                addlistener(obj.rig,'SaveData_Control',@obj.saveData);
                addlistener(obj.rig,'SaveData_Control',@obj.writeTrialNotes);
                addlistener(obj.rig,'IncreaseTrialNum_Control',@obj.increaseTrialNum);
                if obj.analyze
                    obj.analyzelistener = addlistener(obj.rig,'DataSaved_Control',@obj.runAnalyses);
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
            obj.rig.setParams('trialnum', obj.n);
        end
        
        function saveData(obj,varargin)
            if isa(obj.rig,'ContinuousRig')
                % continuous rigs save their data themselves
                return
            end
            % data = obj.rig.inputs.data;
            data.params = obj.protocol.params;
            data.params.trial = obj.n;
            data.params.trialBlock = obj.block_n;
            if isa(obj.rig,'EpiOrLEDRig')
                data.params.blueToggle = obj.rig.devices.epi.params.blueToggle;
                data.params.controlToggle = obj.rig.devices.epi.params.controlToggle;
                data.params.routineToggle = obj.rig.devices.epi.params.routineToggle;
            end
            data.timestamp = now;
            data.name = sprintf(regexprep(obj.getRawFileStem,'\\','\\\'),obj.n);
            data.tags = obj.tags;
            
            save(data.name, '-struct', 'data');
        end
        
    end
    
end % classdef