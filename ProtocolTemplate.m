classdef ProtocolTemplate < FlySoundProtocol
    
    properties (Constant)
        protocol = 'FlySoundProtocol';
    end
    
    properties (Hidden)
    end
    
    % The following properties can be set only by class methods
    properties (SetAccess = private)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        
        function obj = ProtocolTemplate(varargin)
            % In case more construction is needed
            % obj = obj@FlySoundProtocol(varargin);
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
            
            trialdata.durSweep = 2;
            obj.aiSession.Rate = trialdata.sampratein;
            obj.aiSession.DurationInSeconds = trialdata.durSweep;
            
            obj.x = ((1:obj.aiSession.Rate*obj.aiSession.DurationInSeconds) - 1)/obj.aiSession.Rate;
            obj.x_units = 's';
            
            for fam = 1:famN

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

    end % methods
    
    methods (Access = protected)
                        
        function createSubDataStructBoilerPlate(obj)
            % TODO, make this a map.Container array, so you can add
            % whatever keys you want.  Or cell array of maps?  Or a java
            % hashmap?
            sdbp;
            obj.subDataBoilerPlate = dbp;
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