classdef ImagingBasicRig < ImagingRig
    % current hierarchy:
    %   Rig -> EPhysRig         -> BasicEPhysRig
    %                           -> TwoTrodeRig
    %                           -> PiezoRig 
    %                           -> TwoPhotonRig -> TwoPhotonEPhysRig 
    %                                           -> TwoPhotonPiezoRig     
    %                           -> CameraRig    -> CameraEPhysRig 
    %                                           -> PiezoCameraRig 
    %       -> ImagingRig   -> ImagingPiezoRig
    %                       -> ImagingBasicRig
    %
    properties (Constant)
        rigName = 'ImagingBasicRig';
        IsContinuous = false;
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
    end
    
    events
        %InsufficientFunds, notify(BA,'InsufficientFunds')
    end
    
    methods
        function obj = ImagingBasicRig(varargin)
            obj = obj@ImagingRig(varargin{:});
        end
        
        function setDisplay(obj,fig,evnt,varargin)
            if nargin<4
                varargin = {[]};
            end
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

                line(makeInTime(protocol),makeInTime(protocol),'parent',ax,'color',[0 0 0],'linewidth',1,'tag','exposure','displayname','io');
                
                xlabel('Time (s)'); %xlim([0 max(t)]);
                linkaxes(get(obj.TrialDisplay,'children'),'x');
            end
        end
        
        function displayTrial(obj,protocol)
            if ~ishghandle(obj.TrialDisplay), obj.setDisplay(protocol), end

            % There is no input here, no Piezo or recording, so don't plot
            % anything.
            
        end
    end
    methods (Access = protected)
    end
end

