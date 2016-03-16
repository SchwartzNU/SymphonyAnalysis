function [analysisTreeName, paramList, twoD] = conditionParser(conditionString)
%Adam 1/14/15
%For now it will only get the parameter(s)
%Assume that I have analysisTrees named treeLS, treeMB etc.


analysisClassWords = {
    'SMS';
    'FB';
    'MB';
    'MB8000';
    'MB250';
    };

paramWords = {
    '.mean';
    '.mean_c';
    '.median';
    '.median_c';
    '.value';
    };

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
    
paramWords = [paramWords; metaParamWords];

for wordInd = 1:length(analysisClassWords)
    if ~isempty(strfind(conditionString, analysisClassWords{wordInd}))
        analysisTreeName = ['tree',analysisClassWords{wordInd}];
        break;
    end;
    %word not found - default is LS
    analysisTreeName = 'treeLS';
end;
    
paramList = cell(0);
condSplit = strsplit(conditionString);
for paramWordInd = 1:length(paramWords)
    paramWord = paramWords{paramWordInd};
    for conditionWordInd = 1:length(condSplit)
        conditionWord = condSplit{conditionWordInd};
        if ~isempty(strfind(conditionWord, paramWord))
            paramList = [paramList; conditionWord];
            break;
        end;
    end;
end;
paramList = unique(paramList);

twoD =  ~isempty(strfind(conditionString, '&&'));
    

end
        
        
       