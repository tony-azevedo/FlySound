classdef LED_Arduino_Control < Device
    
    properties (Constant)
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties 
        deviceName = 'LED_Arduino_Control';
        socket
    end
    
    properties (SetAccess = protected)
    end
    
    events
        Abort
        Override
        ControlFlag
        RoutineFlag
        BlueFlag
        IRPWMFlag
    end
    
    methods
        function obj = LED_Arduino_Control(varargin)
            % This and the transformInputs function are hard coded
            
            obj.inputLabels = {};
            obj.inputUnits = {};
            obj.inputPorts = [];
            obj.digitalOutputLabels = {'epittl','abort','control','routine','bluettl','irlaserttl'};
            obj.digitalOutputUnits = {'Bit','Bit','Bit','Bit','Bit','Bit'};
            obj.digitalOutputPorts = [7,6,5,4,3,0];  % ,'Port2/Line0'];
            obj.digitalInputLabels = {'arduino_output'}; %,'trial_duration'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = [2];
            
            % obj.createSocket();
        end
        
        function createSocket(obj)
            JARPATH = 'C:\Users\tony\Code\FlySound\java\jeromq-0.5.2.jar';
            javaclasspath(JARPATH)
            if 1
                import org.zeromq.*
                import java.lang.*
            else
                % import org.zeromq.SocketType
                % import org.zeromq.ZMQ
                % import org.zeromq.ZContext
            end
            
            context = ZContext();
            obj.socket = context.createSocket(SocketType.PUB);
            % obj.socket.bind('tcp://*:5556');
        end
        
        function in = transformInputs(obj,in,varargin)
            %multiply Inputs by micron/volts
        end
        
        function out = transformOutputs(obj,out,varargin)
            %multiply outputs by volts/micron
            %out.epittl = 1-out.epittl; 
            out.epittl = out.epittl;
            out.control = 0.*out.epittl+obj.params.controlToggle;
            out.routine = 0.*out.epittl+obj.params.routineToggle;
            out.bluettl = 0.*out.epittl+obj.params.blueToggle;
            out.irlaserttl = 0.*out.epittl+obj.params.irlaserToggle;
        end
        
        function setParams(obj,varargin)
            fprintf('Still have to figure out how to send target\n')
            % oldtarget = obj.params.target;
            % duinoPWM = obj.params.duinoPWM;
            setParams@Device(obj,varargin{:})
            notify(obj,'ControlFlag')
            % The listener then sets all the flags, control, routine, blue
            %if any(oldtarget~=obj.params.target) || duinoPWM ~= obj.params.duinoPWM
                % send the 
            %end
        end
        
        function abort(obj,varargin)
            notify(obj,'Abort')
        end
        
        function override(obj,varargin)
            notify(obj,'Override')
        end

    end
    
    methods (Access = protected)
        function setupDevice(obj)
        end
                
        function defineParameters(obj)
            % rmacqpref('defaultsLED_Arduino_Control')
            obj.params.controlToggle = 0;
            obj.params.routineToggle = 0;
            obj.params.blueToggle = 0;
            obj.params.irlaserToggle = 0;
            obj.params.target = [340 80];
            obj.params.duinoPWM = 64;
        end
    end
end
