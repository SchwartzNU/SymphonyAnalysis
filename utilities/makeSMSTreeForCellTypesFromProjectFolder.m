function [] = makeSMSTreeForCellTypesFromProjectFolder(fname_cellTypes, filterName)
ANALYSIS_FOLDER = getenv('ANALYSIS_FOLDER');

fid = fopen(fname_cellTypes, 'r');
temp = textscan(fid, '%s', 'delimiter', '\n');
cellTypeNames = temp{1};
fclose(fid);

treeFolder = [ANALYSIS_FOLDER 'analysisTrees' filesep 'SMS'];
filterDirectory = [ANALYSIS_FOLDER 'acrossCellFilters' filesep];
load([filterDirectory filterName]);

cellFilter = [];

analysisName = 'SpotsMultiSizeAnalysis';
epochFilt = SearchQuery();
for i=1:size(filterData,1)
    if ~isempty(filterData{i,1})
        epochFilt.fieldnames{i} = filterData{i,1};
        epochFilt.operators{i} = filterData{i,2};
        
        value_str = filterData{i,3};
        if isempty(value_str)
            value = [];
        elseif strfind(value_str, ',')
            z = 1;
            r = value_str;
            while ~isempty(r)
                [token, r] = strtok(r, ',');
                value{z} = strtrim(token);
                z=z+1;
            end
        elseif isletter(value_str(1)) % call it char if the first entry is a char
            value = value_str;
        else
            value = str2num(value_str); %#ok<ST2NM>
        end
        
        epochFilt.values{i} = value;
    end
end
epochFilt.pattern = filterPatternString;

for i=1:length(cellTypeNames)
    curName = cellTypeNames{i}
    dirName = [ANALYSIS_FOLDER 'Projects' filesep 'SMS_by_type' filesep curName];
    fid = fopen([dirName filesep 'cellNames.txt'], 'r');
    temp = textscan(fid, '%s', 'delimiter', '\n')
    cellNames = temp{1}
    fclose(fid);
    
    Ncells = length(cellNames);
    
    %set up output tree
    resultTree = AnalysisTree;
    nodeData.name = ['Collected analysis tree: ' analysisName];
    resultTree = resultTree.set(1, nodeData);
    
    disp(['Analyzing type ' curName ' : ' num2str(Ncells) ' cells']);
    %set up type output tree
    curTypeTree = AnalysisTree;
    nodeData.name = curName;
    curTypeTree = curTypeTree.set(1, nodeData);
    
    for j=1:length(cellNames)
        curCellName = cellNames{j};
        disp(['Analyzing cell ' curCellName ': ' num2str(j) ' of ' num2str(Ncells)]);
        
        %deal with cells split across two files
        [curCellNameParts{1}, remStr] = strtok(curCellName, ',');
        if isempty(remStr), curCellNameParts = {}; end
        z=2;
        while ~isempty(remStr)
            [cellNamePart, remStr] = strtok(remStr, ',');
            if ~isempty(cellNamePart)
                curCellNameParts{z} = strtrim(cellNamePart);
            end
            z=z+1;
        end
        if isempty(curCellNameParts)
            try
                curResultTree = doSingleAnalysis(cellNames{j}, analysisName, cellFilter, epochFilt);
            catch
            end
            if ~isempty(curResultTree)
                curTypeTree = curTypeTree.graft(1, curResultTree);
            end
        else
            for k=1:length(curCellNameParts)
                try
                    curResultTree = doSingleAnalysis(curCellNameParts{k}, analysisName, cellFilter, epochFilt);
                catch
                end
                if ~isempty(curResultTree)
                    curTypeTree = curTypeTree.graft(1, curResultTree);
                end
                
            end
        end
        
    end
    if length(curTypeTree.Node)>1
        resultTree = resultTree.graft(1, curTypeTree);
    end
    
    analysisTree = resultTree;
    save([treeFolder filesep curName], 'analysisTree');
    extractSMSFromTreeLeaves(resultTree, curName);
end