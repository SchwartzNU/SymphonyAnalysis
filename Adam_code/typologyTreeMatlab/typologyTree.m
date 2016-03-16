function T = typologyTree
%typology tree implementation
%Adam 1/13/15

%In a later version: pass in a remodeled tree to automatically get new cellTypeList and id
%fields. Reset = 'yes' resets to original structure.

%Manual initial structure
t = tree(0);
t = t.addnode(1, 1);
t = t.addnode(1, 2);
t = t.addnode(find(t==1), 11);
t = t.addnode(find(t==1), 12);
t = t.addnode(find(t==12), 121);
t = t.addnode(find(t==12), 122);
t = t.addnode(find(t==122), 1221);
t = t.addnode(find(t==1221), 12211);
t = t.addnode(find(t==12211), 122111);
t = t.addnode(find(t==12211), 122112);
t = t.addnode(find(t==1221), 12212);
t = t.addnode(find(t==12212), 122121);
t = t.addnode(find(t==12212), 122122);
t = t.addnode(find(t==122), 1222);
t = t.addnode(find(t==1222), 12221);
t = t.addnode(find(t==1222), 12222);
t = t.addnode(find(t==12222), 122221);
t = t.addnode(find(t==12222), 122222);
t = t.addnode(find(t==2), 21);
t = t.addnode(find(t==21), 211);
t = t.addnode(find(t==21), 212);
t = t.addnode(find(t==212), 2121);
t = t.addnode(find(t==212), 2122);
t = t.addnode(find(t==2), 22);
t = t.addnode(find(t==22), 221);
t = t.addnode(find(t==221), 2211);
t = t.addnode(find(t==221), 2212);
t = t.addnode(find(t==22), 222);
t = t.addnode(find(t==222), 2221);
t = t.addnode(find(t==2221), 22211);
t = t.addnode(find(t==2221), 22212);
t = t.addnode(find(t==22212), 222121);
t = t.addnode(find(t==22212), 222122);
t = t.addnode(find(t==222), 2222);
t = t.addnode(find(t==2222), 22221);
t = t.addnode(find(t==22221), 222211);
t = t.addnode(find(t==22221), 222212);
t = t.addnode(find(t==222212), 2222121);
t = t.addnode(find(t==222212), 2222122);
t = t.addnode(find(t==2222122), 22221221);
t = t.addnode(find(t==2222122), 22221222);
t = t.addnode(find(t==22221222), 222212221);
t = t.addnode(find(t==22221222), 222212222);
t = t.addnode(find(t==2222), 22222);
t = t.addnode(find(t==22222), 222221);
t = t.addnode(find(t==22222), 222222);
t = t.addnode(find(t==222222), 2222221);
t = t.addnode(find(t==222222), 2222222);
t = t.addnode(find(t==2222222), 22222221);
t = t.addnode(find(t==2222222), 22222222);


cellTypeList0 =  {
    'ON alpha';
    'OFF transient alpha';
    'OFF sustained alpha';
    'ON high speed sensitive';
    'OFF transient high speed sensitive';
    'ON-OFF DS sustained';
    'ON-OFF DS transient';
    'ON DS sustained';
    'ON sustained non-alpha';
    'ON sustained ODB';
    'ON transient LSDS';
    'LED';
    'ON-OFF size selector';
    'ON transient OFF sustained';
    'Suppressed by contrast';
    'ON delayed';
    'ON OS';
    'OFF OS';
    'JAM-B';
    'Large bursty'};

singleTypeNodeList =  {
    [2212, 222211];
    [121];
    [11];
    [2211];
    [122111];
    [2122];
    [2121];
    [211];
    [222212221];
    [22221221];
    [2222221];
    [222122];
    [222212222, 22222222];
    [22222221];
    [122222, 222221];
    [222121]
    [22211,2222121];
    [12221];
    [122112, 122122, 122221];
    [122121]};

