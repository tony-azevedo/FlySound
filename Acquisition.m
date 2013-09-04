classdef Acquisition < handle
    
    properties (Constant) 
    end
    
    properties (Hidden, SetAccess = protected)
        n               % current trial
        expt_n          % current experiment trial
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
    end
    
    properties (SetObservable, AbortSet)
        analyze
    end
    
    % Define an event called InsufficientFunds
    events
    end
    
    methods
        function obj = Acquisition(varargin)
            
            obj.setIdentifiers(varargin{:})
            obj.updateFileNames()

            addlistener(...
                obj,...
                'analyze',...
                'PostSet',@obj.setAnalysisFlag);

            % set a simple protocol
            obj.setProtocol('SealTest');
            
            obj.openNotesFile();
            obj.saveAcquisition();
            obj.analyze = 1;

        end
        
        function run(obj,varargin)
            if nargin>1
                repeats = varargin{1};
            else
                repeats = 1;
            end
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
            if isempty(rawtrials)
                obj.n = 1;
                obj.expt_n = 1;
            else
                obj.n = length(rawtrials)+1;
            end
            expt_rawtrials = dir([obj.D,'\','*_Raw_*',...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_*']);
            if isempty(expt_rawtrials)
                obj.expt_n = 1;
            else
                obj.expt_n = length(expt_rawtrials)+1;
            end
            
            fprintf('Fly %s, Cell %s currently has %d %s trials (%d total)\n',obj.flynumber,obj.cellnumber,obj.n-1,obj.protocol.protocolName,obj.expt_n-1);
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
                addlistener(obj.rig,'StartTrial',@obj.writeTrialNotes);
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
                obj.saveAcquisition();
            end
        end
        
        function writeTrialNotes(obj,varargin)
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
            fprintf(obj.notesFileID,', %s\n',datestr(clock,13));
            fprintf(1,', %s\n',datestr(clock,13));
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
            obj.notesFileID = fopen(obj.notesFileName,'a');
            if newnoteslogical
                obj.writePrologueNotes
            end
        end
        
        function writeRunNotes(obj,varargin)
            obj.notesFileID = fopen(obj.notesFileName,'a');
            
            fprintf(obj.notesFileID,'\n\t%s - %s - %s; F%s_C%s\n',...
                obj.protocol.protocolName,datestr(clock,13),...
                obj.flygenotype,obj.flynumber,obj.cellnumber);
            fprintf(1,'\n\t%s - %s - %s; F%s_C%s\n',...
                obj.protocol.protocolName,datestr(clock,13),...
                obj.flygenotype,obj.flynumber,obj.cellnumber);
            
            if isa(obj.rig,'EPhysRig')
                obj.protocol.setParams('mode',obj.rig.devices.amplifier.mode);
            end

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
        
        function saveData(obj,varargin)
            data = obj.rig.inputs.data;
            data.params = obj.protocol.params;
            data.params.trial = obj.n;
            data.name = sprintf(regexprep(obj.getRawFileStem,'\\','\\\'),obj.n);
            
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
                    '(obj.rig.inputs.data,obj.protocol.params,obj.protocol.x);'])
            end
        end
            
    end
    
end % classdef