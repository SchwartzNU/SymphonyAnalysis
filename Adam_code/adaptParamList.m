function [paramListAdapted, paramsExcluded] = adaptParamList(nodeData, keywords)
%Adam 12/30/14
%extracts fields from parameter structures created by LightStepAnalysisTEMP
%that was revised by Greg 12/29/14. 

[byEpochParamList, singleValParamList, ~] = getParameterListsByType(nodeData);

newList1 = cell(length(byEpochParamList),1);
newList2 = cell(length(singleValParamList),1);
newListMeta = cell(0,1);

for I = 1:length(byEpochParamList)
    paramName = char(byEpochParamList(I));
    singleParamStruct = nodeData.(paramName);
    if singleParamStruct.units == 's'
        newList1{I} = [paramName,'.median_c'];
    else
        newList1{I} =  [paramName,'.mean_c'];    
    end;
end;
for I = 1:length(singleValParamList)
    paramName = char(singleValParamList(I));
    newList2{I} = [paramName,'.value'];

end;

% meta parameters:
metaParamWords = {
    'Xwidth';
    'YinfOverYmax';
    'Xmax';
    'Xcutoff';
    'absMax';
    'absValueSpot300'
    'DSI';
    'OSI';
    'generalMean'};

%Look for meta-parameters in node
fnames = fieldnames(nodeData);
for i=1:length(fnames)
    curField = fnames{i};
    if ~isstruct(nodeData.(curField))
       for metaInd = 1:length(metaParamWords)
          if ~isempty(strfind(curField, char(metaParamWords(metaInd))))
            newListMeta = [newListMeta; curField];  
            break;
          end;
       end;
    end;
end;

paramListAdapted = [newList1; newList2; newListMeta];


paramsExcluded = cell(0,1);
if ~isempty(keywords)
    %Look for keywords in paramList
    newParamList = cell(0,1);
    for i=1:length(paramListAdapted)
        curParam = paramListAdapted{i};
        
        for keywordInd = 1:length(keywords)
            if ~isempty(strfind(curParam, char(keywords(keywordInd))))
                newParamList = [newParamList; curParam];
                break;
            end;
        end;
        
    end;
    paramsExcluded = setdiff(paramListAdapted, newParamList);
    paramListAdapted = newParamList;
end;




end
