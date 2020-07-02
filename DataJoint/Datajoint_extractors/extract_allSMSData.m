function [] = extract_allSMSData
allTypes = unique(fetchn(sl.RecordedNeuron, 'cell_type'));

for i=1:length(allTypes)
    newName = input(['Name for ' allTypes{i} ': '],'s');
    fname = ['SMS_' newName];
    
    positionStruct = extract_cellPositionsForQuery(q, fname)
end