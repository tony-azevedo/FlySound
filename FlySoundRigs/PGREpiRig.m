classdef PGREpiRig < PGRCameraRig
    
    properties (Constant)
        rigName = 'PGREpiRig';
        IsContinuous = false;
    end
    
    methods
        function obj = PGREpiRig(varargin)
            lightstim = getacqpref('AcquisitionHardware','LightStimulus');
            switch lightstim
                case 'LED_Red'
                    obj.addDevice('epi','LED_Red');
                case 'Epifluorescence'
                    obj.addDevice('epi','Epifluorescence');
            end
        end
                
        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@Rig(obj,fig,evnt,varargin{:})
            if nargin>3
                protocol = varargin{1};            
                ax = subplot(3,1,[1 2],'Parent',obj.TrialDisplay,'tag','inputax');
                delete(findobj(ax,'tag','ampinput'));
                line(makeTime(protocol),makeTime(protocol),'parent',ax,'color',[1 0 0],'linewidth',1,'tag','ampinput','displayname','input');
                ylabel('Amp Input'); box off; set(gca,'TickDir','out');
                
                xlims = get(ax,'xlim');
                ylims = get(ax,'ylim');
                x_ = min(xlims)+ 0.025 * diff(xlims);
                y_ = max(ylims)- 0.025 * diff(ylims);
                st = obj.devices.camera.status;
                text(x_,y_,sprintf('Camera status: %s',st),'parent',ax,'horizontalAlignment','left','verticalAlignment','top','tag','CameraStatus','fontsize',7);
                
                ax = subplot(3,1,3,'Parent',obj.TrialDisplay,'tag','outputax');
                out = protocol.getStimulus;
                
                delete(findobj(ax,'tag','sgsmonitor'));               
                delete(findobj(ax,'tag','piezocommand'));
                line(makeOutTime(protocol),out.epicommand,'parent',ax,'color',[.7 .7 .7],'linewidth',1,'tag','epicommand','displayname','V');
                ylabel('Epi (V)'); box off; set(gca,'TickDir','out');
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
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','epicommand');
            set(l,'ydata',obj.outputs.datacolumns(:,strcmp(chnames.out,'epicommand')));

            l = findobj(findobj(obj.TrialDisplay,'tag','inputax'),'tag','ampinput');
            set(l,'ydata',invec);
            
            [st,str,missedFrames] = obj.devices.camera.status;
            xlims = get(findobj(obj.TrialDisplay,'tag','inputax'),'xlim');
            ylims = get(findobj(obj.TrialDisplay,'tag','inputax'),'ylim');
            x_ = min(xlims)+ 0.025 * diff(xlims);
            y_ = max(ylims)- 0.025 * diff(ylims);
            set(findobj(obj.TrialDisplay,'type','text','tag','CameraStatus'),'string',sprintf('PGR %s - %s',st,str),'position',[x_, y_, 0]);
            if missedFrames
                set(findobj(obj.TrialDisplay,'type','text','tag','CameraStatus'),'color',[1 0 0]);
            else
                set(findobj(obj.TrialDisplay,'type','text','tag','CameraStatus'),'color',[0 0 0]);
            end
            %l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','exposure');
            % set(l,'ydata',obj.inputs.data.exposure);
            
        end

    end
    
    methods (Access = protected)
    end
end
