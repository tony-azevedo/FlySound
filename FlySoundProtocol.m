classdef FlySoundProtocol < handle
    
    properties (Hidden)
        
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
        modusOperandi   % simulate or run?
        fly_genotype
        fly_number
        cell_number
        rec_gain
        rec_mode
        D               % main directory
        dataFileName
        data
        dataBoilerPlate
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
                obj.fly_genotype = acquisitionPrefs.fly_genotype;
                obj.fly_number = acquisitionPrefs.fly_number;
                obj.cell_number = acquisitionPrefs.cell_number;
            end
            
            % assign updated values of input parameters
            if isfield(p.Results,'fly_genotype') && isempty(p.Results.fly_genotype)
                p.Results.fly_genotype = input('Enter Fly Genotype:  ');                
            end
            obj.fly_genotype = p.Results.fly_genotype;
            if isfield(p.Results,'fly_number') && isempty(p.Results.fly_number)
                p.Results.fly_genotype = input('Enter Fly Number:  ');                
            end
            obj.fly_genotype = p.Results.fly_genotype;
            if isfield(p.Results,'cell_number') && isempty(p.Results.cell_number)
                p.Results.fly_genotype = input('Enter Cell Number:  ');                
            end
            obj.fly_genotype = p.Results.fly_genotype;
            
            % then set preferences to current values
            setpref('AcquisitionPrefs',...
                {'fly_genotype','fly_number','cell_number'},...
                {obj.fly_genotype,obj.fly_number,obj.cell_number});
            
            obj.D = ['C:\Users\Anthony Azevedo\Acquisition\',date,'\',...
                date,'_F',obj.fly_number,'_C',obj.cell_number];
            
            obj.dataFileName = dir([obj.D,'\WCwaveform_',...
                date,'_F',obj.fly_number,'_C',obj.cell_number,'.mat']);
            
            obj.rec_gain = readGain();
            obj.rec_mode = readMode();
            createAIAOSessions();
            obj.aiSession.Rate = p.Results.aiSamprate;
            obj.dataBoilerPlate = createDataMatBoilerPlate(obj);
            obj.data = obj.loadData();

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
            addRequired(p,'obj');
            addRequired(p,'famN');
            addOptional(p,'vm_id',0);
            parse(p,varargin{:});

            % stim_mat = generateStimFamily(obj);
            trialdata = obj.dataBoilerPlate;
            trialdata.Vm_id = p.Results.vm_id;

            obj.rec_gain = readGain();
            obj.rec_mode = readMode();
            trialdata.rec_gain = obj.rec_gain;
            trialdata.rec_mode = obj.rec_mode;
            
            obj.aiSession.Rate = trialdata.trial;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;
            
            obj.x = ((1:obj.aiSession.Rate*obj.aiSession.DurationInSeconds) - 1)/obj.aiSession.Rate;
            
            for fam = 1:famN
                addTrialParametersDataStruct();
                addStimToAOSession();
                
                trialdata.trial = obj.n;
                trialdata.durSweep = 2;
                    
                if strcmp(obj.rec_mode,'IClamp')
                    trialdata.currentscale = obj.rec_gain; %%???????
                    trialdata.voltagescale = obj.rec_gain; %10.3 when output gain is 100; % scaling factor for voltage (mV)
                elseif strcmp(obj.rec_mode,'VClamp')
                    trialdata.currentscale = obj.rec_gain*trialdata.headstagegain; %200                             % scaling factor for current (pA)
                    trialdata.voltagescale = 20; %10.3 when output gain is 100;   % scaling factor for voltage (mV)
                end
                trialdata.currentoffset= -0.0335;                                 % What is this?
                trialdata.voltageoffset = 0*trialdata.voltagescale;                 % offset for voltage
                
                
                y = obj.aiSession.startForeground; %plot(x); drawnow
                voltage = y;
                current = y;
                
                % apply scaling factors
                current = (current-trialdata.currentoffset)*trialdata.currentscale;
                voltage = voltage*trialdata.voltagescale-trialdata.voltageoffset;
                
                switch obj.rec_mode
                    case 'VClamp'
                        y = current;
                    case 'IClamp'
                        y = voltage;
                end
                
                saveData(trialdata,current,voltage)% save data(n)
                
                displayTrial(y)
            end
        end
        
        function saveData(obj,trialdata,current,voltage)
            % For speed test appending to data;
            obj.data(obj.n) = trialdata;

            save(obj.dataFileName,'obj.data');
            save([obj.D,'\Raw_WCwaveform_', ...
                date,'_F',obj.fly_number,'_C',obj.cell_number,'_', ...
                num2str(obj.n)],'current','voltage');
        end
        
        function displayTrial(obj,y)
            figure(1);
            plot(obj.x,y,'r','linewidth',1);
            box off; set(gca,'TickDir','out');
            switch obj.rec_mode
                case 'VClamp'
                    ylabel('I (pA)'); %xlim([0 max(t)]);
                case 'IClamp'
                    ylabel('V_m (mV)'); %xlim([0 max(t)]);
            end
        end

    end % methods
    
    methods (Access = protected)
                
        function createAIAOSessions(obj)
            % configureAIAO is to start an acquisition routine
            
            obj.aiSession = daq.createSession('ni');
            obj.aiSession.addAnalogInputChannel('Dev1',0, 'Voltage')
            
            % configure AO
            obj.aoSession = daq.createSession('ni');
            % aoSession.addAnalogOutputChannel('Dev1',0:2, 'Voltage')
            
            obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger')
            obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger')
        end
        
        function trialdata = createDataMatBoilerPlate(obj)
            trialdata.protocol = mfilename('class');
            trialdata.date = date;
            trialdata.flynumber = obj.fly_number;
            trialdata.flygenotype = obj.fly_genotype;
            trialdata.cellnumber = obj.cell_number;
            trialdata.sampratein = obj.aiSession.Rate;
            trialdata.recmode = obj.rec_mode;
            trialdata.recgain = obj.rec_gain;
            trialdata.headstagegain = 1;
            trialdata.samprateout = obj.aoSession.Rate;
        end
        
        function loadData(obj)
            % make a directory if one does not exist
            if ~isdir(obj.D)
                mkdir(obj.D);
            end
            
            % check whether a saved data file exists with today's date
            if isempty(dir(obj.D))
                % if no saved data exists then this is the first trial
                obj.data(1) = obj.dataBoilerPlate;
                obj.data = obj.data(1:end-1);
                obj.n = length(obj.data)+1;
            else
                %load current data file
                obj.data = load(obj.dataFileName,'data');
                obj.n = length(obj.data)+1;

            end
            fprintf('Fly %s, Cell %s currently has %d trials',obj.fly_number,obj.cell_number,length(obj.data));
            
        end
        
        function stim_mat = generateStimFamily(obj)
            for paramsToVary = obj.params
                stim_mat = generateStimulus;
            end
        end

        
    end % protected methods
    
    methods (Static)
    end
end % classdef