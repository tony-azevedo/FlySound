classdef PiezoRig < EPhysRig
    
    properties (Constant)
        rigName = 'PiezoRig';
        IsContinuous = false;
    end
    
    
    methods
        function obj = PiezoRig(varargin)
            obj.addDevice('piezo','Piezo');
            obj.addDevice('speaker','Speaker');
            obj.aiSession.addTriggerConnection('Dev1/PFI0','External','StartTrigger');
            obj.aoSession.addTriggerConnection('External','Dev1/PFI2','StartTrigger');
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@Rig(obj,fig,evnt,varargin{:})
            if nargin>3
                protocol = varargin{1};            
                ax = subplot(3,1,[1 2],'Parent',obj.TrialDisplay,'tag','inputax');
                delete(findobj(ax,'tag','ampinput'));
                line(makeTime(protocol),makeTime(protocol),'parent',ax,'color',[1 0 0],'linewidth',1,'tag','ampinput','displayname','input');
                ylabel('Amp Input'); box off; set(gca,'TickDir','out');
                
                ax = subplot(3,1,3,'Parent',obj.TrialDisplay,'tag','outputax');
                out = protocol.getStimulus;
                
                delete(findobj(ax,'tag','sgsmonitor'));               
                delete(findobj(ax,'tag','piezocommand'));
                line(makeOutTime(protocol),out.piezocommand,'parent',ax,'color',[.7 .7 .7],'linewidth',1,'tag','piezocommand','displayname','V');
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[0 0 1],'linewidth',1,'tag','sgsmonitor','displayname','V');
                ylabel('SGS (V)'); box off; set(gca,'TickDir','out');
                xlabel('Time (s)'); %xlim([0 max(t)]);
            end
        end
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end

            if strcmp(obj.devices.amplifier.mode,'VClamp')
                invec = obj.inputs.data.current;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'current'));
                inunits = obj.devices.amplifier.inputUnits{ind(1)};
                ylabel(findobj(obj.TrialDisplay,'tag','inputax'),inunits);
            elseif sum(strcmp({'IClamp','IClamp_fast'},obj.devices.amplifier.mode))
                invec = obj.inputs.data.voltage;
                ind = find(strcmp(obj.devices.amplifier.inputLabels,'voltage'));
                inunits = obj.devices.amplifier.inputUnits{ind(1)};
                ylabel(findobj(obj.TrialDisplay,'tag','inputax'),inunits);
            end
            
            chnames = obj.getChannelNames;
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','piezocommand');
            set(l,'ydata',obj.outputs.datacolumns(:,strcmp(chnames.out,'piezocommand')));

            l = findobj(findobj(obj.TrialDisplay,'tag','inputax'),'tag','ampinput');
            set(l,'ydata',invec);
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','sgsmonitor');
            set(l,'ydata',obj.inputs.data.sgsmonitor);

        end

    end
    
    methods (Access = protected)
    end
end
