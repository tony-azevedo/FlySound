classdef SealTest < FlySoundProtocol
    
    properties (Constant)
        protocolName = 'SealTest';
        rigRequired = 'ContinuousOutRig';
        %            obj.listener = obj.aoSession.addlistener('DataRequired',@(src,event) src.queueOutputData(obj.generateStimulus));

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
        
        function obj = SealTest(varargin)
            % In case more construction is needed
            obj = obj@FlySoundProtocol(varargin{:});
        end

        function varargout = getStimulus(obj,varargin)
            varargout = {obj.out,obj.x};
        end
                
        function stop(obj)
            obj.aoSession.stop;
            obj.aoSession.IsContinuous = false;

            stim = zeros(obj.aoSession.Rate*0.001,1);
            obj.aoSession.queueOutputData(stim(:));
            obj.aoSession.startBackground;
            obj.aoSession.wait;
            obj.aoSession.IsContinuous = true;
       end
          
    end
    methods (Access = protected)
                                                       
        function defineParameters(obj)
            obj.params.sampratein = 100000;
            obj.params.samprateout = 100000;
            obj.params.stepamp = 5; %mV;
            obj.params.stepdur = .02; %sec;
            obj.params.pulses = 20;
            %             obj.params.stimDurInSec = 2;
            %             obj.params.preDurInSec = .5;
            %             obj.params.postDurInSec = .5;
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses);
            
            obj.params.Vm_id = 0;
            obj.params = obj.getDefaults;
        end
        
        function setupStimulus(obj,varargin)
            obj.params.durSweep = obj.params.stepdur*(2*obj.params.pulses);
            obj.x = (1:obj.params.samprateout*obj.params.durSweep)/obj.params.samprateout;
            obj.x = obj.x(:);
            
            obj.y = zeros(2*obj.params.pulses,obj.params.stepdur*obj.params.samprateout);
            obj.y(2:2:2*obj.params.pulses,:) = 1;
            obj.y = obj.y(:);
            
            obj.y = obj.y * obj.params.stepamp;            
        end
                        
    end % protected methods
    
    methods (Static)
    end
end % classdef