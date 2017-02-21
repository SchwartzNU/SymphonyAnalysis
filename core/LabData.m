classdef LabData < handle
    properties
        cellTypes = containers.Map; %keys are cell type names (e.g. On Alpha), values are cell names (e.g. 042214Ac1)
        allDataSets = containers.Map %keys are cell names, values are cell arrays of data set names
        analysisFolder;
    end
    
    methods
        function obj = LabData()
            global ANALYSIS_FOLDER
            obj.analysisFolder = ANALYSIS_FOLDER;
            
            %clear everything
            obj.cellTypes = containers.Map; %keys are cell type names (e.g. On Alpha), values are cell names (e.g. 042214Ac1)
            obj.allDataSets = containers.Map;
        end
        
        function clearContents(obj)
            obj.cellTypes = containers.Map; %keys are cell type names (e.g. On Alpha), values are cell names (e.g. 042214Ac1)
            obj.allDataSets = containers.Map;
        end
        
        function val = hasCell(obj, cellName)
            allCells = obj.allCellNames();
            if sum(strcmp(allCells, cellName)) > 0
                val = true;
            else
                val = false;
            end
        end
        
        function typeName = getCellType(obj, cellName)
            cellTypes = obj.allCellTypes();
            typeName = [];
            for i=1:length(cellTypes)
                if any(strmatch(cellName, obj.cellTypes(cellTypes{i}), 'exact'))
                    typeName = cellTypes{i};
                end
            end
            %if isempty(typeName)
            %    warndlg(['Warning: Cell ' cellName ' not found.']);
            %end
        end
        
        function cellNames = getCellsOfType(obj, typeName)
            %returns string array of cell names
            if obj.cellTypes.isKey(typeName)
                cellNames = obj.cellTypes(typeName);
            else
                cellNames = [];
                %warndlg(['Warning: Cell type ' typeName ' not found.']);
            end
        end
        
        function cellTypes = allCellTypes(obj)
            cellTypes = obj.cellTypes.keys;
        end
        
        function cellNames = allCellNames(obj)
            typeList = obj.allCellTypes();
            cellNames = {};
            for i=1:length(typeList);
                cellNames = [cellNames; obj.cellTypes(typeList{i})];
            end
        end
        
        function addCell(obj, cellName, typeName)
            allNames = obj.allCellNames();
            if strcmp(allNames, cellName)
                errordlg(['Cell ' cellName ' is already in the database. Use moveCell instead']);
                return
            end
            if obj.cellTypes.isKey(typeName)
                obj.cellTypes(typeName) = [obj.cellTypes(typeName); cellName];
            else
                %answer = questdlg(['Add new cell type ' typeName '?'] , 'New cell type warning:', 'No','Yes','Yes');
                %if strcmp(answer, 'Yes')
                obj.cellTypes(typeName) = {cellName};
                %end
            end
            obj.updateDataSets(cellName);
        end
        
        function renameType(obj, oldTypeName, newTypeName)
            cellTypes = obj.allCellTypes();
            if ~any(strmatch(oldTypeName, cellTypes, 'exact'))
                errordlg(['Type ' oldTypeName ' not found']);
                return
            end
            
            curCellList = obj.cellTypes(oldTypeName);
            obj.cellTypes(newTypeName) = curCellList;
            obj.cellTypes.remove(oldTypeName);
        end
        
        function renameCell(obj, oldCellName, newCellName)
            allCells = obj.allCellNames();
            if ~any(strmatch(oldCellName, allCells, 'exact'))
                errordlg(['Cell ' oldCellName ' not found']);
                return
            end
            
            typeName = obj.getCellType(oldCellName);
            curList = obj.cellTypes(typeName);
            curList = strrep(curList, oldCellName, newCellName);
            obj.cellTypes(typeName) = curList;
            dataSets = obj.allDataSets(oldCellName);
            obj.allDataSets.remove(oldCellName);
            obj.allDataSets(newCellName) = dataSets;
        end
        
        function moveCell(obj, cellName, typeName)
            allCells = obj.allCellNames();
            if ~any(strmatch(cellName, allCells, 'exact'))
                errordlg(['Cell ' cellName ' not found']);
                return
            end
            
            %remove from old list
            oldTypeName = obj.getCellType(cellName);
            curList = obj.cellTypes(oldTypeName);
            curList = curList(~strcmp(cellName, curList));
            obj.cellTypes(oldTypeName) = curList;
            
            %remove if empty
            if isempty(curList)
                obj.cellTypes.remove(oldTypeName);
            end
            
            %add to new list
            if obj.cellTypes.isKey(typeName)
                obj.cellTypes(typeName) = [obj.cellTypes(typeName); cellName];
            else
                %answer = questdlg(['Add new cell type ' typeName '?'] , 'New cell type warning:', 'No','Yes','Yes');
                %if strcmp(answer, 'Yes')
                obj.cellTypes(typeName) = {cellName};
                %end
            end
            
        end
        
        function clearEmptyTypes(obj)
            allTypes = obj.allCellTypes();
            for i=1:length(allTypes)
                if isempty(obj.cellTypes(allTypes{i}))
                    obj.cellTypes.remove(allTypes{i});
                end
            end
        end
        
        function deleteCell(obj, cellName)
            allCells = obj.allCellNames();
            if ~any(strcmp(cellName, allCells))
                errordlg(['Cell ' cellName ' not found']);
                return
            end
            typeName = obj.getCellType(cellName);
            curList = obj.cellTypes(typeName);
            curList = curList(~strcmp(cellName, curList));
            obj.cellTypes(typeName) = curList;
            obj.allDataSets.remove(cellName);
            
            if isempty(obj.getCellsOfType(typeName))
                obj.cellTypes.remove(typeName);
            end
        end
        
        function mergeCellTypes(obj, type1, type2)
            %merge type 1 into type 2
            c1 = obj.getCellsOfType(type1);
            for i=1:length(c1)
                obj.addCell(c1{i}, type2);
            end
            obj.cellTypes.remove(type1);
        end
        
        function cellNames = cellsWithDataSet(obj, dataSetName)
            allCells = obj.allCellNames();
            cellNames = {};
            for i=1:length(allCells)
                curCell = allCells{i};
                if strmatch(dataSetName, obj.allDataSets(curCell))
                    cellNames = [cellNames; curCell];
                end
            end
        end
        
        function [cellTypes, N] = cellTypesWithDataSet(obj, dataSetName)
            %N is the number of each
            cellNames = obj.cellsWithDataSet(dataSetName);
            cellCountMap = containers.Map;
            for i=1:length(cellNames)
                curType = obj.getCellType(cellNames{i});
                if ~cellCountMap.isKey(curType)
                    cellCountMap(curType) = 1;
                else
                    cellCountMap(curType) = cellCountMap(curType) + 1;
                end
            end
            cellTypes = cellCountMap.keys;
            N = cell2mat(cellCountMap.values);
            for i=1:length(cellTypes)
                disp([cellTypes{i} ': ' num2str(N(i))]);
            end
        end
        
        %update functions
        function updateDataSets(obj, cellNames)
            if nargin < 2
                cellNames = obj.allCellNames();
            end
            if ischar(cellNames)
                cellNames = {cellNames};
            end
            for i=1:length(cellNames)
                curCellName = cellNames{i};
                curCellName_orig = curCellName;
                %Deal with cell names that include '-Ch1' or '-Ch2'
                curCellName = strrep(curCellName, '-Ch1', '');
                curCellName = strrep(curCellName, '-Ch2', '');
                
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
                    load([obj.analysisFolder 'cellData' filesep curCellName]); %loads cellData
                    obj.allDataSets(curCellName_orig) = cellData.savedDataSets.keys;
                else
                    for j=1:length(curCellNameParts)
                        load([obj.analysisFolder 'cellData' filesep curCellNameParts{j}]); %loads cellData
                        if j==1
                            obj.allDataSets(curCellName_orig) = cellData.savedDataSets.keys;
                        else
                            obj.allDataSets(curCellName_orig) = [obj.allDataSets(curCellName_orig), cellData.savedDataSets.keys];
                        end
                    end
                end
            end
            
        end
        
        function displayAllDataSets(obj, cellName)
            dataSets = obj.allDataSets(cellName);
            for i=1:length(dataSets)
                disp(dataSets{i});
            end
        end
        
        function displayCellTypes(obj)
            cellTypeKeys = obj.cellTypes.keys;
            for i=1:length(cellTypeKeys)
                disp([cellTypeKeys{i} ': ' num2str(length(obj.cellTypes(cellTypeKeys{i})))]);
            end
        end
        
        %analysis functions
        function analyzeCells(obj, cellNames)
            
            %cellNames can be a single str or a cell array of cell names
            %(as returned by getCellsOfType)
            if ischar(cellNames)
                cellNames = {cellNames};
            end
            tic
            for i=1:length(cellNames)
                curCellName = cellNames{i};
                disp(['Analyzing cell ' curCellName ': ' num2str(i) ' of ' num2str(length(cellNames))]);
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
                    analysisTree = analyzeCell(curCellName);
                    save([obj.analysisFolder 'analysisTrees' filesep curCellName], 'analysisTree');
                else
                    for j=1:length(curCellNameParts)
                        %j
                        %curCellNameParts{j}
                        analysisTree = analyzeCell(curCellNameParts{j});
                        save([obj.analysisFolder 'analysisTrees' filesep curCellNameParts{j}], 'analysisTree');
                    end
                end
            end
            disp('Analysis complete')
            toc
        end
        
        function resultTree = collectCells(obj, cellNames)
            %cellNames can be a single str or a cell array of cell names
            %(as returned by getCellsOfType)
            if ischar(cellNames)
                cellNames = {cellNames};
            end
            %set up output tree
            resultTree = AnalysisTree;
            nodeData.name = 'Collected cells tree: multiple cells';
            resultTree = resultTree.set(1, nodeData);
            
            for i=1:length(cellNames)
                curCellName = cellNames{i};
                disp(['Collecting cell ' curCellName ': ' num2str(i) ' of ' num2str(length(cellNames))]);
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
                    load([obj.analysisFolder 'analysisTrees' filesep curCellName]);
                    if length(analysisTree.Node)>1
                        resultTree = resultTree.graft(1, analysisTree);
                    end
                else
                    splitCellTree = AnalysisTree;
                    nodeData = struct;
                    nodeData.name = ['Split cell: ' curCellName];
                    splitCellTree = splitCellTree.set(1, nodeData);
                    for j=1:length(curCellNameParts)
                        load([obj.analysisFolder 'analysisTrees' filesep curCellNameParts{j}]);
                        if length(analysisTree.Node)>1
                            splitCellTree = splitCellTree.graft(1, analysisTree);
                        end
                    end
                    if length(splitCellTree.Node)>1
                        resultTree = resultTree.graft(1, splitCellTree);
                    end
                end
                
            end
        end
        
        function resultTree = collectAnalysis(obj, analysisName, cellTypes, cellFilter, epochFilter)
            %if overwriteFlag is true, this will recompute the analysis for
            %each cell
            %it should always compute the analysis if the cell has the
            %matching dataset (not the current behavior of collectAnalysis)
            if nargin < 5
                epochFilter = [];
            end
            if nargin < 4
                cellFilter = [];
            end
            if nargin < 3
                cellTypes = obj.allCellTypes;
            end
            if ischar(cellTypes)
                cellTypes = {cellTypes};
            end
            
            %set up output tree
            resultTree = AnalysisTree;
            nodeData.name = ['Collected analysis tree: ' analysisName];
            resultTree = resultTree.set(1, nodeData);

            for i=1:length(cellTypes)
                curType = cellTypes{i};
                disp(['Analyzing type ' curType ': ' num2str(i) ' of ' num2str(length(cellTypes))]);
                %set up type output tree
                curTypeTree = AnalysisTree;
                nodeData.name = [curType];
                curTypeTree = curTypeTree.set(1, nodeData);
                
                cellNames = obj.getCellsOfType(curType);
                for j=1:length(cellNames)
                    curCellName = cellNames{j};
                    disp(['Analyzing cell ' curCellName ': ' num2str(j) ' of ' num2str(length(cellNames))]);
                    
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
                        curResultTree = doSingleAnalysis(cellNames{j}, analysisName, cellFilter, epochFilter);
                        if ~isempty(curResultTree)
                            curTypeTree = curTypeTree.graft(1, curResultTree);
                        end
                    else
                        for k=1:length(curCellNameParts)
                            curResultTree = doSingleAnalysis(curCellNameParts{k}, analysisName, cellFilter, epochFilter);
                            if ~isempty(curResultTree)
                                curTypeTree = curTypeTree.graft(1, curResultTree);
                            end
                            
                        end
                    end
                    
                end
                if length(curTypeTree.Node)>1
                    resultTree = resultTree.graft(1, curTypeTree);
                end
            end
            
        end
        
    end
    
    
end