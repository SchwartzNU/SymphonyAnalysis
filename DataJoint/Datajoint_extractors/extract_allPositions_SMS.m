function [] = extract_allPositions_SMS
allTypes = unique(fetchn(sl.RecordedNeuron, 'cell_type'));

for i=1:length(allTypes)
    newName = input(['Name for ' allTypes{i} ': '],'s');
    fname = ['Positions_SMSdata_' newName];
    q = sl.RecordedNeuron * sl.SMSSpikeData & ['cell_type =  "' allTypes{i} '"'];
    extract_cellPositionsForQuery(q, fname);
end