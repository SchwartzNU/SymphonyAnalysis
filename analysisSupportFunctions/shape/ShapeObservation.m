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
            pk = max(resp);
            if pk > 0
                del = find(resp > pk / 2.0, 1, 'first') / e.sampleRate;
            else
                del = nan;
            end
            dist = sqrt(sum((spot_position - prevPosition).^2));
        
        end
        
    end
end
