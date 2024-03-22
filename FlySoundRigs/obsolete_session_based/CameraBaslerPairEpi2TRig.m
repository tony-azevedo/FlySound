classdef CameraBaslerPairEpi2TRig < CameraBaslerPairTwoAmpRig
    
    properties (Constant)
        rigName = 'CameraBaslerPairEpi2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = CameraBaslerPairEpi2TRig(varargin)
            lightstim = getacqpref('AcquisitionHardware','LightStimulus');
            switch lightstim
                case 'LED_Red'
                    obj.addDevice('epi','LED_Red');
                case 'LED_Blue'
                    obj.addDevice('epi','LED_Blue');
                case 'LED_Bath'
                    obj.addDevice('epi','LED_Bath');
            end
        end
               

        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@TwoAmpRig(obj,fig,evnt,varargin{:})
            protocol = varargin{1};
%             ax = findobj(obj.TrialDisplay,'tag','outputax');
%             line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[.5 1 .5],'linewidth',1,'tag','exposure','displayname','exposure');
            
            ax = findobj(obj.TrialDisplay,'tag','inputax2');
            xlims = get(ax,'xlim');
            ylims = get(ax,'ylim');
            x_ = min(xlims)+ 0.025 * diff(xlims);
            y_ = max(ylims)- 0.025 * diff(ylims);
            y2_ = max(ylims)- 0.15 * diff(ylims);
            
            text(x_,y_,sprintf('Camera status:'),'parent',ax,'horizontalAlignment','left','verticalAlignment','top','tag','CameraStatus','fontsize',7);
            text(x_,y2_,sprintf('Camera status:'),'parent',ax,'horizontalAlignment','left','verticalAlignment','top','tag','Camera2Status','fontsize',7);

        end
        
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end
            displayTrial@TwoAmpRig(obj,protocol)

%             expvec = obj.inputs.data.exposure;
% 
%             ylims = get(findobj(obj.TrialDisplay,'tag','outputax'),'ylim');
%             l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','exposure');
%             
%             set(l,'ydata',diff(ylims)*expvec+min(ylims));

            xlims = get(findobj(obj.TrialDisplay,'tag','inputax1'),'xlim');
            ylims = get(findobj(obj.TrialDisplay,'tag','inputax1'),'ylim');
            x_ = min(xlims)+ 0.025 * diff(xlims);
            y_ = max(ylims)- 0.025 * diff(ylims);
            y2_ = max(ylims)- 0.15 * diff(ylims);

            t = makeInTime(protocol);
            frames = obj.inputs.data.exposure(1:end-1)==0&obj.inputs.data.exposure(2:end)>0;
            fps = 1/median(diff(t(frames)));
            N = obj.devices.camera.videoInput.DiskLoggerFrameCount; %sum(obj.inputs.data.exposure);
            
            frames2 = obj.inputs.data.exposure2(1:end-1)==0&obj.inputs.data.exposure2(2:end)>0;
            fps2 = 1/median(diff(t(frames2)));
            N2 = obj.devices.cameratwin.videoInput.DiskLoggerFrameCount; %sum(obj.inputs.data.exposure);

            set(findobj(obj.TrialDisplay,'type','text','tag','CameraStatus'),'string',sprintf('Frames: %d at %.1f fps',N,fps),'position',[x_, y_, 0]);
            set(findobj(obj.TrialDisplay,'type','text','tag','Camera2Status'),'string',sprintf('Frames: %d at %.1f fps',N2,fps2),'position',[x_, y2_, 0]);
        end
    end
    
    methods (Access = protected)
    end
end
