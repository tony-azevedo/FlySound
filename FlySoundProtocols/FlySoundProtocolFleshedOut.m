classdef FlySoundProtocolFleshedOut < handle
    
    properties (Constant, Abstract) 
        protocolName;
    end
    
    properties (Hidden)
        n               % current trial
        x               % current x
        stimx           % stimulus x
        y               % current y
        x_units
        y_units
        D               % main directory
        dataFileName    % filename for data struct
        data
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
        
        function obj = FlySoundProtocolFleshedOut(varargin)
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
            end
            
            % assign updated values of input parameters
            if isfield(p.Results,'fly_genotype') && isempty(p.Results.fly_genotype)
                while isempty(obj.fly_genotype)
                    obj.fly_genotype = input(sprintf('Enter Fly Genotype (current - %s):  ',acquisitionPrefs.fly_genotype),'s');
                    if ~isempty(acquisitionPrefs.fly_genotype)
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
                    if ~isempty(acquisitionPrefs.fly_number)
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
                    if ~isempty(acquisitionPrefs.cell_number)
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
            
            obj.recgain = readGain();
            obj.recmode = readMode();
            obj.createAIAOSessions();
            obj.aiSession.Rate = p.Results.aiSamprate;

            obj.defineParameters();  % Saving Params.  This can be updated in other protocols
            obj.createDataStructBoilerPlate();  % Saving Params.  This can be updated in other protocols

            obj.loadData();
            obj.x = [];              % current x
            obj.y = [];              % current y
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
            p = inputParser;
            addRequired(p,'famN');
            addOptional(p,'vm_id',0);
            parse(p,famN,varargin{:});
            
            % stim_mat = generateStimFamily(obj);
            trialdata = obj.dataBoilerPlate;
            trialdata.Vm_id = p.Results.vm_id;

            obj.recgain = readGain();
            obj.recmode = readMode();
            trialdata.recgain = obj.recgain;
            trialdata.recmode = obj.recmode;
            if strcmp(obj.recmode,'IClamp')
                trialdata.currentscale = obj.recgain; %%???????
                trialdata.voltagescale = obj.recgain; %10.3 when output gain is 100; % scaling factor for voltage (mV)
            elseif strcmp(obj.recmode,'VClamp')
                trialdata.currentscale = obj.recgain*trialdata.headstagegain; %200                             % scaling factor for current (pA)
                trialdata.voltagescale = 20; %10.3 when output gain is 100;   % scaling factor for voltage (mV)
            end
            trialdata.currentoffset= -0.0335;                                 % What is this?
            trialdata.voltageoffset = 0*trialdata.voltagescale;                 % offset for voltage
            
            trialdata.durSweep = 2;
            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;
            
            obj.x = ((1:obj.aiSession.Rate*obj.aiSession.DurationInSeconds) - 1)/obj.aiSession.Rate;
            obj.x_units = 's';
            
            for fam = 1:famN
                %addTrialParametersDataStruct();
                %addStimToAOSession();

                fprintf('Trial %d\n',obj.n);

                trialdata.trial = obj.n;

                obj.y = obj.aiSession.startForeground; %plot(x); drawnow
                voltage = obj.y;
                current = obj.y;
                
                % apply scaling factors
                current = (current-trialdata.currentoffset)*trialdata.currentscale;
                voltage = voltage*trialdata.voltagescale-trialdata.voltageoffset;
                
                switch obj.recmode
                    case 'VClamp'
                        obj.y = current;
                        obj.y_units = 'pA';
                    case 'IClamp'
                        obj.y = voltage;
                        obj.y_units = 'mV';
                end
                
                obj.saveData(trialdata,current,voltage)% save data(n)
                
                obj.displayTrial()
            end
        end
                
        function displayTrial(obj)
            figure(1);
            redlines = findobj(1,'Color',[1, 0, 0]);
            set(redlines,'color',[1 .8 .8]);
            line(obj.x,obj.y,'color',[1 0 0],'linewidth',1);
            box off; set(gca,'TickDir','out');
            switch obj.recmode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
            xlabel('Time (s)'); %xlim([0 max(t)]);
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
            obj.showParams
        end
        
        function showParams(obj,varargin)
            disp('')
            disp(obj.params);
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
        
        function defaults = getDefaults(obj)
            defaults = getpref(['defaults',obj.protocolName]);
        end

    end % methods
    
    methods (Access = protected)
                
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage');
            
            % configure AO
            obj.aoSession = daq.createSession('ni');
            obj.aoSession.addAnalogOutputChannel('Dev1',0, 'Voltage');
            
            obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
            obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
        end
        
        function defineParameters(obj)
            p = obj.params;
            p.sampratein = 10000;
            p.samprateout = 10000;
            p.durSweep = [];
            p.Vm_id = 0;
            p.recmode = readMode();
            p.recgain = readGain();

            defaults = obj.getDefaults;
            if ~isempty(defaults)
                dnames = fieldnames(defaults);
                for d = 1:length(defaults)
                    p.(dnames{d}) = defaults.(dnames{d});
                end
            end
            obj.params = p;
            obj.setDefaults;
        end
        
        function createDataStructBoilerPlate(obj)
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?
            dbp.protocolName = obj.protocolName;
            dbp.date = date;
            dbp.flynumber = obj.fly_number;
            dbp.flygenotype = obj.fly_genotype;
            dbp.cellnumber = obj.cell_number;
            dbp.headstagegain = 1;
            dbp.vclampoutputfactor = 100;  %mV/V in V clamp;
            dbp.iclampoutputfactor = 2/dbp.headstagegain;  %nA/V in V clamp;
            dbp.currentscale = 1000/(obj.recgain*dbp.headstagegain); % mV/gainsetting gives pA
            dbp.voltagescale = 1000/(obj.recgain); % mV/gainsetting gives pA; % mV/gainsetting gives mV
            dbp.currentoffset= -0.0335;                                 % What is this?
            dbp.voltageoffset = 0*dbp.voltagescale;                 % offset for voltage
            dbp.trial = [];
            obj.dataBoilerPlate = dbp;
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
        
        
    end % protected methods
    
    methods (Static)
    end
end % classdef