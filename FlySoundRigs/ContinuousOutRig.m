classdef ContinuousOutRig < ContinuousRig & EPhysRig
    
    properties (Constant)
        rigName = 'ContinuousOutRig';
    end
    
    properties (Hidden, SetAccess = protected)
        prevValue
        listener
    end
    
    properties (SetAccess = protected)
    end
    
    events
    end
    
    methods
        function obj = ContinuousOutRig(varargin)
            ...
        end
    
        
        function run(obj,protocol,varargin)
            if obj.aoSession.IsRunning
                return
            end
            obj.devices.amplifier.getmode;
            obj.devices.amplifier.getgain;
            %obj.setOutputs;

            obj.aoSession.Rate = protocol.params.samprateout;
            obj.aoSession.wait;

            obj.setAOSession(protocol);
            obj.listener = obj.aoSession.addlistener('DataRequired',...
                @(src,event) src.queueOutputData(obj.outputs.datacolumns));
            % obj.listener = obj.aoSession.addlistener('ErrorOccurred',...
            %     @(src,event) error('What the fuck?!'));

            obj.aoSession.IsContinuous = true;

            obj.aoSession.startBackground;    
        end
        
        function setAOSession(obj,protocol)
            % figure out what the stim vector should be
            obj.transformOutputs(protocol.next());
            obj.aoSession.queueOutputData(obj.outputs.datacolumns);
        end

        
        function stop(obj)
            obj.aoSession.stop;
            obj.aoSession.IsContinuous = false;

            stim = zeros(size(obj.aoSession.Channels));
            obj.aoSession.queueOutputData(stim);
            obj.aoSession.startBackground;
            obj.aoSession.wait;
            obj.aoSession.IsContinuous = true;
        end
        
        function delete(obj)
            obj.stop;
            delete@Rig(obj)
        end
    end
    
    methods (Access = protected)
    end
end
