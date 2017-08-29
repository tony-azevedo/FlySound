classdef CameraEpi2TRig < CameraTwoAmpRig
    
    properties (Constant)
        rigName = 'CameraEpi2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = CameraEpi2TRig(varargin)
            lightstim = getpref('AcquisitionHardware','LightStimulus');
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
            t = makeInTime(protocol);
            fps = 1/mean(diff(t(~obj.inputs.data.exposure)));
            N = sum(~obj.inputs.data.exposure);
            set(findobj(obj.TrialDisplay,'type','text','tag','CameraStatus'),'string',sprintf('Frames: %d at %.1f fps',N,fps),'position',[x_, y_, 0]);

        end
    end
    
    methods (Access = protected)
    end
end
