classdef Camera < Device
    
    properties (Constant)
        
    end
    
    properties (Hidden, SetAccess = protected)
    end
    
    properties (SetAccess = protected)
        gaincorrection
    end
    
    properties
        deviceName = 'Camera';
    end

    events
        %
    end
    
    methods
        function obj = Camera(varargin)
            % This and the transformInputs function are hard coded
            
            obj.digitalInputLabels = {'exposure'};
            obj.digitalInputUnits = {'Bit'};
            obj.digitalInputPorts = [3];
            obj.digitalInputPorts = [28];
%             obj.digitalOutputLabels = {'trigger'};
%             obj.digitalOutputUnits = {'Bit'};
%             obj.digitalOutputPorts = [7];

        end
        
        function varargout = transformInputs(obj,inputstruct)
            
            inlabels = fieldnames(inputstruct);
            units = {};
            for il = 1:length(inlabels)
                if strcmp(inlabels{il},'exposure')
                    units = {'bit'};
                    % Try for now to record the whole thing, not just when
                    % it starts.
%                     inputstruct.exposure = inputstruct.exposure > 0.5;
%                     inputstruct.exposure = ...
%                         [inputstruct.exposure(2:end) - inputstruct.exposure(1:end-1); 0];
%                     inputstruct.exposure = inputstruct.exposure > 0;
                end
            end
            varargout = {inputstruct,units};

        end
        
        function out = transformOutputs(obj,out,varargin)
            % The following code creates a trigger. To get the camera to go
            % faster, it cannot take a trigger. So, now the recording and
            % file directory are set, then the recording is started, the
            % trial starts, waiting for a start trigger. The trigger check
            % box is unchecked in FlyCap, and the camera rolls, with the
            % exposure trigger starting the trial. Hence, there is no more
            % triggering.
            
%             rig = varargin{1};
%             if ~isfield(out,'trigger')
%                 fns = fieldnames(out);
%                 out.trigger = out.(fns{1});
%                 out.trigger(:) = 0;
%             else
%             end
%             dur = length(out.trigger)/rig.aoSession.Rate;
%             frametime = 1/obj.params.framerate;
%             Nframes = floor((dur-.25)/frametime);
%             idxs = round(((1:Nframes)-1)*(frametime*rig.aoSession.Rate) + 1);
%             
%             out.trigger(idxs) = 1;
%             %out.trigger(idxs+1) = 1;
%             out.trigger(end) = 0;
%             
%             obj.params.Nframes = sum(out.trigger);%/2;
%             fprintf('\tFramerate = %d fps;\tN frames = %d\n',obj.params.framerate,sum(out.trigger)/2);
% %             obj.videoInput.TriggerRepeat = obj.params.Nframes-1;
% %             % obj.videoInput.TriggerFcn = {obj.dispFunc};
        end
    
    end
    
    methods (Access = protected)
        function setupDevice(obj)        
        end

        function defineParameters(obj)
            % try rmpref('defaultsCamera'), catch, end
            obj.params.setup = 'x Frames, write in the rest of the information';
            obj.params.framerate = 150;
            obj.params.Nframes = 30;
        end
    end
end
