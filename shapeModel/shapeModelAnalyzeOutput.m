nonLinearFit = {};

if plotOutputCurrents
    figure(102 + paramSetIndex);clf;
    set(gcf, 'Name',['Output Currents ' num2str(paramSetIndex)],'NumberTitle','off');
    dim1 = ceil(sqrt(stim_numOptions));
    dim2 = ceil(stim_numOptions / dim1);
    outputAxes = tight_subplot(dim1, dim2, .05, .04);
end

out_valsByOptions = [];

plot_timeLims = [0.0, sim_endTime];
timeOffsetSim = -.01;
timeOffsetSpikes = -.3;
ephysScale = .1;
simScale = [1, .5; 1, .5] * 1000; % scaling the sim relative to ephys
combineScaleCurrents = [1.9, 1.9; 1, 1]; % voltages; ooi
combineScaleSpikes = .1;
additiveOffset = 0; % add to overall output current
% displayScale = [5,2.2];
plotYLimsScale = 1;
fitAnalysisLimits = [.2, 1.5];

nonLinearCell = {[],[]};
nonLinearSim = {[],[]};

fitnessScoreByOptionCurrent = [];

outputSignalsByOption = {};

for optionIndex = 1:stim_numOptions
    outputSignals = [];
    outputLabels = {};
    
%     ang = stim_edgeAngle(optionIndex);
    % Output scale
    sim_responseSubunitsCombinedScaled = sim_responseSubunitsCombinedByOption{optionIndex};
    for vi = 1:e_numVoltages
        for oi = 1:2
            sim_responseSubunitsCombinedScaled(vi,oi,:) = simScale(vi, oi) * combineScaleCurrents(vi, oi) * sim_responseSubunitsCombinedScaled(vi,oi,:);
        end
    end
    
    % Combine Ex and In
