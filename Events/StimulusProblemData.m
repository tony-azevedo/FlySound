classdef StimulusProblemData < event.EventData
    properties (Constant)
        Possibles = {'CalibratingStimulus',...
            'UncorrectedStimulus',...
            'UncalibratedStimulus',...
            'StimulusOutsideBounds',...
            'IssueNotSpecified'}
    end
    
    properties
        Issue;
        Index
    end
    methods
        function obj = StimulusProblemData(issue)
            obj.Issue = issue;
            obj.Index = strcmp(obj.Possibilities,issue);
            if isempty(obj.Index)
                obj.Index = length(obj.Possibilities);
                obj.Issue = obj.Possibilities{obj.Index};
            end                
        end
    end
end
