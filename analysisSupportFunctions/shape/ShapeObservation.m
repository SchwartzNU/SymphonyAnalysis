classdef ShapeObservation < handle
    
    properties
        sourceEpoch
        shapeDataMatrixIndex
        
        signalStartIndex
        signalEndIndex

        % parameters
        position
        intensity
        voltage
        spotSize
        flickerFrequency
        
        % results
        respMean
        respPeak
        tHalfMax
        distFromPrev
        
        adaptSpotX
        adaptSpotY
        adaptSpotEnabled

    end
    
    methods
        
        function obj = ShapeObservation()
        end
        
        function extractResults(obj, resp)
            obj.respMean = mean(resp);
            obj.respPeak = max(resp);
            if obj.respPeak > 0
                timeToPeak = find(resp > pk / 2.0, 1, 'first') / .sampleRate;
            else
                timeToPeak = nan;
            end
%             dist = sqrt(sum((spot_position - prevPosition).^2));
        
        end
        
    end
end