%Conditions manually, for breadth first order of th nodes
%Separate parameters by spaces; analysisTree other than LS put stim.
%initials in beginning.
cl = {'ONOFFindex.mean_c < -0.5';
    'ONOFFindex.mean_c > -0.5';
    'baselineRate.mean_c > 60';
    'baselineRate.mean_c < 60';
    'DSI > 0.18';
    'DSI < 0.18';
    'OFFSETpeakInstantaneousFR.mean_c > 400';
    'OFFSETpeakInstantaneousFR.mean_c < 400';
    'ONSETpeakInstantaneousFR.mean_c < 100';
    'ONSETpeakInstantaneousFR.mean_c > 100';
    'ONSET_FRmax.value < 300, alt. ONSETpeakInstantaneousFR.mean_c < 360';   %alternative possible conditions, not "&&".
    'ONSET_FRmax.value > 300, alt. ONSETpeakInstantaneousFR.mean_c > 360';
    'OFFSETburstRate.mean_c > 130';
    'OFFSETburstRate.mean_c < 130';
    'SMS OFFSET_FRrangeFrac_Xmax; OFFSETnonBurstDuration_absMax';   %more params possible, too little data, see specific paramLists saved.
    'SMS OFFSET_FRrangeFrac_Xmax; OFFSETnonBurstDuration_absMax';
    'ONSETrespDuration.median_c < 0.5';
    'ONSETrespDuration.median_c > 0.5';
    'ONSETlatency.median_c > 0.3';
    'ONSETlatency.median_c < 0.3';
    'baselineRate.mean_c < 2';
    'baselineRate.mean_c > 2';
    'FB ??';
    'FB ??';
    'FB ??';
    'FB ??';
    'ONSETrespDuration.mean_c > 0.4';
    'ONSETrespDuration.mean_c < 0.4';
    'OFFSETspikes_grandBaselineSubtracted_generalMean > 5';
    'OFFSETspikes_grandBaselineSubtracted_generalMean < 5';
    '(OFFSETburstNonBurstRatio_duration.mean_c > 0.5) && (blistQ10.value < 0.02)';
    '~((OFFSETburstNonBurstRatio_duration.mean_c > 0.5) && (blistQ10.value < 0.02))';
    'ONSET_FRmax.value > 85';
    'ONSET_FRmax.value < 85';
    'SMS ONSETspikes_Xcutoff > 500, alt. SMS ONSETrespDuration_Xwidth > 200';
    'SMS ONSETspikes_Xcutoff < 500, alt. SMS ONSETrespDuration_Xwidth < 200';
    '(ONSETspikes.mean_c > 100) && (ONSET_FRmax.value > 280)';
    '~((ONSETspikes.mean_c > 100) && (ONSET_FRmax.value > 280))';
    'baselineRate.mean_c > 2';
    'baselineRate.mean_c < 2';
    'FB OSI > X ??';
    'FB OSI < X ??';
    'MB250 DSI > X?';
    'MB250 DSI < X?';
    'spikeAmp ??';
    'spikeAmp ??';
    '(SMS ONSETspikes_absMax < 16) && (SMS OFFSETlatency_absMax >  0.15)';
    '~((SMS ONSETspikes_absMax < 16) && (SMS OFFSETlatency_absMax >  0.15))';
    'SMS ONSETspikes_Xwidth > 500, alt. SMS spikeCount_stimInterval_baselinesSubtracted_Xcutoff > 400';
    'SMS ONSETspikes_Xwidth < 500, alt. SMS spikeCount_stimInterval_baselinesSubtracted_Xcutoff < 400';
    };





%Set single cell types in leaf nodes.
fullTree = tree(t,  struct('id',[],'conditions', {}, 'cellTypeList',{}));
curNode = fullTree.get(1);


for cellTypeInd = 1:length(cellTypeList0)
    curNode(1).cellTypeList = cellTypeList0(cellTypeInd);
    for cellTypeSplit = 1:length(singleTypeNodeList{cellTypeInd})
        fullTree = fullTree.set(find(t==singleTypeNodeList{cellTypeInd}(cellTypeSplit)),curNode);
    end;
end;

%Fill in celltypeList recursively
[fullTree, cellTypeList0] = recursiveConcat(fullTree,1);

%Relabel nodes recursively
fullTree = recursiveLabel(fullTree, 1, 0);


%Fill in condition list
conditionList = cell(length(fullTree.Node)-1,2);
conditionListInd = fullTree.breadthfirstiterator;
conditionListInd = conditionListInd(2:end);
for I =1:length(fullTree.Node)-1
    curNode = fullTree.get(conditionListInd(I));
    conditionList{I,1} = curNode.id;
    curNode.conditions = cl{I};
    fullTree = fullTree.set(conditionListInd(I),curNode);
end;
conditionList(:,2) = cl;
disp(conditionList)
% %



T = fullTree;

end
