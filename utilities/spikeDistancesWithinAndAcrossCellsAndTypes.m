function [Dmean, Dstd, Derr, spCount_meanByType, spCount_stdByType] = spikeDistancesWithinAndAcrossCellsAndTypes(allCellTypeCodes, spM, cost, type)
%type: withinCell, withinType, or acrossType
%Ncells = length(allCellNames);
typeCodes = unique(allCellTypeCodes);
Ntypes = length(typeCodes);

L = length(typeCodes);
cellInd = cell(1,L);
for i=1:L
    cellInd{i} = find(allCellTypeCodes == typeCodes(i));
end

Dmean = zeros(1, Ntypes);
Dstd = zeros(1, Ntypes);
Derr = zeros(1, Ntypes);
spCount_meanByType = zeros(1, Ntypes);
spCount_stdByType = zeros(1, Ntypes);

z = 1;
if strcmp(type, 'withinCell')
    disp('within cell')
    for t=1:Ntypes
        disp([num2str(t) ' of ' num2str(Ntypes) ' types']);
        curCells = cellInd{t};
        Ncells = length(curCells);
        Dmeans_within_cell = zeros(1, Ncells);
        spCount_mean = zeros(1, Ncells);
        for i=1:Ncells
            tic;
            disp([num2str(z) ' of ' num2str(length(allCellTypeCodes)) ' cells']);
            z=z+1;
            if ~isempty(spM{curCells(i)})
                [Dmeans_within_cell(i), Dstd_temp, Derr_temp, spCount_mean(i)] = pairwiseSpikeDistances(spM{curCells(i)}, cost);
                Dmeans_within_cell(i)
            end
            toc;
        end
        Dmean(t) = nanmean(Dmeans_within_cell);
        Dstd(t) = nanstd(Dmeans_within_cell);
        Derr(t) = Dstd(t)./sqrt(Ncells);
        spCount_meanByType(t) = nanmean(spCount_mean)
        spCount_stdByType(t) = nanstd(spCount_mean)
        disp(['Cost per spike = ' num2str(Dmean(t)/spCount_meanByType(t))]);
    end
elseif strcmp(type, 'withinType')
    disp('within type')
    for t=1:Ntypes
        disp([num2str(t) ' of ' num2str(Ntypes) ' types']);
        curCells = cellInd{t};
        Ncells = length(curCells);
        Dmeans_across = zeros(1, Ncells);
        spCount_mean = zeros(1, Ncells);
        for i=1:Ncells
            tic;
            disp([num2str(z) ' of ' num2str(length(allCellTypeCodes)) ' cells']);
            z=z+1;
            %across cells shuffle
            Ntrials = length(spM{curCells(i)});
            randList = randperm(Ncells, min(Ncells, Ntrials));
            sp_new = cell(1, min(Ncells, Ntrials));
            for j=1:min(Ncells, Ntrials)
                spTemp = spM{curCells(randList(j))};
                if ~isempty(spTemp)
                    sp_new{j} = spTemp{randperm(length(spTemp), 1)};  %random trial from within this other cell's data
                end
            end
            [Dmeans_across(i), Dstd, Derr, spCount_mean(i)] = pairwiseSpikeDistances(sp_new, cost);
            Dmeans_across(i)
            toc;
        end
        Dmean(t) = nanmean(Dmeans_across)
        Dstd(t) = nanstd(Dmeans_across)
        Derr(t) = Dstd(t)./sqrt(Ncells)
        spCount_meanByType(t) = nanmean(spCount_mean)
        spCount_stdByType(t) = nanstd(spCount_mean)
        disp(['Cost per spike = ' num2str(Dmean(t)/spCount_meanByType(t))]);
    end
elseif strcmp(type, 'acrossType')
    disp('across type')
    for t=1:Ntypes
        disp([num2str(t) ' of ' num2str(Ntypes) ' types']);
        curCells = cellInd{t};
        Ncells = length(curCells);
        Dmeans_across = zeros(1, Ncells); %across types now
        curCells = randperm(length(allCellTypeCodes), Ncells);   %random collection of cells
        for i=1:Ncells
            tic;
            disp([num2str(z) ' of ' num2str(length(allCellTypeCodes)) ' cells']);
            z=z+1;
            
            %across cells shuffle
            Ntrials = length(spM{curCells(i)});
            randList = randperm(Ncells, min(Ncells, Ntrials));
            sp_new = cell(1, min(Ncells, Ntrials));
            for j=1:min(Ncells, Ntrials)
                spTemp = spM{curCells(randList(j))};
                if ~isempty(spTemp)
                    sp_new{j} = spTemp{randperm(length(spTemp), 1)};  %random trial from within this other cell's data
                end
            end
            [Dmeans_across(i), Dstd_temp, Derr_temp, spCount_mean(i)] = pairwiseSpikeDistances(sp_new, cost);
            Dmeans_across(i)
            toc;
        end
        Dmean(t) = nanmean(Dmeans_across)
        Dstd(t) = nanstd(Dmeans_across)
        Derr(t) = Dstd(t)./sqrt(Ncells)
        spCount_meanByType(t) = nanmean(spCount_mean)
        spCount_stdByType(t) = nanstd(spCount_mean)
        disp(['Cost per spike = ' num2str(Dmean(t)/spCount_meanByType(t))]);
    end
elseif strcmp(type, 'allCellsPairwise')
    disp('allCellsPairwise')
    Ncells = length(allCellTypeCodes);
    Ncomparisons = 10;
    Dmat = zeros(Ncells,Ncells);
    spCounts = zeros(Ncells,Ncells); %use geometric mean here?
    for i=1:Ncells
        disp([num2str(i) ' of ' num2str(Ncells) ' cells']);
        tic;
        for j = i:Ncells            
            [D_temp, Dstd_temp, Derr_temp, spCount_mean] = pairwiseSpikeDistancesBetweenCells(spM{i},spM{j}, Ncomparisons, cost);
            Dmat(i,j) = D_temp;
            spCounts(i,j) = spCount_mean;
            
        end
        toc;
    end
    Dmean = Dmat;
    spCount_meanByType = spCounts;
    spCount_stdByType = nan;
    Derr = nan;
    Dstd = nan;
end



