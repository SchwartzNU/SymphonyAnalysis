classdef AnalysisTree < tree
    properties
        filename
        filepath
        name %descriptive name of analysis
    end
    
    methods
        
        function obj = AnalysisTree()
            %constructor, empty for now
        end
        
        function obj = setName(obj, name)
            nodeData = struct;
            nodeData.name = name;
            obj = obj.set(1, nodeData);
        end
        
        function obj = copyAnalysisParams(obj, params)
           nodeData = obj.get(1);
           names = fieldnames(params);           
           for i=1:length(names)
              nodeData.(names{i}) = params.(names{i});
              if isprop(obj, names{i})
                  obj.(names{i}) = params.(names{i});
              end
           end
           obj = obj.set(1, nodeData);
        end
        
        function obj = addTreeLevel(obj, oldTree, analysisType, param)
            if isempty(param)
                return;
            end
            
            chInd = oldTree.getchildren(1);            
            L = length(chInd);
            values = cell(1,L);
            for i=1:L
                %find nodes that are of the right class and have a value for this parameter 
                %set other values to 'not part of analysis'
                curNode = oldTree.get(chInd(i));
                if strcmp(curNode.class, analysisType) && isfield(curNode, param)
                   values{i} = num2str(curNode.(param));                                   
                else
                   values{i} = 'not part of analysis';
                end
            end       
            
            uniqueVals = unique(values);
            uniqueVals = setdiff(uniqueVals, 'not part of analysis');
            Nvals = length(uniqueVals);
            for n=1:Nvals
               newNode = struct;
               newNode.name = [param '=' uniqueVals{n}];
               newNode.(param) = uniqueVals{n};
               obj = obj.addnode(1, newNode);
               newTree_chInd = obj.getchildren(1);

               for i=1:L                  
                  if strcmp(values{i}, uniqueVals{n}) %if matching value    
                    %disp('found match');
                    obj = obj.graft(newTree_chInd(n), oldTree.subtree(chInd(i)));
                  end
               end               
            end
        end
        
        function obj = buildCellTree(obj, rootNodeID, cellData, dataSet, paramList)
            if isempty(paramList)
                return;
            end
            
            curParam = paramList{1};
            if isa(curParam, 'function_handle')
                for i=1:length(dataSet)
                    v = curParam(cellData.epochs(dataSet(i)));
                    if isscalar(v)
                        allVals(i) = v;
                    else
                        allVals{i} = num2str(v);
                    end
                end
            else
                allVals = cellData.getEpochVals(paramList{1}, dataSet);
                
                % the above can return cell arrays of mixed strings and numbers, so clean it up here:
                if iscell(allVals)
                    for i=1:length(allVals)
                        if isscalar(allVals{i})
                            allVals{i} = num2str(allVals{i});
                        end
                    end
                end
            end
            uniqueVals = unique(allVals);
            
            for i=1:length(uniqueVals)
                if iscell(uniqueVals)
                    curVal = uniqueVals{i};
                else
                    curVal = uniqueVals(i);
                end
                newDataSet = [];
                for j=1:length(dataSet)
                    if iscell(allVals)
                        epochVal = allVals{j};
                    else
                        epochVal = allVals(j);
                    end
                    if ischar(curVal)
                        if strcmp(curVal, epochVal)
                            newDataSet = [newDataSet dataSet(j)];
                        end
                    else
                        if curVal == epochVal
                            newDataSet = [newDataSet dataSet(j)];
                        end
                    end
                end
                if ~isempty(newDataSet)
                    nodeData = struct;
                    
                    if isa(curParam, 'function_handle')
                        nodeData.splitParam = func2str(curParam);
                        nodeData.name = [func2str(curParam) '==' num2str(curVal)];
                    else
                        nodeData.splitParam = curParam;
                        nodeData.name = [curParam '==' num2str(curVal)];
                    end
                    nodeData.splitValue = curVal;
                    nodeData.epochID = newDataSet;
                    [obj, newID] = obj.addnode(rootNodeID, nodeData);
                    %recursive call
                    if length(paramList) > 1
                        obj = obj.buildCellTree(newID, cellData, newDataSet, paramList(2:end));
                    end
                end
            end
        end
        
        function obj = copyParamsFromSampleEpoch(obj, cellData, dataSet, params)
            sampleEpoch = cellData.epochs(dataSet(1));
            nodeData = obj.get(1);
            for i=1:length(params)
                nodeData.(params{i}) = sampleEpoch.get(params{i});
            end
            obj = obj.set(1, nodeData);
        end
        
        function cellName = getCellName(obj, nodeInd)
            nodeData = obj.get(nodeInd);
            cellName = '';
            while ~isfield(nodeData, 'cellName');
                nodeInd = obj.getparent(nodeInd);
                if nodeInd == 0
                   return;
                end
                nodeData = obj.get(nodeInd);
            end
            cellName = nodeData.cellName;            
        end
        
        function mode = getMode(obj, nodeInd)
            mode = '';
            nodeData = obj.get(nodeInd);
            while ~isfield(nodeData, 'ampModeParam');
                 if nodeInd==1
                    return;
                end
                nodeInd = obj.getparent(nodeInd);
                nodeData = obj.get(nodeInd);
            end
            mode = nodeData.(nodeData.ampModeParam);
        end
        
        function device = getDevice(obj, nodeInd)
            nodeData = obj.get(nodeInd);
            while ~isfield(nodeData, 'deviceName');
                nodeInd = obj.getparent(nodeInd);
                nodeData = obj.get(nodeInd);
            end
            device = nodeData.deviceName;
        end
        
        function className = getClassName(obj, nodeInd)
            className = [];
            nodeData = obj.get(nodeInd);
            while ~isfield(nodeData, 'class');
                if nodeInd==1
                    return;
                end
                nodeInd = obj.getparent(nodeInd);                
                nodeData = obj.get(nodeInd);
            end
            className = nodeData.class;
        end
        
        function obj = percolateUp(obj, nodeIDs, varargin)
            if length(varargin) == 2 && iscell(varargin{1}) && iscell(varargin{2}) %specified as 2 long lists instead
                inNames = varargin{1};
                outNames = varargin{2};
            else %in pairs
                inNames = varargin(1:2:end);
                outNames = varargin(2:2:end);
            end
            
            if length(inNames) ~= length(outNames)
                disp('Error: parameters must be specified in pairs');
            end
            %                 parentList = [];
            %                 for i=1:length(nodeIDs)
            %                     parentList = [parentList obj.getparent(nodeIDs(i))];
            %                 end
            %                 parentList = unique(parentList);
            
            for p=1:length(inNames)
                for i=1:length(nodeIDs)
                    parent = obj.getparent(nodeIDs(i));
                    %chIndex = find(obj.getchildren(parent) == nodeIDs(i));
                    nodeData = obj.get(parent);
                    if isfield(obj.get(nodeIDs(i)), inNames{p})
                        if ~isfield(nodeData, outNames{p})
                            nodeData.(outNames{p}) = []; 
                            %zeros(1,length(obj.getchildren(parent)));
                        end
                        %merging struct (special response struct) or just a
                        %value
                        if isstruct(obj.get(nodeIDs(i)).(inNames{p}))
                            S = obj.get(nodeIDs(i)).(inNames{p});
                            fnames = fieldnames(S);
                            for f = 1:length(fnames)
                                curField = fnames{f};
                                if strcmp(curField, 'units') || strcmp(curField, 'type') 
                                    %copy once
                                    nodeData.(outNames{p}).(curField) = S.(curField);
                                elseif length(S.(curField)) > 1
                                    %strcmp(curField, 'value') || strcmp(curField, 'value_c') || strcmp(curField, 'outliers')
                                    %do not copy these
                                else
                                    %copy as vector
                                    if ~isfield(nodeData.(outNames{p}), curField)
                                        curInd = 1;
                                    else
                                        curInd = length(nodeData.(outNames{p}).(curField)) + 1;
                                    end
                                    if isempty(S.(curField)) %why am I getting empties here?
                                        nodeData.(outNames{p}).(curField)(curInd) = NaN; 
                                    else
                                        nodeData.(outNames{p}).(curField)(curInd) = S.(curField);
                                    end
                                end
                            end
                        else
                            curVec = nodeData.(outNames{p});
                            curVec = [curVec obj.get(nodeIDs(i)).(inNames{p})];
                            nodeData.(outNames{p}) = curVec;
                        end
                        obj = obj.set(parent, nodeData);
                    end
                end
            end
            
        end
        
    end
    
    methods(Static)
        
        function plotLeaf(node, cellData)
            %do nothing - to be overwritten by each analysis class
            
        end
        
    end
    
end