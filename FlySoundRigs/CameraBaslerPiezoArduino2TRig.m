classdef CameraBaslerPiezoArduino2TRig < CameraBaslerTwoAmpRig
    % current hierarchy:
    
    properties (Constant)
        rigName = 'CameraBaslerPiezoArduino2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = CameraBaslerPiezoArduino2TRig(varargin)
            obj.addDevice('arduino','Arduino');
            obj.addDevice('triggeredpiezo','TriggeredPiezo');
            obj.devices.triggeredpiezo.setuplistener(obj);
            addlistener(obj.devices.arduino,'ControlFlag',@obj.setArduinoControl);
            addlistener(obj.devices.arduino,'Abort',@obj.turnOffEpi);
            addlistener(obj,'EndRun',@obj.turnOffEpi);
        end
        
        function in = run(obj,protocol,varargin)
            %obj.devices.triggeredpiezo.start();
            in = run@CameraBaslerTwoAmpRig(obj,protocol,varargin{:});
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@TwoAmpRig(obj,fig,evnt,varargin{:})
            if nargin>3
                protocol = varargin{1};
                out = protocol.getStimulus;
                
                ax = findobj(obj.TrialDisplay,'tag','outputax');
                delete(findobj(ax,'tag','sgsmonitor'));
                delete(findobj(ax,'tag','piezocommand'));
                line(makeOutTime(protocol),out.ttl,'parent',ax,'color',[.7 .7 .7],'linewidth',1,'tag','arduinottl','displayname','piezocommand');
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[0 0 1],'linewidth',1,'tag','sgsmonitor','displayname','sgsmonitor');
                ylabel(ax,'SGS (V)'); box off; set(gca,'TickDir','out');
                xlabel(ax,'Time (s)'); %xlim([0 max(t)]);
                linkaxes(get(obj.TrialDisplay,'children'),'x');
            end
        end
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end
            displayTrial@TwoAmpRig(obj,protocol)
                        
            delete(findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampinput_alt2'));
            delete(findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampinput_alt1'));
            delete(findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampoutput2'));
            delete(findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','ampoutput1'));
            
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','arduinottl');
            set(l,'ydata',obj.inputs.data.arduino_output);
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','sgsmonitor');
            set(l,'ydata',obj.inputs.data.sgsmonitor);
            
        end
        
    end
    
    methods (Access = protected)
    end
end
