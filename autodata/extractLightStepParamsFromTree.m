function output = extractLightStepParamsFromTree(analysisTree, justGetCellNames)

    nodes = analysisTree.Node;

    %% Extraction code

    global CELL_DATA_FOLDER;

    output = {};

    for ni = 1:length(nodes)

        node = nodes{ni};
        if isfield(node, 'cellName')
            cellName = node.cellName;
            li = analysisTree.getchildren(ni);
            if isempty(li)
                continue
            end
            eids = nodes{li}.epochID;
            load(fullfile(CELL_DATA_FOLDER, [cellName, '.mat']))
            data = [];
            stimTime = nan;
            for eid = eids
                epoc = cellData.epochs(eid);
                if isnan(stimTime) || stimTime == epoc.get('stimTime')
                    data(end+1,:) = epoc.getData('Amplifier_Ch1');
                    stimTime = epoc.get('stimTime');
                end
            end
            mn = mean(data, 1);
            output(end+1, :) = {cellName, mn, epoc.get('ampHoldSignal')};
        end
    end
    
    if justGetCellNames
        return
    end


    %% Fitting code
    sim_timeStep = 0.005;
    for ci = 1:size(output, 1)
        stepResponse = output{ci,2};
        voltage = output{ci,3};

        preTimeSec = cellData.epochs(eid).get('preTime') / 1000;
        stepResponse = stepResponse - mean(stepResponse(1:(preTimeSec * 10000)));
        stepResponse = stepResponse(1:10000 * 1.5);
        stepResponse = stepResponse ./ prctile(abs(stepResponse), 99.5);
        stepResponse = stepResponse ./ sign(voltage);
        stepResponse = stepResponse(preTimeSec * 10000 : end);
        r = resample(stepResponse, round(1/sim_timeStep), 10000);
        r = reshape(r,length(r),1);

        % delay, rise dur, hold dur, decay time constant, baseline to peak ratio
        x0 = [.05, .1, .02, .2, 0];
        w = 15.^(linspace(1,0,length(r)))';
        fToMin = @(p) mean(w .* power(abs(makeParametricResponse(p, sim_timeStep, length(r)) - r), 2));

    %     plot(makeParametricResponse(x0, sim_timeStep, length(r)))


    %     fitData = {};
    %     for fi = 1:20
    %         p = rand(1,5)/10 + x0;

        p = x0;
        for li = 1:10
            [p, ~] = fminsearch(fToMin, p);
        end
    %         fitData(fi,:) = {f, p};
    %     end
    %     
    %     [~, bestFit] = max(cell2mat(fitData(:,1)));
    %     p = fitData{bestFit,2};


        fit = makeParametricResponse(p, sim_timeStep, length(r));
        mn = mean(r) * ones(size(fit));

        % check the fit quality
        r2 = 1 - sum((r - fit).^2)/sum((r - mn).^2);
        if r2 < 0.7
            p = nan*zeros(1,6);
        else
            p = [sign(voltage), p];
        end

        output{ci, 3} = p;

%         figure(10);clf;
%         hold on
%         plot(r) 
%         plot(fit)
%         hold off
%         legend('signal','initial','final')
%         title(sprintf('%g',r2*100))
%         drawnow
%         pause
    end
end

function d = makeParametricResponse(p, sim_timeStep, len)

    delay = zeros(1, round(p(1) / sim_timeStep));
    rise = linspace(0, 1, round(p(2) / sim_timeStep));
    holds = ones(1, round(p(3) / sim_timeStep));
    decay = (1-p(5))*exp(-1 * (sim_timeStep:sim_timeStep:10) / p(4)) + p(5);
    
    sig = horzcat(delay, rise, holds, decay);
%     d = diff(sig);
    d = sig(1:len)';
    
end