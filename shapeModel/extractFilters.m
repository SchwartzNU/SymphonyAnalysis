load(sprintf('analysisData_%s_%s.mat', cellName, acName));
filters = cell(2);

filterDelays = [0.00,0.0]; % .05 for 033116Ac2

lightResponses = {};

for vi = 1:2
    e = analysisData.epochData{vi}; % using E/I alignment step here
    [response, t] = resample(e.response, e.t, 1000);
    response = smooth(response, 10);

    col_intensity = e.shapeDataColumns('intensity');
    col_startTime = e.shapeDataColumns('startTime');
    col_endTime = e.shapeDataColumns('endTime');
    col_flickerFrequency = e.shapeDataColumns('flickerFrequency');

    intensities = e.shapeDataMatrix(:,col_intensity);
    startTime = e.shapeDataMatrix(:,col_startTime);
    endTime = e.shapeDataMatrix(:,col_endTime);
    flickerFreq = e.shapeDataMatrix(:,col_flickerFrequency);

    for oi = 1:2
        oi
        %% ON Segments (from just before this ON to the next OFF)
        figure(120+vi-1)
        clf;
        numSpots = e.totalNumSpots;
        ha = tight_subplot(numSpots, 2);
        for si = 1:numSpots

            if oi == 1
                thisStart = find(t > startTime(si), 1);
                thisEnd = find(t > (endTime(si) + e.timeOffset), 1);
            else
                thisStart = find(t > endTime(si), 1);
                if si+1 > length(startTime)
                    thisEnd = length(t);
                else
                    thisEnd = find(t > (startTime(si+1) + e.timeOffset), 1);
                end
            end
            
            tRegion = thisStart:thisEnd;
            thisResp = response(tRegion);

            thisT = t(tRegion);
            light = zeros(size(thisT));
            light(thisT > startTime(si)) = intensities(si);

        %     if si < length(startTime)
        %         nextStart = find(e.t > startTime(si + 1), 1);
        %     else
        %         nextStart = length(e.t);
        %     end

            lightResponses{vi,oi} = thisResp;
            thisRespExpanded = thisResp;
    %         plot(thisT, thisResp)
            fitT = (0:300)/1000; 
    %         fitT = thisT(end-99:end)';
    %         efit = fit(fitT', thisResp(end-99:end), 'exp1');
    %         expansion = 
    %         thisRespExpanded = vertcat(thisRespExpanded, linspace(mean(thisRespExpanded(end-20:end)), 0, 1000)');
            startValue = mean(thisRespExpanded(end-10:end));
            thisRespExpanded = vertcat(thisResp, startValue * exp(-fitT / .2)');

            tDisplay = thisT - startTime(si);
            axes(ha(si * 2 - 1))
            plot(thisRespExpanded ./ max(abs(thisRespExpanded)))
            hold on
            plot(light)
            hold off


            responseDiff = diff(thisRespExpanded);
            %
            %         fLight = fft(light);
            %         fResp = fft(thisResp);


            axes(ha(si * 2))
            plot(responseDiff)

            if si == 2 % CHOOSE LIGHT FLASH
                tFilterOn = tDisplay(1:end-1);
                filters{vi,oi} = vertcat(zeros(filterDelays(vi) * 1000,1), responseDiff);


                temporalFilter.(sprintf('TFilter_%d',vi)) = tDisplay;
                temporalFilter.(sprintf('LightSignal_%d',vi)) = light;
                temporalFilter.(sprintf('LightResponse_%d',vi)) = thisRespExpanded;
                temporalFilter.(sprintf('Filter_%d',vi)) = responseDiff;
                plot(thisRespExpanded)
            end

        end
        % filterOn(end) = 0;

        % Now, apply the filters
        figure(130+vi-1);clf;
        subplot(2,1,1)
        plot(filters{vi,oi})
        title('selected filter')

        % make the light onset signal
        
        lightOn = zeros(size(t));
        for si = 1:e.totalNumSpots
            if oi == 1

                start = find(t > startTime(si), 1);
                lightOn(start) = intensities(si);
            else
                start = find(t > endTime(si), 1);
                lightOn(start) = intensities(si);
            end
        end

        lightOn = cumsum(lightOn);

        subplot(2,1,2)
        lightSignal = (e.signalLightOn > 0)*1;
        plot(lightSignal*200)
        hold on

    %     filterOn{vi}(end) = -1*sum(filterOn{vi}(1:end-1));

        plot(conv(lightOn, filters{vi,oi}))
        title('filtered epoch for check')

        plot(e.response)
        hold off
        
        pause
    end
end

% Export temporal filter from cell & resample
c_filtersResampled = cell(2);
for vi = 1:e_numVoltages
    for oi = 1:2
        c_filtersResampled{vi,oi} = normg(resample(filters{vi,oi}, round(1/sim_timeStep), 1000));
        c_filtersResampled{vi,oi}(end) = -1*sum(c_filtersResampled{vi,oi}(1:end-1));
    end
end

