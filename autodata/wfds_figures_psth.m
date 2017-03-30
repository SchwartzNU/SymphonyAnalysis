%% Plot light step response PSTH for optimal SMS size
global CELL_DATA_FOLDER


% selects = {selectFminiOff, selectWfdsOff};
selects = {selectWfdsOn};


figure(166);clf;


%% Create GUI




%% Add plots
for ci = 1:20%size(dtab,1)
    if selects{1}(ci)
        col = colo;
    else
%     elseif selects{2}(ci)
%         col = colo2;
%     else
        continue
    end
    
    bestSize = dtab{ci, 'SMS_offSpikes_prefSize'};
    if isnan(bestSize)
        continue
    end
    
    dataSet = dtab{ci, 'SMS_sp_dataset'}{1};
    
    load([CELL_DATA_FOLDER cellNames{ci}])
    epochIds = cellData.savedDataSets(dataSet);
    matchingEpochs = [];
    for ei = 1:length(epochIds)
        epoch = cellData.epochs(epochIds(ei));
        if abs(epoch.get('curSpotSize') - bestSize) < 1
            matchingEpochs(end+1) = ei;
        end
    end
    
    if isempty(matchingEpochs)
        disp(['umm ' cellNames{ci}])
        ci
        continue
    end
    
    response = [];

%     [dataMean, xvals, dataStd, units] = cellData.getMeanData(matchingEpochs, streamName);
    [spCount, xvals] = cellData.getPSTH(matchingEpochs, 25); % bin length in ms
    plot(xvals, spCount, 'Color', col, 'ButtonDownFcn', {@cellPlotCallback, ci, dtab})
    hold on
end

function cellPlotCallback(src, ~, ci, dtab)
    if src.LineWidth > 1
        src.LineWidth = 1;
    else
        src.LineWidth = 3;
    end
    fprintf('%s: %s\n', dtab.cellType{ci}, dtab.Properties.RowNames{ci});
    
end
