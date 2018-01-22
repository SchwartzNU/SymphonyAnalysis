function [singleCombinationMatrix, singleReferenceMatrix] = generateCombinationMatrix(D)

numCells = size(D,2);

for cellInd = 1:numCells
    
    numGenes = length(D);
    expGenes = sum( D(:,cellInd) ~=0 );
    
    %%%%%% For integers
    %%singleCombinationMatrix = int32(zeros(nchoosek(expGenes,2),2));
    %%singleReferenceMatrix = int16(zeros(nchoosek(expGenes,2),2));
    
    singleCombinationMatrix = zeros(nchoosek(expGenes,2),2);
    singleReferenceMatrix = zeros(nchoosek(expGenes,2),2);
    currRow = 0;
    
    tic;
    disp(['Generating combinations for cell ' num2str(cellInd) ' of ' num2str(numCells) '...' ]);
    for geneA = 1:numGenes-1
        if D(geneA, cellInd) > 0
            for geneB = (geneA+1):numGenes
                if D(geneB, cellInd) > 0
                    currRow = currRow + 1;
                    singleCombinationMatrix(currRow,:) = [D(geneA, cellInd),D(geneB, cellInd)];
                    %singleCombinationMatrix(currRow,:) = [int32(D(geneA, cellInd)),int32(D(geneB, cellInd))];
                    singleReferenceMatrix(currRow,:) = [int16(geneA),int16(geneB)];
                end
            end          
        end
    end
    save(strcat('CombinationMatrix_cellInd',num2str(cellInd)),'singleCombinationMatrix');
    save(strcat('ReferenceMatrix_cellInd',num2str(cellInd)),'singleReferenceMatrix');
    toc;
end

end

