classdef FlySoundProtocol < handle
    
    properties (Constant, Abstract) 
        protocolName;
    end
    
    properties (Hidden, SetAccess = protected)
        n               % current trial
        x               % current x
        stimx           % stimulus x
        y               % current y
        stim            % current stim
        x_units
        y_units
        D               % main directory
        dataFileName    % filename for data struct
        data
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
                @(x) any(validatestring(x,{'Run','Stim'})));
            
            parse(p,varargin{:});
            obj.modusOperandi = p.Results.modusOperandi;
            
            % first assign the saved values
            if ispref('AcquisitionPrefs')
                acquisitionPrefs = getpref('AcquisitionPrefs');
            else
                acquisitionPrefs.fly_genotype = [];
                acquisitionPrefs.fly_number = [];
                acquisitionPrefs.cell_number = [];
                acquisitionPrefs.notes_file_name = [];
            end
            
            % assign updated values of input parameters
            if isfield(p.Results,'fly_genotype') && isempty(p.Results.fly_genotype)
                while isempty(obj.fly_genotype)
                    obj.fly_genotype = input(sprintf('Enter Fly Genotype (current - %s):  ',acquisitionPrefs.fly_genotype),'s');
                    if isempty(obj.fly_genotype) && ~isempty(acquisitionPrefs.fly_genotype)
                        obj.fly_genotype = acquisitionPrefs.fly_genotype;
                    end
                end
            elseif isfield(p.Results,'fly_genotype') && ~isempty(p.Results.fly_genotype)
                obj.fly_genotype = p.Results.fly_genotype;
            end
            
            % assign updated values of input parameters
            if isfield(p.Results,'fly_number') && isempty(p.Results.fly_number)
                while isempty(obj.fly_number)
                    obj.fly_number = input(sprintf('Enter Fly Number (current - %s):  ',acquisitionPrefs.fly_number),'s');
                    if isempty(obj.fly_number) && ~isempty(acquisitionPrefs.fly_number)
                        obj.fly_number = acquisitionPrefs.fly_number;
                    end
                end
            elseif isfield(p.Results,'fly_number') && ~isempty(p.Results.fly_number)
                obj.fly_number = p.Results.fly_number;
            end
            
            % assign updated values of input parameters
            if isfield(p.Results,'cell_number') && isempty(p.Results.cell_number)
                while isempty(obj.cell_number)
                    obj.cell_number = input(sprintf('Enter Cell Number (current - %s):  ',acquisitionPrefs.cell_number),'s');
                    if isempty(obj.cell_number) && ~isempty(acquisitionPrefs.cell_number)
                        obj.cell_number = acquisitionPrefs.cell_number;
                    end
                end
            elseif isfield(p.Results,'cell_number') && ~isempty(p.Results.cell_number)
                obj.cell_number = p.Results.cell_number;
            end
                        
            % then set preferences to current values
            setpref('AcquisitionPrefs',...
                {'fly_genotype','fly_number','cell_number'},...
                {obj.fly_genotype,obj.fly_number,obj.cell_number});
            
            obj.D = ['C:\Users\Anthony Azevedo\Acquisition\',date,'\',...
                date,'_F',obj.fly_number,'_C',obj.cell_number];
            
            obj.dataFileName = [obj.D,'\',obj.protocolName,'_',...
                date,'_F',obj.fly_number,'_C',obj.cell_number,'.mat'];
            
            obj.openNotesFile();
            
            obj.recgain = readGain();
            obj.recmode = readMode();
            obj.createAIAOSessions();
            obj.aiSession.Rate = p.Results.aiSamprate;

            obj.createDataStructBoilerPlate();  % Saving Params.  This can be updated in other protocols
            obj.defineParameters();  % Saving Params.  This can be updated in other protocols
            obj.loadData();

            obj.x = [];              % current x
            obj.y = [];              % current y
            obj.setupStimulus();            
            obj.x_units = [];
            obj.y_units = [];
            obj.showDefaults
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
        
    end % methods
    
    methods (Access = protected)
                
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            fprintf('** Protocol Subclass Lacks AIAO Session! **\n');
        end
        
        function createDataStructBoilerPlate(obj)
            % Data Structure as basis for each entry in the saved data
            % structure.  Create this whenever you need to
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?
            dbp.protocolName = obj.protocolName;
            dbp.date = date;
            dbp.flynumber = obj.fly_number;
            dbp.flygenotype = obj.fly_genotype;
            dbp.cellnumber = obj.cell_number;
            dbp.trial = [];
            dbp.repeats = [];
            dbp.recgain = readGain();
            dbp.recmode = readMode();
            dbp.headstagegain = 1;
            
            dbp.daqCurrentOffset = 0.006; %nA There is some current offset when Vdaq = 0 
            % to get this number, run  the zeroDAQOut routine and mess with
            % ext_offset

            % Current Injection = DAQ_voltage*m+b
            % DAQ_out_voltage = (nA-b)/m;  % to get these numbers, run the
            % currentInputCalibration routine
            dbp.daqout_to_current = 0.1199709; % m, multiply DAQ voltage to get nA injected
            dbp.daqout_to_current_offset = -0.00150;  % b, add to DAQ voltage to get the right offset

            dbp.rearcurrentswitchval = 1; % [V/nA];
            dbp.hardcurrentscale = 1/(dbp.rearcurrentswitchval*dbp.headstagegain); % [V]/current scal gives nA;

            dbp.scaledcurrentscale = 1000/(dbp.recgain*dbp.headstagegain); % [mV/V]/gainsetting gives pA
            dbp.scaledcurrentoffset = -0.00890326; % [mV/V]/gainsetting gives pA
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
        
        function loadData(obj)
            % make a directory if one does not exist
            if ~isdir(obj.D)
                mkdir(obj.D);
            end
            
            % check whether a saved data file exists with today's date
            if isempty(dir(obj.dataFileName))
                % if no saved data exists then this is the first trial
                obj.data = appendStructure(obj.dataBoilerPlate,obj.params);
                obj.data = obj.data(1:end-1);
                obj.n = length(obj.data)+1;
            else
                %load current data file
                temp = load(obj.dataFileName,'data');
                obj.data = temp.data;
                obj.n = length(obj.data)+1;

            end
            fprintf('Fly %s, Cell %s currently has %d trials\n',obj.fly_number,obj.cell_number,length(obj.data));
            
        end
        
        function stim_mat = generateStimFamily(obj)
            for paramsToVary = obj.params
                stim_mat = generateStimulus;
            end
        end
        
        function saveData(obj,trialdata,current,voltage)
            save([obj.D,'\',obj.protocolName,'_Raw_', ...
                date,'_F',obj.fly_number,'_C',obj.cell_number,'_', ...
                num2str(obj.n)],'current','voltage');

            % TODO: For speed, test appending to data; It is O(n^2) right
            % now
            trialdata.trial = obj.n;
            obj.data(obj.n) = trialdata;
            data = obj.data;
            save(obj.dataFileName,'data');

            obj.n = length(obj.data)+1;
        end
        
        function openNotesFile(obj)
            curnotesfn = [obj.D,'\notes_',...
                date,'_F',obj.fly_number,'_C',obj.cell_number,'.mat'];
            
            obj.notesFileName = curnotesfn;
            obj.notesFileID = fopen(obj.notesFileName,'a');    
        end
        
        function writePrologueNotes(obj)
        end
        
        function writeTrialNotes(obj)
        end
        
    end % protected methods
    
    methods (Static)
    end
end % classdef