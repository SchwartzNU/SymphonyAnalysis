function paramOverlap(analysisTree, cellType1, cellType2) 

userDate = '121814';
pathname = ['/Users/adammani/Documents/analysis/Adam Matlab analysis/',userDate,'/mat files/'];


paramList = {
    %'medianONlatency';
    'medianOFFlatency';
    
    'blistQuantile10';
    'blistQuantile90';
    'meanBlist';
    'meanONOFFindex';
    
    %'meanONenhancedSpikes';
    %'medianONburstDuration';
    %'meanONburstSpikes';
    %'medianONenhancedDuration';
    
    'meanOFFenhancedSpikes';
    'medianOFFburstDuration';
    'meanOFFburstSpikes';
    'medianOFFenhancedDuration';
    %'meanONnonBurstToBurstSpikes';
    
    %'meanONnonBurstToBurstFR';
    %'meanONnonBurstFR';
    %'meanONnonBurstSpikes';
    
    'meanOFFnonBurstToBurstSpikes';
    
    'meanOFFnonBurstToBurstFR';
    'meanOFFnonBurstFR';
    'meanOFFnonBurstSpikes';
    
    %'meanONpeakFR'
    'meanOFFpeakFR';
    
    'meanOFFnonBurstToPeakFR';
    'meanOFFenhancedToPeakFR';
    'meanOFFenhancedFR';
    'meanOFFburstFR';
    
%     'meanONnonBurstToPeakFR';
%     'meanONenhancedToPeakFR';
%     'meanONenhancedFR';
%     'meanONburstFR';

    'meanBaselineFR';
};
numParams = length(paramList);




%Collect parameter data
paramForCellType1 = cell(numParams,1);
paramForCellType2 = cell(numParams,1);
cellTypeNodes = analysisTree.getchildren(1);
for cellTypeInd = 1:length(cellTypeNodes)
    
    curCellType = analysisTree.Node{cellTypeNodes(cellTypeInd)}.name;
    disp(curCellType);
    if ~isempty( strfind(curCellType, cellType1))
        curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));
        for paramInd = 1:length(paramList)            
            paramName = paramList{paramInd};
            %given cell type, given parameter
            [cellNamesType1, paramForCellType1{paramInd}] = paramAcrossCells(curCellTypeTree, paramName);
        end;
              
    elseif ~isempty( strfind(curCellType, cellType2))
        curCellTypeTree = subtree(analysisTree, cellTypeNodes(cellTypeInd));
        for paramInd = 1:length(paramList)
            paramName = paramList{paramInd};
            %given cell type, given parameter
            [cellNamesType2, paramForCellType2{paramInd}] = paramAcrossCells(curCellTypeTree, paramName);
        end; 
    end;
 
end;    


%Make histograms and estimate inter-celltype difference
overlaps = zeros(numParams,1);
figure;
for paramInd = 1:numParams
    M1 = paramForCellType1{paramInd};
    M1 = M1(~isnan(M1) & ~(M1==inf));
    M2 = paramForCellType2{paramInd};
    M2 = M2(~isnan(M2) & ~(M2==inf));
    
    leftEdge = min([M1; M2]);
    rightEdge = max([M1; M2]);
    binSize =  (rightEdge - leftEdge)/10;
    centers = (leftEdge:binSize:rightEdge);
    
    if binSize > 0
        subplot(ceil(numParams/3), 3, paramInd);
        y1 = hist(M1, centers);
        y1 = y1./sum(y1);
        %y1 = resample(y1,5,1);
        
        y2 = hist(M2, centers);
        y2 = y2./sum(y2);
        %y2 = resample(y2,5,1);
        
        %centers = resample(centers,5,1);
        %[centers_sorted, ind] = sort(centers);
        
        %plot(centers_sorted, y1(ind), 'b');
        %hold('on');
        %plot(centers_sorted,y2(ind), 'y');        
        bar(centers,[y1' y2'],'stacked');
        title(paramList{paramInd});
        %hold('off');
        %keyboard;
    end;
    
    
    %calculate obverlap...
    y1n = y1./sqrt(y1*y1');
    y2n = y2./sqrt(y2*y2');
    overlaps(paramInd) = y1n*y2n';
%     %Kullback?
end;

[sortedOverlaps, sortedParamIndices] = sort(overlaps);
disp(sortedOverlaps);
paramList = paramList(sortedParamIndices);
disp(paramList);
[minOverlap, minOverlapParamIndex] =  min(sortedOverlaps);
disp(['Minimal ovrlap is: ', num2str(minOverlap),' using: ', paramList{minOverlapParamIndex}]);

%save
cellType1(strfind(cellType1,' ')) = '';
cellType1(strfind(cellType1,'/')) = '';
cellType1(strfind(cellType1,'-')) = '';

cellType2(strfind(cellType2,' ')) = '';
cellType2(strfind(cellType2,'/')) = '';
cellType2(strfind(cellType2,'-')) = '';

filename = ['overlap_',cellType1,'_',cellType2,'_',userDate];
fullfilename = [pathname, filename,'.mat'];
save(fullfilename, 'sortedOverlaps', 'paramList', 'cellNamesType1', 'paramForCellType1', 'cellNamesType2', 'paramForCellType2');


end



