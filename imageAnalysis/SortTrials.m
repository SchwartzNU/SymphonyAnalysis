cell = '040519Ac1';
load([CELL_DATA_FOLDER, cell])
keys = cellData.savedDataSets.keys;

if length(keys) > 1
    for i = 1:length(keys)
        display([ num2str(i),'. ', keys{i}])
    end
    ind = input('Which of these saved datasets should we use? ');
else
    ind = 1;
    display('Only 1 saved dataset found, so we are going to use it')
end

all_epochs = cellData.savedDataSets(keys{ind});
SpotSizes = cellData.getEpochVals('curSpotSize', all_epochs);
Unique_SpotSizes = unique(SpotSizes);


for i = 1:length(Unique_SpotSizes)
    cur_size = Unique_SpotSizes(i);
    find(SpotSizes == cur_size)
    
    foldername = ['Size', num2str(cur_size)];
    mkdir(foldername)
    
    MatchingEpochs = find(SpotSizes == cur_size);
    
    for ii = 1:length(MatchingEpochs)
        trial = MatchingEpochs(ii);
        imgfile = ['trial', num2str(trial), '.tif'];
        movefile(imgfile, foldername)
    end
end