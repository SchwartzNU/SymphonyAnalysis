function levelIDs = getTreeLevel(tree, splitParam, value)
    if nargin < 3
        value = [];
    end
    iterator = breadthfirstiterator(tree);
    levelIDs = [];
    for i=1:length(iterator);
        curNodeData = tree.get(iterator(i));
        if isfield(curNodeData, 'splitParam') && strcmp(curNodeData.splitParam, splitParam)
            if ~isempty(value)
               if strcmp(num2str(curNodeData.splitValue), num2str(value))
                   levelIDs = [levelIDs iterator(i)]; 
               end
            else
                levelIDs = [levelIDs iterator(i)]; 
            end
        end
    end
end