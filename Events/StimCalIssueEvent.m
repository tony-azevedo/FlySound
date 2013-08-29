classdef StimCalIssueEvent < event.EventData
    properties (Constant)
        Possibles = {CalibratingStimulus,...
            UncorrectedStimulus,...
            UncalibratedStimulus,...
            StimulusOutsideBounds,...
            }
    end
    
    properties
        Issue;
    end
    methods
        function obj = StimCalIssueEvent(temp,pressure)
            obj.Temperature = temp;
            obj.OilPressure = pressure;
        end
    end
end
