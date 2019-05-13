function returnStruct = analysisTreeDataExtractor(T, nameFunc, paramList)
    %T is analysis tree
    %
    %nameFunc is a function used for converting the name of the node into
    %the convention you want for Igor data sets
    %
    %paramList is a cell array of parameters you want to extract
    
    allInd = T.nodeorderiterator;
    L = length(allInd);
    
    Nparams = length(paramList);
    z = 1;
    
    returnStruct = struct;
    
    for i=1:L
        paramCheck = zeros(1,Nparams);
        curNode = T.get(allInd(i));
        
        %check if it has the right fields
        for p=1:Nparams
            paramCheck(p) = isfield(curNode, paramList{p});
        end
        
        %must have all of them... could change this behavior
        if sum(paramCheck) == Nparams
            
            % This is where you should call nameFunc and fix the name into
            % something better
            returnStruct(z).name = curNode.name;
             
            for p=1:Nparams
                if isstruct(curNode.(paramList{p})) %parameter struct
                    paramStruct = curNode.(paramList{p});
                    paramType = paramStruct.type;
                    paramUnits = paramStruct.units;
                    if strcmp(paramType, 'byEpoch')
                        if strcmp(paramUnits, 's')
                          returnStruct(z).(paramList{p}) = paramStruct.median_c;
                        else
                           returnStruct(z).(paramList{p}) = paramStruct.mean_c;
                        end
                    else %single value
                         returnStruct(z).(paramList{p}) =  paramStruct.value;
                    end
                else %regular vec
                    returnStruct(z).(paramList{p}) = curNode.(paramList{p});
                end
            end
            
            z=z+1;
        end
        
        %This is where you should call exportStructToHDF5 on each
        %returnStruct, so ...
        %exportStructToHDF5(returnStruct(i), fileName, returnStruct(i).name)
        
    end

    
end