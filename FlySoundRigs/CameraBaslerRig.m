classdef CameraBaslerRig < EPhysRig
    % current hierarchy: 7/14/16
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> TwoTrodeRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig 
    %                   -> PGRCameraRig -> PGREPhysRig
    %                                   -> PGRPiezoRig % This setup is for
    %                                   a digital output that requires same
    %                                   session, and same input and output
    %                                   sample rates
    %                   -> BasicEPhysRigSS
    
    properties (Constant,Abstract)
        rigName;
        IsContinuous;
    end
    
    methods
        function obj = CameraBaslerRig(varargin)
            obj.addDevice('camera',CameraBasler);
            addlistener(obj,'StartTrial',@obj.readyCamera);
            addlistener(obj,'DataSaved',@obj.resetCamera);
        end
        
        function in = run(obj,protocol,varargin)
            obj.devices.camera.setup(protocol);
            in = run@EPhysRig(obj,protocol,varargin{:});
        end
        
        function readyCamera(obj,fig,evnt,varargin)
            obj.devices.camera.start()
            
        end
        
        function resetCamera(obj,fig,evnt,varargin)
            obj.devices.camera.stop()
            
        end

        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@Rig(obj,fig,evnt,varargin{:})
            camfig = figure(1001); clf;
            set(camfig,'position',[1120 31 560 420],'name','PGR Camera','tag','PGRCamFig')
            camax = axes('parent',camfig,'units','normalized','position',[0 0 1 1],'tag','PGRCamAx');
            set(camax,'box','on','xtick',[],'ytick',[]);
            if nargin>3
                protocol = varargin{1};            
                ax = subplot(3,1,[1 2],'Parent',obj.TrialDisplay,'tag','inputax');
                delete(findobj(ax,'tag','ampinput'));
                line(makeTime(protocol),makeTime(protocol),'parent',ax,'color',[1 0 0],'linewidth',1,'tag','ampinput','displayname','input');
                ylabel('Amp Input'); box off; set(gca,'TickDir','out');
                
                ax = subplot(3,1,3,'Parent',obj.TrialDisplay,'tag','outputax');
                
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[0 0 1],'linewidth',1,'tag','exposure','displayname','V');
                ylabel('SGS (V)'); box off; set(gca,'TickDir','out');
                xlabel('Time (s)'); %xlim([0 max(t)]);
                linkaxes(get(obj.TrialDisplay,'children'),'x');
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
                        
            l = findobj(findobj(obj.TrialDisplay,'tag','inputax'),'tag','ampinput');
            set(l,'ydata',invec);
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','exposure');
            set(l,'ydata',obj.inputs.data.exposure);

        end

    end
    
    methods (Access = protected)
    end
end
