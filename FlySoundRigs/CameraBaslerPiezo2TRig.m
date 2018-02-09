classdef CameraBaslerPiezo2TRig < CameraBaslerTwoAmpRig
    
    properties (Constant)
        rigName = 'CameraBaslerPiezo2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = CameraBaslerPiezo2TRig(varargin)
            obj.addDevice('piezo','Piezo');
        end
               

        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@TwoAmpRig(obj,fig,evnt,varargin{:})
            protocol = varargin{1};
            out = protocol.getStimulus;
            
            ax = findobj(obj.TrialDisplay,'tag','outputax');
            delete(findobj(ax,'tag','sgsmonitor'));
            delete(findobj(ax,'tag','piezocommand'));
            line(makeOutTime(protocol),out.piezocommand,'parent',ax,'color',[.7 .7 .7],'linewidth',1,'tag','piezocommand','displayname','piezocommand');
            line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[0 0 1],'linewidth',1,'tag','sgsmonitor','displayname','sgsmonitor');
            ylabel(ax,'SGS (V)'); box off; set(ax,'TickDir','out');
            xlabel(ax,'Time (s)'); %xlim([0 max(t)]);
            
            ax = findobj(obj.TrialDisplay,'tag','inputax1');
            xlims = get(ax,'xlim');
            ylims = get(ax,'ylim');
            x_ = min(xlims)+ 0.025 * diff(xlims);
            y_ = max(ylims)- 0.025 * diff(ylims);
            
            text(x_,y_,sprintf('Camera status:'),'parent',ax,'horizontalAlignment','left','verticalAlignment','top','tag','CameraStatus','fontsize',7);

        end
        
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end
            displayTrial@TwoAmpRig(obj,protocol)

            chnames = obj.getChannelNames;
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','piezocommand');
            set(l,'ydata',obj.outputs.datacolumns(:,strcmp(chnames.out,'piezocommand')));
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','sgsmonitor');
            set(l,'ydata',obj.inputs.data.sgsmonitor);

            xlims = get(findobj(obj.TrialDisplay,'tag','inputax1'),'xlim');
            ylims = get(findobj(obj.TrialDisplay,'tag','inputax1'),'ylim');
            x_ = min(xlims)+ 0.025 * diff(xlims);
            y_ = max(ylims)- 0.025 * diff(ylims);
            t = makeInTime(protocol);
            frames = obj.inputs.data.exposure(1:end-1)==0&obj.inputs.data.exposure(2:end)>0;
            fps = 1/median(diff(t(frames)));
            N = obj.devices.camera.videoInput.DiskLoggerFrameCount; %sum(obj.inputs.data.exposure);
            set(findobj(obj.TrialDisplay,'type','text','tag','CameraStatus'),'string',sprintf('Frames: %d at %.1f fps',N,fps),'position',[x_, y_, 0]);

        end
    end
    
    methods (Access = protected)
    end
end
