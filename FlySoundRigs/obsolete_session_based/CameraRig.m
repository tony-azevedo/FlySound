classdef CameraRig < EPhysRig
    % current hierarchy:
    
    properties (Constant,Abstract)
        rigName;
        IsContinuous;
    end
    
    methods
        function obj = CameraRig(varargin)
            obj.addDevice('camera','Camera');
            obj.aiSession.addTriggerConnection('External','Dev1/PFI0','StartTrigger'); % start trigger from the camera
            obj.aiSession.ExternalTriggerTimeout = 60; % start trigger from the camera
            
%             rigDev = getacqpref('AcquisitionHardware','rigDev');
%             triggerChannelIn = getacqpref('AcquisitionHardware','triggerChannelIn');
%             triggerChannelOut = getacqpref('AcquisitionHardware','triggerChannelOut');
            
            addlistener(obj,'StartTrial',@obj.readyCamera);
            addlistener(obj,'EndTrial',@obj.stopCameraTriggering);
        end

        function in = run(obj,protocol,varargin)
            dur = protocol.params.durSweep;
            frametime = 1/obj.devices.camera.params.framerate;
            Nframes = floor((dur-.1)/frametime);
            str = sprintf('%s\n%s\n%s%s\n\n%s\n%s\n\n%s%.1f sec, %d frames. POSTDURINSEC>100 ms!',...
                'Ready the camera:',...
                ' - Set Directory',...
                ' - Set Prefix: ',...
                [protocol.protocolName '_Image'],...
                'Mode: 0, Trigger polarity high, raw 8',...
                'Video, streaming, m-jpeg, 85 quality',...
                ' - Acq for ',...
                protocol.params.durSweep,...
                Nframes);
            

            clipboard('copy',[protocol.protocolName '_Image']);
            h = msgbox(str,'CAMERA SETUP');
            pos = get(h,'position');
            set(h, 'position',[696 125 pos(3) pos(4)])
            uiwait(h);
            
            in = run@EPhysRig(obj,protocol,varargin{:});
        end
        
        function readyCamera(obj,fig,evnt,varargin)
            
            dur = evnt.protocol.params.durSweep;
            frametime = 1/obj.devices.camera.params.framerate;
            Nframes = floor((dur-.1)/frametime);

            str = sprintf('Rig ready for trigger:\n%.5f frames',Nframes);
            h = msgbox(str,'CAMERA','replace');
            pos = get(h,'position');
            set(h, 'position',[600 178 pos(3) pos(4)])
            
            %clipboard('copy',sprintf('%d',Nframes));

            uiwait(h);

        end
        
        function stopCameraTriggering(obj,fig,evnt,varargin)
            
            str = sprintf('Stop the triggering;\nThen wait for saving');
            h = msgbox(str,'CAMERA','replace');
            pos = get(h,'position');
            %set(h, 'position',[1280 700 pos(3) pos(4)])
            set(h, 'position',[600 178 pos(3) pos(4)])
            
            %clipboard('copy',sprintf('%d',Nframes));

            uiwait(h);

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
