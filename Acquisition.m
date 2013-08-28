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
        %         runlistener
        %         triallistener
        %         inputlistener
        %         flylistener
        %         celllistener
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = protected)
        modusOperandi   % simulate or run?
        flygenotype
        rig
        protocol % can I change this object if it's protected?
        analyses
    end
    
    properties (SetObservable, AbortSet)
        flynumber
        cellnumber    
    end
    
    % Define an event called InsufficientFunds
    events
    end
    
    methods
        
        function obj = Acquisition(varargin)
            addlistener(...
                obj,...
                'flynumber',...
                'PostSet',@obj.updateFileNames);
            addlistener(...
                obj,...
                'cellnumber',...
                'PostSet',@obj.updateFileNames);
            
            obj.setIdentifiers(varargin{:})
            
            obj.setRig();
            addlistener(obj.rig,'StartRun',@obj.writeRunNotes);
            addlistener(obj.rig,'StartTrial',@obj.writeTrialNotes);
            addlistener(obj.rig,'SaveData',@obj.saveData);
            
            obj.setProtocol('PiezoSine');
            obj.findPrevTrials();
            obj.openNotesFile();
       end
             
        function run(varargin)
            if nargin>1
                repeats = varargin{1};
            else
                repeats = 1;
            end 
            obj.rig.run(repeats)
        end
        
        function setRig(obj,varargin)
            numlines = [1];
            defAns = {''};
            inputprompts{1} = 'Rig Class Name: ';
            if ispref('AcquisitionPrefs')
                acquisitionPrefs = getpref('AcquisitionPrefs');
            else
                acquisitionPrefs.rig = [];
            end
            if ~isfield(acquisitionPrefs,'rig')
                acquisitionPrefs.rig = [];
            end
            if nargin>1
                acquisitionPrefs.rig = varargin{1};
            end
            undefinedID = 0;
            usingAcqPrefs = 0;
            dlgtitle = 'Enter Rig Name';
            if isempty(obj.rig)
                if ~isempty(acquisitionPrefs.rig)  
                    eval(['obj.rig = ' acquisitionPrefs.rig]);
                    defAns{1} = acquisitionPrefs.rig;
                    usingAcqPrefs = 1;
                else
                    undefinedID = 1;
                end
            end            
            if undefinedID
                while undefinedID
                    answer = inputdlg(inputprompts,dlgtitle,numlines,defAns);
                    eval(['obj.rig = ' answer{1}]);
                    %                     try eval(['obj.rig = ' answer{1}]);
                    %                     catch
                    %                         warning('Enter a valid Rig Class Name');
                    %                     end
                    if ~isempty(obj.rig)
                        break
                    end
                end
                disp('****')
            else
                if usingAcqPrefs
                    fprintf('Rig is current: \n')%fly genotype - %s\nfly number - %s\ncell number - %s\n',...
                end
            end
            
            % then set preferences to current values
            setpref('AcquisitionPrefs',...
                {'rig'},...
                {obj.rig.rigName});
        end
        
        function setProtocol(obj,prot)
            eval(['obj.protocol = ' prot]);
            obj.protocol.setParams(...
                'sampratein',obj.rig.params.sampratein,...
                'samprateout',obj.rig.params.samprateout);
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
            name = [obj.D,'\',obj.protocolName,'_Raw_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_', ...
                '%d.mat'];            
        end
        
    end % methods
    
    methods (Access = protected)
                
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
        end

        function writeTrialNotes(obj,varargin)
            fprintf(obj.notesFileID,'\t\t%d, %s trial %d',...
                obj.expt_n,...
                obj.protocol.protocolName,...
                obj.n);
            fprintf(1,'\t\t%d, %s trial %d',obj.expt_n, obj.protocol.protocolName,obj.n);
            if nargin>1
                paramnames = varargin;
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
            end
            fprintf(obj.notesFileID,', %s\n',datestr(clock,13));
            fprintf(1,', %s\n',datestr(clock,13));
        end
        
        function warn(obj,warning)
            fprintf(obj.notesFileID,'\t\t\t%s\n',warning);
            fprintf(1,'\t\t\t%s\n',warning);
        end
                
        function updateFileNames(obj,metprop,propevnt)
            obj.D = ['C:\Users\Anthony Azevedo\Acquisition\',datestr(date,'yymmdd'),'\',...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber];
        end

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
                
        function saveData(obj,varargin)
            trialdata.trial = obj.n;
            params = trialdata;
            %tic
            name = [obj.D,'\',obj.protocolName,'_Raw_', ...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'_', ...
                num2str(obj.n)];
            if nargin>4
                if  mod(length(varargin),2)
                    error('Need key value pairs to save data')
                end
                savestr = 'save(name,''current'',''voltage'',''name'',''params''';
                for ex = 1:2:length(varargin)
                    extraname = varargin{ex};
                    eval([extraname '=varargin{ex+1};']);
                    savestr = [savestr ',''' extraname ''''];
                end
                savestr = [savestr ')'];
                eval(savestr);
            else
                save(name,'current','voltage','name','params');
            end
            obj.n = obj.n + 1;
            obj.expt_n = 1;
        end
        
        function openNotesFile(obj)
            if ~isempty(obj.notesFileID)
                fclose(obj.notesFileID);
            end
            curnotesfn = [obj.D,'\notes_',...
                datestr(date,'yymmdd'),'_F',obj.flynumber,'_C',obj.cellnumber,'.txt'];
            % if the file does not exist, restart the current trial number
            obj.notesFileName = curnotesfn;
            obj.notesFileID = fopen(obj.notesFileName,'a'); 
        end
        
        function writeRunNotes(obj)
            obj.notesFileID = fopen(obj.notesFileName,'a');

            fprintf(obj.notesFileID,'\n\t%s - %s - %s; F%s_C%s\n',...
                obj.protocolName,datestr(clock,13),...
                obj.flygenotype,obj.flynumber,obj.cellnumber);
            fprintf(1,'\n\t%s - %s - %s; F%s_C%s\n',...
                obj.protocolName,datestr(clock,13),...
                obj.flygenotype,obj.flynumber,obj.cellnumber);

            fprintf(obj.notesFileID,'\t%s',obj.rig.recmode);
            fprintf(1,'\t%s',obj.recmode);

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
            %TODO
        end
    end % static methods
    
end % classdef