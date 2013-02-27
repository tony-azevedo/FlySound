classdef FlySoundProtocol < handle
    
    properties (Constant, Abstract) 
        protocolName;
    end
    
    properties (Hidden)
        n               % current trial
        x               % current x
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
        rec_gain        % amp gain
        rec_mode        % amp mode
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
            
            obj.rec_gain = readGain();
            obj.rec_mode = readMode();
            obj.createAIAOSessions();
            obj.aiSession.Rate = p.Results.aiSamprate;
            obj.createDataStructBoilerPlate();  % Standard Params.  This can be updated in other protocols
            obj.loadData();
            obj.x = [];              % current x
            obj.y = [];              % current y
            obj.x_units = [];
            obj.y_units = [];

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

            obj.rec_gain = readGain();
            obj.rec_mode = readMode();
            trialdata.recgain = obj.rec_gain;
            trialdata.recmode = obj.rec_mode;
            if strcmp(obj.rec_mode,'IClamp')
                trialdata.currentscale = obj.rec_gain; %%???????
                trialdata.voltagescale = obj.rec_gain; %10.3 when output gain is 100; % scaling factor for voltage (mV)
            elseif strcmp(obj.rec_mode,'VClamp')
                trialdata.currentscale = obj.rec_gain*trialdata.headstagegain; %200                             % scaling factor for current (pA)
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
                
                switch obj.rec_mode
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
            switch obj.rec_mode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
            xlabel('Time (s)'); %xlim([0 max(t)]);
        end
        
        function setparams(obj,varargin)
            
        end
        function showparams(obj,varargin)
            
        end

        function setdefaults(obj,varargin)
            p = inputParser;
            names = fieldnames(obj.dataBoilerPlate);
            for name = names
                addOptional(p,name{1});
            end
            parse(p,varargin{:});
            results = fielnames(p.Results);
            for r = results
                setpref(['defaults',obj.protocolName],...
                    ['default',r{1}],...
                    p.Results.(r{1}));
            end
        end
        
        function showdefaults(obj)
            disp('');
            disp(getpref(['defaults',obj.protocolName]));
        end
        
        function defaults = getdefaults(obj)
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
        
        function createDataStructBoilerPlate(obj)
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?
            dbp.protocolName = obj.protocolName;
            dbp.date = date;
            dbp.flynumber = obj.fly_number;
            dbp.flygenotype = obj.fly_genotype;
            dbp.cellnumber = obj.cell_number;
            dbp.sampratein = obj.aiSession.Rate;
            dbp.samprateout = obj.aoSession.Rate;
            dbp.recmode = obj.rec_mode;
            dbp.recgain = obj.rec_gain;
            dbp.headstagegain = 1;
            dbp.Vm_id = 0;
            dbp.currentscale = 1000/(obj.rec_gain*dbp.headstagegain); % mV/gainsetting gives pA
            dbp.voltagescale = 1000/(obj.rec_gain); % mV/gainsetting gives pA; % mV/gainsetting gives mV
            dbp.currentoffset= -0.0335;                                 % What is this?
            dbp.voltageoffset = 0*dbp.voltagescale;                 % offset for voltage
            dbp.trial = [];
            dbp.durSweep = [];
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
                obj.data = obj.dataBoilerPlate;
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

            % TODO: For speed test appending to data;
            obj.data(obj.n) = trialdata;
            data = obj.data;
            save(obj.dataFileName,'data');

            obj.n = length(obj.data)+1;
        end
        
        
    end % protected methods
    
    methods (Static)
    end
end % classdef