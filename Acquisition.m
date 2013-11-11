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
            obj.setProtocol('SealTest');

            obj.saveAcquisition();

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
                untagel = num2str(untag{t});
                obj.tags = obj.tags(~strcmp(obj.tags,untagel));
            end

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
            p.addParamValue('flygenotype','',@ischar);
            p.addParamValue('flynumber',[],@isnumeric);
            p.addParamValue('cellnumber',[],@isnumeric);
            p.addParamValue('aiSamprate',10000,@isnumeric);
            p.addParamValue('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;
            
            obj.flygenotype = '';
            obj.flynumber = '';
            obj.cellnumber = '';
            
            numlines = [1 1 1];
            defAns = {'','',''};
            inputprompts{1} = 'Fly Genotype: ';
            if isfield(p.Results,'flygenotype') && ~isempty(p.Results.flygenotype)
                obj.flygenotype = p.Results.flygenotype;
                defAns{1} = obj.flygenotype;
                numlines(1) = 0;
            end
            
            inputprompts{2} = 'Fly Number: ';
            if isfield(p.Results,'flynumber') && ~isempty(p.Results.flynumber)
                obj.flynumber = num2str(p.Results.flynumber);
                defAns{2} = obj.flynumber;
                numlines(2) = 0;
            end
            
            inputprompts{3} = 'Cell Number: ';
            if isfield(p.Results,'cellnumber') && ~isempty(p.Results.cellnumber)
                obj.cellnumber = num2str(p.Results.cellnumber);
                defAns{3} = obj.cellnumber;
                numlines(3) = 0;
            end
            
            if ispref('AcquisitionPrefs')
                acquisitionPrefs = getpref('AcquisitionPrefs');
            else
                acquisitionPrefs.flygenotype = [];
                acquisitionPrefs.flynumber = [];
                acquisitionPrefs.cellnumber = [];
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
            
            if undefinedID
                while undefinedID
                    answer = inputdlg(inputprompts,dlgtitle,numlines,defAns);
                    obj.flygenotype = answer{1};
                    obj.flynumber  = answer{2};
                    obj.cellnumber = answer{3};
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
                    fprintf('Identifiers are current: \nfly genotype - %s\nfly number - %s\ncell number - %s\n',...
                        obj.flygenotype,...
                        obj.flynumber,...
                        obj.cellnumber);
                end
            end
            
            % then set preferences to current values
            setpref('AcquisitionPrefs',...
                {'flygenotype','flynumber','cellnumber','last_timestamp'},...
                {obj.flygenotype,obj.flynumber,obj.cellnumber, now});
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
            if isempty(obj.rig) || ~strcmp(obj.protocol.requiredRig,obj.rig.rigName)
                eval(['obj.rig = ' obj.protocol.requiredRig ';']);
                
                addlistener(obj.rig,'StartRun',@obj.writeRunNotes);
                %addlistener(obj.rig,'StartTrial',@obj.writeTrialNotes);
                addlistener(obj.rig,'SaveData',@obj.writeTrialNotes);
                addlistener(obj.rig,'SaveData',@obj.saveData);
                if obj.analyze
                    obj.analyzelistener = addlistener(obj.rig,'DataSaved',@obj.runAnalyses);
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
                    data.params.gain = obj.rig.devices.amplifier.secondary_gain;
                end
            end
            if isa(obj.rig,'CameraRig')
                images = dir([obj.D,'\',obj.protocol.protocolName,'_Image_*']);
                if isempty(images)
                    uiwait(msgbox('There are no images to connect to this trial'))
                    warning('There are no images to connect to this trial')
                else
                    imnums = zeros(length(images));
                    for im = 1:length(images)
                        pattern = [obj.protocol.protocolName,'_Image_'];
                        imnumstr = regexprep(regexp(images(im).name,[pattern '\d+'],'match'),pattern,'');
                        imnums(im) = str2double(imnumstr{1});
                    end
                    imnum = max(unique(imnums));
                    
                    % check record date
                    imfile = dir([obj.D,'\',obj.protocol.protocolName,'_Image_' num2str(imnum) '*']);
                    if now - imfile(end).datenum > datenum([0 0 0 0 0 2]);
                        % imnum = [];
                        warning('Images are old, but now connected to this file')
                        data.IMAGEWARNING = 'Old images are connected to this file';
                        beep;
                    end
                    data.imageNum = imnum;
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
        end
        
        function saveAcquisition(obj,varargin)
            if ~isdir(obj.D)
                mkdir(obj.D);
            end

            name = [obj.D,'\Acquisition_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber];
            acqStruct.flygenotype = obj.flygenotype;
            acqStruct.flynumber = obj.flynumber;
            acqStruct.cellnumber = obj.cellnumber;             %#ok<STRNU>
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