load(sprintf('analysisData_%s_%s.mat', cellName, acName));

for vi = 1:2
    e = analysisData.epochData{vi}; % using E/I alignment step here
    [response, t] = resample(e.response, e.t, 1000);
    response = smooth(response,10);

    % The goals:
    % filterOn = {}; % by vi
    filterOff = {};

    col_intensity = e.shapeDataColumns('intensity');
    col_startTime = e.shapeDataColumns('startTime');
    col_endTime = e.shapeDataColumns('endTime');
    col_flickerFrequency = e.shapeDataColumns('flickerFrequency');

    intensities = e.shapeDataMatrix(:,col_intensity);
    startTime = e.shapeDataMatrix(:,col_startTime);
    endTime = e.shapeDataMatrix(:,col_endTime);
    flickerFreq = e.shapeDataMatrix(:,col_flickerFrequency);


    %% ON Segments (from just before this ON to the next OFF)
    figure(120+vi-1)
    clf;
    ha = tight_subplot(e.totalNumSpots, 2);
    for si = 1:e.totalNumSpots

        thisStart = find(t > startTime(si) - 0.2, 1);
        thisEnd = find(t > (endTime(si) + e.timeOffset), 1);

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

        tDisplay = thisT - startTime(si);
        axes(ha(si * 2 - 1))
        plot(tDisplay, thisResp ./ max(abs(thisResp)))
        hold on
        plot(tDisplay, light)
        hold off


        responseDiff = diff(thisResp);

        fLight = fft(light);
        fResp = fft(thisResp);


        axes(ha(si * 2))
        plot(responseDiff)

        if si == 2
            tFilterOn = tDisplay(1:end-1);
            filterOn{vi} = responseDiff(tFilterOn > 0);
        end

    end
    % filterOn(end) = 0;

    % Now, apply the filters
    figure(125+vi-1);clf;
    subplot(2,1,1)
    plot(filterOn{vi})

    % make the light onset signal

    lightOn = zeros(size(t));
    for si = 1:e.totalNumSpots

        start = find(t - .18 > startTime(si), 1);
        lightOn(start) = intensities(si);

    end

    lightOn = cumsum(lightOn);

    subplot(2,1,2)
    plot(lightOn)

    filterOn{vi}(end) = -1*sum(filterOn{vi}(1:end-1));

    plot(conv(lightOn, filterOn{vi}, 'valid'))
    hold on
    plot(e.response)
end




