%% vary GJ density
branchN = 2.2;
initBranchLength = 15;
theta = 10;
%densityVec = logspace(1.5,3.5,15);
densityVec = [50 100 150 200 250 300 400 500 1000 2000];
    
Nseeds = 10;
L = length(densityVec);

rootDir = '~/Dropbox/nNOS-2 paper/Model/makeNetworkMATLAB/ModelNetworks/varyGJDensity';

for i=1:L
    for s=1:Nseeds
        tic;
        [allLines, connOut, connectivity, nGJ, positions, distVec, allGJ_points] = nNOS_geom_model_parameterized(theta, branchN, initBranchLength, densityVec(i), s);
        toc;
        dirName = [rootDir filesep 'density=' num2str(round(densityVec(i))) '_seed=' num2str(s)];
        disp([num2str(i) ' of ' num2str(L)]);
        
        mkdir(dirName);        
        save([dirName filesep 'network.mat'], 'allLines', 'connOut', 'connectivity', 'positions', 'nGJ', 'distVec', 'allGJ_points');
        save_nNOS_network(allLines,connOut,dirName);

    end
end

%% vary theta_sd
branchN = 2.2;
initBranchLength = 15;

theta_Vec = [5:10:175];
Nseeds = 10;
density = 300;
L = length(theta_Vec);

rootDir = '~/Dropbox/nNOS-2 paper/Model/makeNetworkMATLAB/ModelNetworks/varyTheta';

for i=1:L
    for s=1:Nseeds
        tic;
        [allLines, connOut, connectivity, nGJ, positions, distVec, allGJ_points] = nNOS_geom_model_parameterized(theta_Vec(i), branchN, initBranchLength, density, s);
        toc;
        dirName = [rootDir filesep 'theta=' num2str(theta_Vec(i)) '_seed=' num2str(s)]
        disp([num2str(i) ' of ' num2str(L)]);
        
        mkdir(dirName);        
        save([dirName filesep 'network.mat'], 'allLines', 'connOut', 'connectivity', 'positions', 'nGJ', 'distVec', 'allGJ_points');
        save_nNOS_network(allLines,connOut,dirName);

    end
end

%% vary initBranchLength
branchN = 2.2;
theta_sd = 15;

initBranchLength_Vec = [15:10:115];
density = 300;
Nseeds = 10;
L = length(initBranchLength_Vec);

rootDir = '~/Dropbox/nNOS-2 paper/Model/makeNetworkMATLAB/ModelNetworks/varyInitLength';

for i=1:L
    for s=1:Nseeds
        tic;
        [allLines, connOut, connectivity, nGJ, positions, distVec, allGJ_points] = nNOS_geom_model_parameterized(theta_sd, branchN, initBranchLength_Vec(i), density, s);
        toc;
        dirName = [rootDir filesep 'initLen=' num2str(initBranchLength_Vec(i)) '_seed=' num2str(s)]
        disp([num2str(i) ' of ' num2str(L)]);
        
        mkdir(dirName);        
        save([dirName filesep 'network.mat'], 'allLines', 'connOut', 'connectivity', 'positions', 'nGJ', 'distVec', 'allGJ_points');
        save_nNOS_network(allLines,connOut,dirName);

    end
end


%% vary branchN
theta_sd = 15;
initBranchLength = 15;
density = 300;

Nseeds = 10;
branchN_Vec = [2:0.1:4];
L = length(branchN_Vec);

rootDir = '~/Dropbox/nNOS-2 paper/Model/makeNetworkMATLAB/ModelNetworks/varyNbranches';

for i=1:L
    for s=1:Nseeds
        tic;
        [allLines, connOut, connectivity, nGJ, positions, distVec, allGJ_points] = nNOS_geom_model_parameterized(theta_sd, branchN_Vec(i), initBranchLength, density, s);
        toc;
        dirName = [rootDir filesep 'branchN=' num2str(branchN_Vec(i)) '_seed=' num2str(s)]
        disp([num2str(i) ' of ' num2str(L)]);
        
        mkdir(dirName);        
        save([dirName filesep 'network.mat'], 'allLines', 'connOut', 'connectivity', 'positions', 'nGJ', 'distVec', 'allGJ_points');
        save_nNOS_network(allLines,connOut,dirName);

    end
end