%     for oi = 1:2
%         sim_responseCurrent_byPolarity[ = sum(sim_responseSubunitsCombinedScaled, 1);
%     end
    sim_responseCurrent = squeeze(sum(sum(sim_responseSubunitsCombinedScaled, 1), 2));
%     out_valsByOptions(optionIndex, 1) = -1*sum(sim_responseCurrent(sim_responseCurrent < 0)) / sim_dims(1);


    if plotOutputCurrents
        axes(outputAxes(plotGrid(optionIndex, 1, 1)));
    end

    Tsim = T+timeOffsetSim;
    sel = Tsim > plot_timeLims(1) & Tsim < plot_timeLims(2);
    Tsim = Tsim(sel);
%         plot(Tsim(sel), sim_responseSubunitsCombinedScaled(:,sel))
    
    labels = {'ex on','ex off'; 'in on','in off'};
    for vi = 1:2
        for oi = 1:2
            outputSignals(end+1,:) = sim_responseSubunitsCombinedScaled(vi,oi,sel);
            outputLabels{end+1} = sprintf('%s s',labels{vi,oi});
        end
    end

%         if ~isempty(nonLinearFit)
%             for vi = 1:e_numVoltages
%                 plot(Tsim(sel), polyval(nonLinearFit{vi}, sim_responseSubunitsCombinedScaled(:,sel)))        
%             end
%         end

    % combined sim
    outputSignals(end+1,:) = sim_responseCurrent(sel);
    outputLabels{end+1} = 'comb_s';

    % ephys responses (ex, in, spikes)
    displayEphysResponses = false;
    if displayEphysResponses
        Esel = T > plot_timeLims(1) & T < plot_timeLims(2);
        simShift = timeOffsetSim / sim_timeStep;
        cell_responses = [];

        for vi = 1:2 %3 %enables spikes
            mn = ephysScale * c_responses{vi, c_angles == ang}.mean;

            if vi <= 2
                scale = combineScaleCurrents(vi,oi);
            else
                scale = combineScaleSpikes;
            end
            mn = scale * resample(mn, round(1/sim_timeStep), 10000);
            cell_responses(vi,:) = mn;
            rcell = cell_responses(vi,Esel);
            if simShift >= 0
                outputSignals(end+1,:) = rcell(simShift:end);
            else
                outputSignals(end+1,:) = [zeros(1,-simShift), rcell(1:end+2*simShift+1)];
            end
            l = {'ex_e','in_e','spike_e'};
            outputLabels{end+1} = l{vi};
    % 
    %         if vi < 3
    %             plot(T(Esel), mn(Esel))
    %         else
    %             plot(T(Esel) + timeOffsetSpikes, mn(Esel));
    %         end


        end
    end
    
    
%     ephys combined values
    displayEphysCombinedValues = false;
    if displayEphysCombinedValues
        cell_responsesCombined = sum(cell_responses(1:2,:));
        rcell = cell_responsesCombined(Esel);
        if simShift >= 0
            outputSignals(end+1,:) = rcell(simShift:end); %#ok<*SAGROW>
        else
            outputSignals(end+1,:) = [zeros(1,-simShift), rcell(1:end+2*simShift+1)];
        end            
        outputLabels{end+1} = 'comb_e';
    end

% % %     extract values for comparison plot
%             out_valsByOptions(optionIndex, 2) = -1*sum(cell_responsesCombined(cell_responsesCombined < 0)) / sim_dims(1);        
%             out_valsByOptions(optionIndex, 3) = -1*sum(cell_responses(3,:)) / sim_dims(1);            
    
%     fitAnalysisWindow = Tsim > fitAnalysisLimits(1) & Tsim < fitAnalysisLimits(2);
%     for oi = 1:3
%         fitnessScoreByOptionCurrent(optionIndex,oi) = rsquare(outputSignals(3+oi,fitAnalysisWindow),outputSignals(oi,fitAnalysisWindow));
%     end

    outputSignalsByOption{optionIndex} = outputSignals;
    
    
    if plotCellResponses
        % then plot all the signals together
        plotSelect = logical([1,0,1,0,1,0,0,0,0]);
        plot(Tsim, outputSignals(plotSelect,:)');
        legend(outputLabels(plotSelect),'Location','Best');
        xlim(plot_timeLims);

%         title(sprintf('angle %d, fit: %d, %d, %d', ang, round(100*fitnessScoreByOptionCurrent(optionIndex,1)),...
%                         round(100*fitnessScoreByOptionCurrent(optionIndex,2)),...
%                         round(100*fitnessScoreByOptionCurrent(optionIndex,3))))
                    
        line(plot_timeLims, [0,0]);
        
        title(stim_directions(optionIndex))


        % investigate nonlinearities relative to the ephys data
%         for vi = 1:2
%             simShift = timeOffsetSim / sim_timeStep;
% 
%             rsim = sim_responseSubunitsCombinedScaled(vi,sel);
%             rcell = cell_responses(vi,Esel);
%             rcell = rcell(simShift:end);
%             nonLinearCell{vi} = horzcat(nonLinearCell{vi}, rcell);
%             nonLinearSim{vi} = horzcat(nonLinearSim{vi}, rsim);
%             
% %             axes(outputAxes(plotGrid(optionIndex, vi + 1, 3)));
% %             plot(rsim,rcell,'.')
% %             hold on
% %             plot(rcell)
% %             hold off
%         end
    end
    
    
    
    if saveOutputSignalsToHDF5
        outputStruct.angles = stim_edgeAngle;% stim_barDirections;
        outputStruct.t = Tsim;
        for i=1:length(outputLabels)
            outputStruct.(sprintf('a%d_%s', ang, outputLabels{i})) = outputSignals(i,:);
        end
    end
end

if plotOutputCurrents
    linkaxes(outputAxes)
end
% ylim(outputAxes(1), 1.4*[min(outputSignals(:)), max(outputSignals(:))])
% ylim(outputAxes(1), [-300, 300])

    

if plotOutputNonlinearity

    figure(114)
    set(gcf, 'Name','Nonlinearity view','NumberTitle','off');
    for vi = 1:2
        subplot(2,1,vi)
        plot(nonLinearSim{vi}, nonLinearCell{vi},'.')
        % ignore values near 0 for fitting
        sigValues = abs(nonLinearSim{vi}) > 0.03 & abs(nonLinearCell{vi}) > 0.03;
        nonLinearFit{vi} = polyfit(nonLinearSim{vi}(sigValues), nonLinearCell{vi}(sigValues), 2);
        hold on
        plot(nonLinearSim{vi}, polyval(nonLinearFit{vi}, nonLinearSim{vi}))
        hold off
        title(e_voltages(vi))
        grid on
        xlabel('Simulation')
        ylabel('Cell ephys')
    end
end

% linkaxes(outputAxes)
% ylim([-1,.6]*.001)

% display combined output over stim options
if plotResultsByOptions
    figure(150);
    
    if paramSetIndex == 1
        clf();
    end
    
    set(gcf, 'Name','Processed outputs over options','NumberTitle','off');

    % compare combined current to spikes to get an RGC output nonlinearity
%     out_valsByOptions = out_valsByOptions ./ max(out_valsByOptions(:));
%     nonlinOutput = polyfit(out_valsByOptions(:,1), out_valsByOptions(:,3),1);
%     out_valsByOptions(:,4) = polyval(nonlinOutput, out_valsByOptions(:,1));

    ordering = [5];%,8,9];
    dataSetToExport = 5; % this is the one for the overall output comparison
    % ordering = 1;
    for ti = ordering
        angles = deg2rad(stim_directions)';
        values = [];
        for oi = 1:stim_numOptions
            signals = outputSignalsByOption{oi};
            values(oi,1) = -sum(signals(ti, signals(ti,:) < 0)) * sim_timeStep;
        end
        values = values + additiveOffset;
        
%         outputStruct.(sprintf('byang_%s',outputLabels{ti})) = values;
        
        a = [angles; angles(1)];
        v = [values; values(1)];
        v = v / mean(v);
        polarplot(a, v)
        hold on
        
        dsi = abs(sum(exp(sqrt(-1) * angles) .* values) / sum(values));
        if dataSetToExport == ti
            dsiByParamSet(paramSetIndex,1) = dsi;
            valuesByParamSet(paramSetIndex,:) = values;
            
        end

        if paramValues(paramSetIndex, col_edgeFlip) == 1
%             values = values;
        else
            values = flipud(values);
        end
%         subplot(4,1,paramSetIndex);
%         dataName = sprintf('%s_%g_%s_%g', paramColumnNames{1}, paramValues(paramSetIndex, 1), paramColumnNames{2}, paramValues(paramSetIndex, 2));
%     	plot(stim_positions, values', 'DisplayName',dataName)
        hold on
        
        outputStruct.(dataName) = values';
        outputStruct.x = stim_positions;
    end
%     hold off
%     legs = {'sim currents','ephys currents','ephys spikes','sim curr nonlin'};
%     legend(outputLabels(ordering))
    legend();
    
    % plot(stim_spotDiams, out_valsByOptions)
    
end

% output spiking nonlinearity maybe
%
% figure(160)
% 
% plot(out_valsByOptions(:,1), out_valsByOptions(:,2),'o');
% % title('current dif to 
% 
% sse = sum((out_valsByOptions(:,4) - out_valsByOptions(:,3)).^2);
% %  of nonlin scaled current diff, to spike rate 
% fprintf('SSE %f\n', sse);

