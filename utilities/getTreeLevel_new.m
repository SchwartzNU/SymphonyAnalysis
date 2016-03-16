function levelIDs = getTreeLevel_new(tree, splitParam, value)
if nargin < 3
    value = [];
end
iterator = tree.breadthfirstiterator;
%keyboard;
levelIDs = [];
for i=1:length(iterator);
    curNodeData = tree.get(iterator(i));
    if isfield(curNodeData, splitParam)
        disp(['found ' splitParam]);
        if ~isempty(value)
            if strcmp(num2str(curNodeData.(splitParam)), num2str(value))
                levelIDs = [levelIDs iterator(i)];
            end
        else
            levelIDs = [levelIDs iterator(i)];
        end
    end
end
