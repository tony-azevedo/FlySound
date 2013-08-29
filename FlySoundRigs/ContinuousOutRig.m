classdef ContinuousOutRig < EPhysRig
    
    properties (Constant)
        rigName = 'ContinuousOutRig';
    end
    
    properties (Hidden, SetAccess = protected)
        prevValue
    end
    
    properties (SetAccess = protected)
    end
    
    events
    end
    
    methods
        function obj = ContinuousOutRig(varargin)
        end
    
        
        function run(obj,protocol,varargin)
            addlistener(obj.aoSession,'DataRequired',@(protocol) obj.setAOSession);
            
            obj.aiSession.Rate = protocol.params.sampratein;
            obj.aiSession.DurationInSeconds = protocol.params.durSweep;
            obj.aoSession.Rate = protocol.params.samprateout;
            obj.aoSession.wait;

            obj.setAOSession(protocol);
            obj.aoSession.startBackground; % Start the session that receives start trigger first    
        end
        
        function setAOSession(obj,protocol)
            % figure out what the stim vector should be
            obj.transformOutputs(protocol.next());
            obj.aoSession.queueOutputData(obj.outputs.datacolumns);
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
    end
end
