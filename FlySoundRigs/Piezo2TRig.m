classdef Piezo2TRig < TwoAmpRig
    % current hierarchy:
    %   Rig -> EPhysRig -> BasicEPhysRig
    %                   -> TwoTrodeRig
    %                   -> PiezoRig 
    %                   -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                   -> TwoPhotonPiezoRig     
    %                   -> CameraRig    -> CameraEPhysRig 
    %                                   -> PiezoCameraRig 
    
    properties (Constant)
        rigName = 'Piezo2TRig';
        IsContinuous = false;
    end
    
    methods
        function obj = Piezo2TRig(varargin)
            obj.addDevice('piezo','Piezo');
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            setDisplay@TwoAmpRig(obj,fig,evnt,varargin{:})
            if nargin>3
                protocol = varargin{1};
                out = protocol.getStimulus;
                
                ax = findobj(obj.TrialDisplay,'tag','outputax');
                delete(findobj(ax,'tag','sgsmonitor'));               
                delete(findobj(ax,'tag','piezocommand'));                
                line(makeOutTime(protocol),out.piezocommand,'parent',ax,'color',[.7 .7 .7],'linewidth',1,'tag','piezocommand','displayname','piezocommand');
                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[0 0 1],'linewidth',1,'tag','sgsmonitor','displayname','sgsmonitor');
                ylabel(ax,'SGS (V)'); box off; set(gca,'TickDir','out');
                xlabel(ax,'Time (s)'); %xlim([0 max(t)]);
                linkaxes(get(obj.TrialDisplay,'children'),'x');
            end
        end
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end
            displayTrial@TwoAmpRig(obj,protocol)

            chnames = obj.getChannelNames;
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','piezocommand');
            set(l,'ydata',obj.outputs.datacolumns(:,strcmp(chnames.out,'piezocommand')));
            
            l = findobj(findobj(obj.TrialDisplay,'tag','outputax'),'tag','sgsmonitor');
            set(l,'ydata',obj.inputs.data.sgsmonitor);

        end

    end
    
    methods (Access = protected)
    end
end
