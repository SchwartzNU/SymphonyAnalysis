function chInd_out = childrenByValue(T, startNode, paramName, paramVal)
chInd_out = [];
chInd = T.getchildren(startNode);
for i=1:length(chInd)
    nodeData = T.get(chInd(i));
    if isfield(nodeData, paramName) && strcmp(num2str(nodeData.(paramName)), num2str(paramVal))
        chInd_out = [chInd_out chInd(i)];
    end
end
