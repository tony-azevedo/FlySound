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
    end
    
    properties (SetObservable, AbortSet)
        analyze
    end
    
    % Define an event called InsufficientFunds
    events
    end
    
    methods
        function obj = Acquisition(varargin)
            obj.tags = {};
            obj.setIdentifiers(varargin{:})
            obj.updateFileNames()

            addlistener(...
                obj,...
                'analyze',...
                'PostSet',@obj.setAnalysisFlag);

            % set a simple protocol
            obj.setProtocol('SealAndLeak');
            obj.analyze = 1;

        end
        
        function run(obj,varargin)
            if nargin>1
                repeats = varargin{1};
            else
                repeats = 1;
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
            
        end
        
        function setProtocol(obj,prot,varargin)
            if ~isempty(obj.rig) && obj.rig.IsContinuous
                obj.rig.stop
            end
            
            protstr = ['obj.protocol = ' prot '('];
            if nargin>2
                for i = 1:length(varargin)
                    protstr = [protstr '''' varargin{i} ''','];
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
                com = inputdlg('Enter comment:', 'Comment', [1 50]);
                com = strcat(com{:});
            end
            fprintf(obj.notesFileID,'\n\t****************\n\t%s\n\t%s\n\t****************\n',datestr(clock,31),com);
            fprintf(1,'\n\t****************\n\t%s\n\t%s\n\t****************\n',datestr(clock,31),com);
        end

        function tag(obj,varargin)
            if nargin > 1
                tag = varargin;
            else
                tag = inputdlg('Enter tag:', 'Tag', [1 50]);
                tag = strcat(tag{:});
            end
            for t = 1:length(tag);
                if ~sum(strcmp(obj.tags,tag{t}));
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
            end
            
            for t = 1:length(untag);
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
        
        
        
        function setIdentifiers(obj,varargin)
            
            p = inputParser;
            p.PartialMatching = 0;

            p.addParameter('flygenotype','',@ischar);
            p.addParameter('flynumber',[],@isnumeric);
            %             p.addParameter('flyage',2,@isnumeric);
            %             p.addParameter('flysex','female',@ischar);
            p.addParameter('cellnumber',[],@isnumeric);
            
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
            defAns = {'','',''};
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
            
            if ispref('AcquisitionPrefs')
                acquisitionPrefs = getpref('AcquisitionPrefs');
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
                    if ~isempty(acquisitionPrefs.flygenotype);
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
                    if ~isempty(acquisitionPrefs.flynumber);
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
                    if ~isempty(acquisitionPrefs.cellnumber);
                        defAns{3} = acquisitionPrefs.cellnumber;
                    end
                    undefinedID = 1;
                end
            end
            if isempty(obj.amplifier1Device)
                if datenum([0 0 0 1 0 0]) > (now-acquisitionPrefs.last_timestamp)
                    if ~sum(strcmp(acquisitionPrefs.amplifier1Device,{'MultiClamp700B','MultiClamp700BAux'}))
                        error('AcuisitionPrefs, ''amplifier1Device'', preference is invalid.  Must be: {''MultiClamp700B'',''MultiClamp700BAux''}')
                    end
                    obj.amplifier1Device = acquisitionPrefs.amplifier1Device;
                    defAns{4} = acquisitionPrefs.amplifier1Device;
                    usingAcqPrefs = 1;
                else
                    if ~isempty(acquisitionPrefs.amplifier1Device);
                        defAns{4} = acquisitionPrefs.amplifier1Device;
                    end
                    undefinedID = 1;
                end
            end

            if undefinedID
                while undefinedID
                    answer = inputdlg(inputprompts,dlgtitle,numlines,defAns);

                    obj.flygenotype = answer{1};
                    obj.flynumber  = answer{2};
                    obj.cellnumber = answer{3};
                    obj.amplifier1Device = answer{4};
                    if ~sum(strcmp(obj.amplifier1Device,{'MultiClamp700B','MultiClamp700BAux'}))
                        error('AcuisitionPrefs, ''amplifier1Device'', preference is invalid.  Must be: {''MultiClamp700B'',''MultiClamp700BAux''}')
                    end

                    if ~isempty(obj.flynumber) && ~isempty(obj.cellnumber)
                        break
                    end
                end
                disp('****')
            else
                if usingAcqPrefs
                    %                     msgbox(...
                    %                         sprintf('Identifiers are current: \nfly genotype - %s\nfly number - %s\ncell number - %s',...
                    %                         obj.flygenotype,...
                    %                         obj.flynumber,...
                    %                         obj.cellnumber));
                    fprintf('Identifiers are current: \nfly genotype - %s\nfly number - %s\ncell number - %s\namplifier 1 - %s\n',...
                        obj.flygenotype,...
                        obj.flynumber,...
                        obj.cellnumber,...
                        obj.amplifier1Device);
                end
            end
            
            % then set preferences to current values
            setpref('AcquisitionPrefs',...
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
            rawtrials = dir(name);

            obj.n = length(rawtrials)+1;
            
            expt_rawtrials = dir([obj.D,'\','*_Raw_*',...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_*']);
            if isempty(expt_rawtrials)
                obj.expt_n = 1;
                obj.block_n = 0;
            else
                obj.expt_n = length(expt_rawtrials)+1;
                % find latest expt_rawtrial to get the block number
                N = 1;
                dn = expt_rawtrials(1).datenum;
                for num = 1:length(expt_rawtrials)
                    if expt_rawtrials(num).datenum > dn;
                        dn = expt_rawtrials(num).datenum;
                        N = num;
                    end
                end
                load(fullfile(obj.D,expt_rawtrials(N).name));
                obj.block_n = params.trialBlock;
            end
                        
            fprintf('Fly %s, Cell %s currently has %d %s trials \n(Total: %d trials in %d blocks)\n',...
                obj.flynumber,obj.cellnumber,obj.n-1,obj.protocol.protocolName,obj.expt_n-1,obj.block_n);
        end
        
        function updateFileNames(obj,metprop,propevnt)
            obj.D = ['C:\Users\Anthony Azevedo\Acquisition\',datestr(date,'yymmdd'),'\',...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber];
            if ~isempty(obj.rig)
                obj.saveAcquisition();
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
                
                eval(['obj.rig = ' obj.protocol.requiredRig '(''amplifier1Device'',obj.amplifier1Device);']);
                
                addlistener(obj.rig,'StartRun',@obj.writeRunNotes);
                addlistener(obj.rig,'SaveData',@obj.writeTrialNotes);
                addlistener(obj.rig,'SaveData',@obj.saveData);
                if obj.analyze
                    obj.analyzelistener = addlistener(obj.rig,'DataSaved',@obj.runAnalyses);
                end
                if isa(obj.rig,'CameraRig')
                    addlistener(obj.rig,'StartTrial',@obj.cleanUpImages);
                end
                
                devs = fieldnames(obj.rig.devices);
                
                for d = 1:length(devs)
                    % if the device params change (eg filter cutoff), save the
                    % acquisition setup
                    addlistener(obj.rig.devices.(devs{d}),'ParamChange',@obj.saveAcquisition);
                end
                obj.writePrologueNotes
                obj.saveAcquisition();
            end
        end
                
        function warn(obj,warning)
            fprintf(obj.notesFileID,'\t\t\t%s\n',warning);
            fprintf(1,'\t\t\t%s\n',warning);
        end
        
        function openNotesFile(obj)
            curnotesfn = [obj.D,'\notes_',...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'.txt'];

            newnoteslogical = isempty(dir(curnotesfn));
            if newnoteslogical && ~isempty(obj.notesFileID)
                fclose(obj.notesFileID);
            end

            obj.notesFileName = curnotesfn;
            if ~isdir(obj.D)
                mkdir(obj.D);
            end
            
            obj.notesFileID = fopen(obj.notesFileName,'a');
        end
                
        function writePrologueNotes(obj)
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
            if isa(obj.rig,'TwoTrodeRig')
                fprintf(obj.notesFileID,'\t{%s,%s}',...
                            obj.rig.devices.amplifier_1.mode,...
                            obj.rig.devices.amplifier_2.mode);
                fprintf(1,'\t{%s,%s}',...
                            obj.rig.devices.amplifier_1.mode,...
                            obj.rig.devices.amplifier_2.mode);
            end
            
            paramnames = fieldnames(obj.protocol.params);
            for i = 1:length(paramnames);
                val = obj.protocol.params.(paramnames{i});
                if length(val)>1
                    val = ['[' num2str(val) ']'];
                else
                    val = num2str(val);
                end
                fprintf(obj.notesFileID,', %s=%s', paramnames{i},val);
                fprintf(1,', %s=%s', paramnames{i},val);
            end
            fprintf(obj.notesFileID,'\n');
            fprintf(1,'\n');
        end
        
        function writeTrialNotes(obj,varargin)
            % data has been saved and obj.n increased
            fprintf(obj.notesFileID,'\t\t%d, %s trial %d',...
                obj.expt_n-1,...
                obj.protocol.protocolName,...
                obj.n-1);
            fprintf(1,'\t\t%d, %s trial %d',obj.expt_n-1, obj.protocol.protocolName,obj.n-1);
            paramsToIter = obj.protocol.paramsToIter;
            for pti = 1:length(paramsToIter)
                pname = paramsToIter{pti};
                fprintf(obj.notesFileID,', %s=%.2f',pname(1:end-1),obj.protocol.params.(pname(1:end-1)));
                fprintf(1,', %s=%.2f',pname(1:end-1),obj.protocol.params.(pname(1:end-1)));
            end
            fprintf(obj.notesFileID,', %s\n',datestr(clock,13));
            fprintf(1,', %s\n',datestr(clock,13));
        end

        
        function saveData(obj,varargin)
            data = obj.rig.inputs.data;
            data.params = obj.protocol.params;
            if isa(obj.rig,'EPhysRig')
                data.params.mode = obj.rig.devices.amplifier.mode;
                data.params.gain = obj.rig.devices.amplifier.gain;
                if isa(obj.rig.devices.amplifier,'MultiClamp700B')
                    data.params.secondary_gain = obj.rig.devices.amplifier.secondary_gain;
                end
            end
            if isa(obj.rig,'TwoTrodeRig')
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
            data.name = sprintf(regexprep(obj.getRawFileStem,'\\','\\\'),obj.n);
            data.tags = obj.tags;
            
            save(data.name, '-struct', 'data');
            % save(obj.rig.inputs.data.name,'current','voltage','name','params');
            obj.n = obj.n + 1;
            obj.expt_n = obj.expt_n+1;

            if isa(obj.rig,'CameraRig')
                imagedir = regexprep(regexprep(data.name,'Raw','Images'),'.mat','');
                mkdir(imagedir);
                images = dir([obj.D,'\',obj.protocol.protocolName,'_Image_*']);
                if isempty(images)
                    h = msgbox('No images. Save, Close Image?');
                    set(h, 'position',[1280 700 170 52.5])
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
        end
        
        function cleanUpImages(obj,varargin)
            images = dir([obj.D,'\',obj.protocol.protocolName,'_Image_*']);
            if ~isempty(images)
                dirname = sprintf(regexprep(obj.getRawFileStem,'\\','\\\'),obj.n-1);
                imagedir = regexprep(regexprep(dirname,'Raw','Images'),'.mat','');
                if ~isdir(fullfile(obj.D,imagedir))
                    imagedir = fullfile(obj.D,'archive');
                    if ~isdir(imagedir);
                        mkdir(imagedir);
                    end
                end
                for im = 1:length(images)
                    [success,m,~] = movefile(fullfile(obj.D,images(im).name),imagedir);
                    if ~success
                        error('Image File %s not moved: %s\n',images(im).name,m);
                    end
                end
            end
        end
            
        function saveAcquisition(obj,varargin)
            if ~isdir(obj.D)
                mkdir(obj.D);
            end

            name = [obj.D,'\Acquisition_', ...
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