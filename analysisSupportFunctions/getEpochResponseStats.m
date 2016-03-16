function outputStruct = getEpochResponseStats(outputStruct)
outlierThres = 4; %SDs

fnames = fieldnames(outputStruct);
for i=1:length(fnames)
    curField = fnames{i};
    if strcmp(outputStruct.(curField).type, 'byEpoch') || strcmp(outputStruct.(curField).type, 'bySplitParameter')
        N = sum(~isnan(outputStruct.(curField).value));
        outputStruct.(curField).N = N;
        outputStruct.(curField).mean = nanmean(outputStruct.(curField).value);
        outputStruct.(curField).median = nanmedian(outputStruct.(curField).value);
        outputStruct.(curField).SD = nanstd(outputStruct.(curField).value);
        outputStruct.(curField).SEM = nanstd(outputStruct.(curField).value)./sqrt(N);
        outputStruct.(curField).min = min(outputStruct.(curField).value);
        outputStruct.(curField).max = max(outputStruct.(curField).value);
        %        outputStruct.(curField).value_norm = outputStruct.(curField).value / outputStruct.(curField).max;
        %        outputStruct.(curField).SEM_norm = outputStruct.(curField).SEM / outputStruct.(curField).max;
        %        outputStruct.(curField).SD_norm = outputStruct.(curField).SD / outputStruct.(curField).max;
        
        %outlier warning
        meanVal = outputStruct.(curField).mean;
        SDval = outputStruct.(curField).SD;
        deviations = abs(outputStruct.(curField).value - meanVal);
        %if mean is nan, just set everyting else to NaN
        if isnan(meanVal)
            outputStruct.(curField).outliers = NaN;
            outputStruct.(curField).value_c = NaN;
            outputStruct.(curField).mean_c = NaN;
            outputStruct.(curField).median_c = NaN;
            outputStruct.(curField).SD_c = NaN;
            outputStruct.(curField).SEM_c = NaN;
            outputStruct.(curField).min_c = NaN;
            outputStruct.(curField).max_c = NaN;
        else
            outputStruct.(curField).outliers = find(deviations > outlierThres * SDval);
            if ~isempty(outputStruct.(curField).outliers)
                disp(['Outlier warning for ' curField ': ' num2str(length(outputStruct.(curField).outliers)) ' outliers from ' num2str(N) ' epochs']);
            end
            
            %recalculate without outliers
            newVals = outputStruct.(curField).value(setdiff(1:N, outputStruct.(curField).outliers));
            outputStruct.(curField).value_c = newVals;
            outputStruct.(curField).mean_c = nanmean(newVals);
            outputStruct.(curField).median_c = nanmedian(newVals);
            outputStruct.(curField).SD_c = nanstd(newVals);
            outputStruct.(curField).SEM_c = nanstd(newVals)./sqrt(N);
            outputStruct.(curField).min_c = min(newVals);
            outputStruct.(curField).max_c = max(newVals);
        end
    end
end
