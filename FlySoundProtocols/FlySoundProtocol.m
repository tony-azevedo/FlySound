classdef FlySoundProtocol < handle
    
    properties (Constant, Abstract) 
        protocolName;
    end
    
    properties (Hidden, SetAccess = protected)
        n               % current trial
        expt_n          % current experiment trial
        x               % current x
        stimx           % stimulus x
        y               % current y
        stim            % current stim
        x_units
        y_units
        D               % main directory
        dataFileName    % filename for data struct
        notesFileName
        notesFileID
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = protected)
        modusOperandi   % simulate or run?
        fly_genotype
        fly_number
        cell_number
        recgain        % amp gain
        recmode        % amp mode
        dataBoilerPlate
        params
        aiSession
        aoSession
        rig
    end
    
    % Define an event called InsufficientFunds
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = FlySoundProtocol(varargin)
            % parse inputs for updates to saving parameters.
            p = inputParser;            
            p.addParamValue('fly_genotype','',@ischar);
            p.addParamValue('fly_number',[],@isnumeric);
            p.addParamValue('cell_number',[],@isnumeric);
            p.addParamValue('aiSamprate',10000,@isnumeric);
            p.addParamValue('modusOperandi','Run',...
                @(x) any(validatestring(x,{'Run','Stim','Cal'})));
            
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;
            
            obj.setIdentifiers(p)
            
            obj.D = ['C:\Users\Anthony Azevedo\Acquisition\',datestr(date,'yymmdd'),'\',...
                datestr(date,'yymmdd'),'_F',obj.fly_number,'_C',obj.cell_number];
            
            obj.dataFileName = [obj.D,'\',obj.protocolName,'_',...
                datestr(date,'yymmdd'),'_F',obj.fly_number,'_C',obj.cell_number,'.h5'];
            
            obj.openNotesFile();
            
            obj.recgain = readGain();
            obj.recmode = readMode();
            obj.createRig();
            obj.aiSession.Rate = p.Results.aiSamprate;

            obj.createDataStructBoilerPlate();  % Saving Params.  This can be updated in other protocols
            obj.defineParameters();  % Saving Params.  This can be updated in other protocols
            obj.findPrevTrials();

            obj.x = [];              % current x
            obj.y = [];              % current y
            obj.setupStimulus();            
            obj.x_units = [];
            obj.y_units = [];
            obj.showParams;
        end
        
        function stim = generateStimulus(obj,varargin)
            p = inputParser;
            addRequired(p,'obj');
            addOptional(p,'famN');
            parse(p,varargin{:});
        end

        function run(obj,famN,varargin)
            % Runtime routine for the protocol. obj.run(numRepeats)
            % preassign space in data for all the trialdata structs
        end
                
        function displayTrial(obj)
            % define in each subclass
        end
        
        function setParams(obj,varargin)
            p = inputParser;
            names = fieldnames(obj.params);
            for i = 1:length(names)
                p.addParamValue(names{i},obj.params.(names{i}),@(x) strcmp(class(x),class(obj.params.(names{i}))));
            end
            parse(p,varargin{:});
            results = fieldnames(p.Results);
            for r = 1:length(results)
                obj.params.(results{r}) = p.Results.(results{r});
            end
            obj.setupStimulus
            obj.showParams
        end
        
        function showParams(obj,varargin)
            disp('')
            disp(obj.protocolName)
            disp(obj.params);
        end

        function defaults = getDefaults(obj)
            defaults = getpref(['defaults',obj.protocolName]);
            if isempty(defaults)
                defaultsnew = [fieldnames(obj.params),struct2cell(obj.params)]';
                obj.setDefaults(defaultsnew{:});
                defaults = obj.params;
            end
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
                setpref(['defaults',obj.protocolName],...
                    [results{r}],...
                    p.Results.(results{r}));
            end
        end
        
        function showDefaults(obj)
            disp('');
            disp('DefaultParameters');
            disp(getpref(['defaults',obj.protocolName]));
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
            name = [obj.D,'\',obj.protocolName,'_Raw_', ...
                datestr(date,'yymmdd'),'_F',obj.fly_number,'_C',obj.cell_number,'_', ...
                '%s.mat'];
            fprintf(1,'%s\n%s\n%s\n',obj.D,obj.dataFileName,name);
            
        end

        function name = getDataFileName(obj)
            name = obj.dataFileName;
        end

        function name = getRawFileStem(obj)
            name = [obj.D,'\',obj.protocolName,'_Raw_', ...
                datestr(date,'yymmdd'),'_F',obj.fly_number,'_C',obj.cell_number,'_', ...
                '%d.mat'];            
        end

    end % methods
    
    methods (Access = protected)
        
        function setIdentifiers(obj,p)

            numlines = [1 1 1];
            defAns = {'','',''};
            inputprompts{1} = 'Fly Genotype: ';
            if isfield(p.Results,'fly_genotype') && ~isempty(p.Results.fly_genotype)
                obj.fly_genotype = p.Results.fly_genotype;
                defAns{1} = obj.fly_genotype;
                numlines(1) = 0;
            end
            
            inputprompts{2} = 'Fly Number: ';
            if isfield(p.Results,'fly_number') && ~isempty(p.Results.fly_number)
                obj.fly_number = num2str(p.Results.fly_number);
                defAns{2} = obj.fly_number;
                numlines(2) = 0;
            end
            
            inputprompts{3} = 'Cell Number: ';
            if isfield(p.Results,'cell_number') && ~isempty(p.Results.cell_number)
                obj.cell_number = num2str(p.Results.cell_number);
                defAns{3} = obj.cell_number;
                numlines(3) = 0;
            end

            if ispref('AcquisitionPrefs')
                acquisitionPrefs = getpref('AcquisitionPrefs');
            else
                acquisitionPrefs.fly_genotype = [];
                acquisitionPrefs.fly_number = [];
                acquisitionPrefs.cell_number = [];
                acquisitionPrefs.last_timestamp = 0;
            end
            
            undefinedID = 0;
            usingAcqPrefs = 0;
            dlgtitle = 'Enter remaining IDs (integers please)';
            if isempty(obj.fly_genotype)
                if datenum([0 0 0 1 0 0]) > (now-acquisitionPrefs.last_timestamp)  
                    obj.fly_genotype = acquisitionPrefs.fly_genotype;
                    defAns{1} = acquisitionPrefs.fly_genotype;
                    usingAcqPrefs = 1;
                else
                    if ~isempty(acquisitionPrefs.fly_genotype);
                        defAns{1} = acquisitionPrefs.fly_genotype;
                    end
                    undefinedID = 1;
                end
            end
            if isempty(obj.fly_number)
                if datenum([0 0 0 1 0 0]) > (now-acquisitionPrefs.last_timestamp)  
                    obj.fly_number = acquisitionPrefs.fly_number;
                    defAns{2} = acquisitionPrefs.fly_number;
                    usingAcqPrefs = 1;
                else
                    if ~isempty(acquisitionPrefs.fly_number);
                        defAns{2} = acquisitionPrefs.fly_number;
                    end
                    undefinedID = 1;
                end
            end
            if isempty(obj.cell_number)
                if datenum([0 0 0 1 0 0]) > (now-acquisitionPrefs.last_timestamp)  
                    obj.cell_number = acquisitionPrefs.cell_number;
                    defAns{3} = num2str(acquisitionPrefs.cell_number);
                    usingAcqPrefs = 1;
                else
                    if ~isempty(acquisitionPrefs.cell_number);
                        defAns{3} = acquisitionPrefs.cell_number;
                    end
                    undefinedID = 1;
                end
            end
            
            if undefinedID
                while undefinedID
                    answer = inputdlg(inputprompts,dlgtitle,numlines,defAns);
                    obj.fly_genotype = answer{1};
                    obj.fly_number  = answer{2};
                    obj.cell_number = answer{3};
                    if ~isempty(obj.fly_number) && ~isempty(obj.cell_number)
                        break
                    end
                end
                disp('****')
            else
                if usingAcqPrefs
                    %                     msgbox(...
                    %                         sprintf('Identifiers are current: \nfly genotype - %s\nfly number - %s\ncell number - %s',...
                    %                         obj.fly_genotype,...
                    %                         obj.fly_number,...
                    %                         obj.cell_number));
                    fprintf('Identifiers are current: \nfly genotype - %s\nfly number - %s\ncell number - %s\n',...
                        obj.fly_genotype,...
                        obj.fly_number,...
                        obj.cell_number);
                end
            end
            
            % then set preferences to current values
            setpref('AcquisitionPrefs',...
                {'fly_genotype','fly_number','cell_number','last_timestamp'},...
                {obj.fly_genotype,obj.fly_number,obj.cell_number, now});
        end
        
        
        function createRig(obj)
            % createRig is to start an acquisition routine
            fprintf('** Protocol Subclass Lacks Rig or AIAO Session! **\n');
        end
        
        function createDataStructBoilerPlate(obj)
            % Data Structure as basis for each entry in the saved data
            % structure.  Create this whenever you need to
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?
            dbp.protocolName = obj.protocolName;
            dbp.date = datestr(date,'yymmdd');
            dbp.flynumber = obj.fly_number;
            dbp.flygenotype = obj.fly_genotype;
            dbp.cellnumber = obj.cell_number;
            dbp.trial = [];
            dbp.repeats = [];
            dbp.recgain = readGain();
            dbp.recmode = readMode();
            dbp.headstagegain = 1;
            
            dbp.daqCurrentOffset = 0.0000; % 0.006; %nA There is some current offset when Vdaq = 0
            % to get this number, run  the zeroDAQOut routine and mess with
            % ext_offset
            
            % Current Injection = DAQ_voltage*m+b
            % DAQ_out_voltage = (nA-b)/m;  % to get these numbers, run the
            % currentInputCalibration routine
            dbp.daqout_to_current = 2/dbp.headstagegain; % m, multiply DAQ voltage to get nA injected
            dbp.daqout_to_current_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            dbp.daqout_to_voltage = .02; % m, multiply DAQ voltage to get mV injected (combines voltage divider and input factor) ie 1 V should give 2mV
            dbp.daqout_to_voltage_offset = 0;  % b, add to DAQ voltage to get the right offset
            
            dbp.rearcurrentswitchval = 1; % [V/nA];
            dbp.hardcurrentscale = 1/(dbp.rearcurrentswitchval*dbp.headstagegain); % [V]/current scal gives nA;
            dbp.hardcurrentoffset = -6.6238/1000;
            dbp.hardvoltagescale = 1/(10); % reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            dbp.hardvoltageoffset = -6.2589/1000; % in V, reads 10X Vm, mult by 1/10 to get actual reading in V, multiply in code to get mV
            
            dbp.scaledcurrentscale = 1000/(dbp.recgain*dbp.headstagegain); % [mV/V]/gainsetting gives pA
            dbp.scaledcurrentoffset = 0; % [mV/V]/gainsetting gives pA
            dbp.scaledvoltagescale = 1000/(dbp.recgain); % mV/gainsetting gives mV
            dbp.scaledvoltageoffset = 0; % mV/gainsetting gives mV
            
            obj.dataBoilerPlate = dbp;
        end
        
        function defineParameters(obj)
            obj.params.sampratein = 10000;
            obj.params.samprateout = 10000;
            obj.params.durSweep = [];
            obj.params.Vm_id = 0;
            
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            try obj.stimx = ((1:obj.params.samprateout*obj.params.durSweep))/obj.params.samprateout;
            catch e
                if ~isfield(obj.params,'samprateout');
                    obj.stimx = [];
                end
            end
            obj.stim = zeros(size(obj.stimx));
            obj.x = ((1:obj.params.sampratein*obj.params.durSweep) - 1)/obj.params.sampratein;
        end
        
        function trialdata = runtimeParameters(obj,varargin)
            obj.recgain = readGain();
            obj.recmode = readMode();
            obj.dataBoilerPlate.recgain = obj.recgain;
            obj.dataBoilerPlate.recmode = obj.recmode;
            
            obj.dataBoilerPlate.scaledcurrentscale = 1000/(obj.recgain*obj.dataBoilerPlate.headstagegain); % [mV/V]/gainsetting gives pA
            obj.dataBoilerPlate.scaledvoltagescale = 1000/(obj.recgain); % mV/gainsetting gives mV
            
            p = inputParser;
            addOptional(p,'repeats',1);
            addOptional(p,'vm_id',obj.params.Vm_id);
            parse(p,varargin{:});
            
            trialdata = appendStructure(obj.dataBoilerPlate,obj.params);
            trialdata.Vm_id = p.Results.vm_id;
            trialdata.repeats = p.Results.repeats;
        end
        
        function findPrevTrials(obj)
            % make a directory if one does not exist
            if ~isdir(obj.D)
                mkdir(obj.D);
            end
            
            % check whether a saved data file exists with today's date
            name = [obj.D,'\',obj.protocolName,'_Raw_', ...
                datestr(date,'yymmdd'),'_F',obj.fly_number,'_C',obj.cell_number,'_*'];
            rawtrials = dir(name);
            if isempty(rawtrials)
                % if no saved data exists then this is the first trial
                %obj.data = appendStructure(obj.dataBoilerPlate,obj.params);
                %obj.data = obj.data(1:end-1);
                obj.n = 1;
                obj.expt_n = 1;
            else
                %load current data file
                %temp = load(obj.dataFileName,'data');
                %i = h5info(obj.dataFileName);
                %obj.data = temp.data;
                obj.n = length(rawtrials)+1;
                
            end
            expt_rawtrials = dir([obj.D,'\','*_Raw_*',...
                datestr(date,'yymmdd'),'_F',obj.fly_number,'_C',obj.cell_number,'_*']);
            if isempty(expt_rawtrials)
                obj.expt_n = 1;
            else
                obj.expt_n = length(expt_rawtrials)+1;                
            end

            fprintf('Fly %s, Cell %s currently has %d %s trials (%d total)\n',obj.fly_number,obj.cell_number,obj.n-1,obj.protocolName,obj.expt_n-1);
        end
        
        function stim_mat = generateStimFamily(obj)
            for paramsToVary = obj.params
                stim_mat = generateStimulus;
            end
        end
        
        function saveData(obj,trialdata,current,voltage,varargin)
            trialdata.trial = obj.n;
            params = trialdata;
            %tic
            name = [obj.D,'\',obj.protocolName,'_Raw_', ...
                datestr(date,'yymmdd'),'_F',obj.fly_number,'_C',obj.cell_number,'_', ...
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
            %fprintf('Save mat: '),toc

            % 1st version: long data struct
            % TODO: For speed, test appending to data; It is O(n^2) right
            % now
            %            trialdata.trial = obj.n;
            %data = obj.data;
            %save(obj.dataFileName,'data');
            
            % 2nd option, append data struct
            % options.overwrite = 0; 
            % tic
            % exportStructToHDF5(trialdata,obj.dataFileName,name,options);
            % fprintf('Append hdf5: '),toc
            
            % 3rd option save individual data struct
            %             name = [obj.D,'\',obj.protocolName,'_Params_', ...
            %                 datestr(date,'yymmdd'),'_F',obj.fly_number,'_C',obj.cell_number,'_', ...
            %                 num2str(obj.n)];
            %             save(name,'params');
            %             fprintf('Save data: '),toc

            obj.n = obj.n + 1;
            obj.expt_n = 1;
        end
        
        function openNotesFile(obj)
            curnotesfn = [obj.D,'\notes_',...
                datestr(date,'yymmdd'),'_F',obj.fly_number,'_C',obj.cell_number,'.txt'];
            % if the file does not exist, restart the current trial number
            obj.notesFileName = curnotesfn;
            obj.notesFileID = fopen(obj.notesFileName,'a');    
        end
        
        function writePrologueNotes(obj)
            obj.notesFileID = fopen(obj.notesFileName,'a');

            fprintf(obj.notesFileID,'\n\t%s - %s - %s; F%s_C%s\n',...
                obj.protocolName,datestr(clock,13),...
                obj.fly_genotype,obj.fly_number,obj.cell_number);
            fprintf(1,'\n\t%s - %s - %s; F%s_C%s\n',...
                obj.protocolName,datestr(clock,13),...
                obj.fly_genotype,obj.fly_number,obj.cell_number);

            fprintf(obj.notesFileID,'\t%s',obj.recmode);
            fprintf(1,'\t%s',obj.recmode);

            paramnames = fieldnames(obj.params);
            for i = 1:length(paramnames);
                val = obj.params.(paramnames{i});
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
            fprintf(obj.notesFileID,'\t\t%d, %s trial %d',...
                obj.expt_n,...
                obj.protocolName,...
                obj.n);
            fprintf(1,'\t\t%d, %s trial %d',obj.expt_n, obj.protocolName,obj.n);
            if nargin>1
                paramnames = varargin;
                for i = 1:length(paramnames);
                    val = obj.params.(paramnames{i});
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
        
    end % protected methods
    
    methods (Static)
    end
end % classdef