% process auto center offline simply

timeOffset = nan;
% load('/Users/sam/analysis/cellData/051216Ac4.mat')
% sessionId = 201651215217;

% load('/Users/sam/analysis/cellData/032416Ac9.mat')
% sessionId = 2016324173256;

% load('/Users/sam/analysis/cellData/060216Ac2.mat')
% sessionId = 2016512181624;

% load('/Users/sam/analysis/cellData/033016Bc8.mat')
% sessionId = 201633020044;

% load('/Users/sam/analysis/cellData/010716Ac4.mat')
% sessionId = 1;

% load('/Users/sam/analysis/cellData/121616Ac7.mat')
% sessionId = 2016121616210;
% timeOffset = 0.3;

% load('/Users/sam/analysis/cellData/081517Ac3.mat')
% sessionId = {'2017815142854','2017815143647'};
% sessionId = 2017815142854; % on ex
% sessionId = 2017815143647; % off ex
% sessionId = 2017815152043; % on in
% timeOffset = 0.09;
% sessionId = 201781515724; % off in

% load('/Users/sam/analysis/cellData/101917Ac1.mat')
% sessionId = '20171019132525';

% load('/Users/sam/analysis/cellData/110917Ac8.mat') % big ex in
% sessionId = 1;

% load('/Users/sam/analysis/cellData/011718Ac1.mat')
% sessionId = {'201811712578','2018117131112'};

% load('/Users/sam/analysis/cellData/011718Ac4.mat') % use min response mode to toss noise
% sessionId = {'201811716347','20181171609'};


% load('/Users/sam/analysis/cellData/012418Bc3.mat')
% sessionId = {'2018124161454','201812416623'};

% load('/Users/sam/analysis/cellData/013118Ac24.mat')
% sessionId = {'201813117312','201813117151'};
% timeOffset = .39;


% load('/Users/sam/analysis/cellData/012418Bc2.mat')
% sessionId = {'2018124143353','201812414403'};
% sessionId = {'2018124143353'};
% sessionId = {'201812414403'};


% load('/Users/sam/analysis/cellData/021318Ac10.mat')
% % 201821317324 % -60 and 20
% % 201821317473 % -38 and -5
% % 201821318150 % -75 and 35
% % 2018213181637 % -50 and 10
% sessionId = {'201821317324'};
% timeOffset = .06;

% load('/Users/sam/analysis/cellData/021618Ac8.mat') % good Fmon vclamp offset
% sessionId = {'2018216181428'};
% timeOffset = .06;


% load('/Users/sam/analysis/cellData/021618Ac3.mat') % good Fmon vclamp offset
% sessionId = {'2018216144613'};
% timeOffset = .06;

% load('/Users/sam/analysis/cellData/022118Ac1.mat') % HD1 vclamp offset
% sessionId = {'2018221143242'};
% timeOffset = .03;

% new set:
% load('/Users/sam/analysis/cellData/072419Ac1.mat') % OODS
% sessionId = {'2019724172324'};
% timeOffset = .05;


load('/Users/sam/analysis/cellData/072419Ac1.mat') % OODS
sessionId = {'2019724172324'};
timeOffset = .05;
options.saveFileName = '072419Ac1 OODS';



epochData = cell(1);
ei = 1;
for i = 1:length(cellData.epochs)
    epoch = cellData.epochs(i);
    if ~isnan(timeOffset)
        epoch.attributes('timeOffset') = timeOffset;
    end
    sid = epoch.get('sessionId');
    
    matched = 0;
    
    if iscell(sessionId)
        for a = 1:length(sessionId)
            if strcmp(sid, num2str(sessionId{a}))
                matched = 1;
            end
        end
        
    else 
        
        if sid == sessionId | strcmp(sid, num2str(sessionId))
            matched = 1;
        end
    end
    
    if matched
%         if epoch.get('presentationId') > 2
%             continue
%         end
        sd = ShapeData(epoch, 'offline');
        epochData{ei, 1} = sd;
        ei = 1 + ei;
%         epoch.attributes('timeOffset')

    end
end

if length(epochData{1}) > 0 %#ok<ISMT>
    % analyze shapedata
    analysisData = processShapeData(epochData);
    disp('analysis done');
else
    disp('no epochs found');
    return
end


%% normal plots
figure(10);clf;
plotShapeData(analysisData, 'plotSpatial_mean');
%% 
figure(11);clf;
plotShapeData(analysisData, 'temporalResponses');

%%
% figure(12);clf;
% plotShapeData(analysisData, 'currentVoltage');

%% new plots
% figure(13);clf;
% plotShapeData(analysisData, 'spatialOffset_onOff');
%%
figure(15);clf;
plotShapeData(analysisData, 'responsesByPosition');
%%
% figure(11);clf;
% plotShapeData(analysisData, 'temporalComponents');


%%
figure(17);clf;


plotShapeData(analysisData, 'overlap', options); 

%% save maps

% plotShapeData(analysisData, 'plotSpatial_saveMaps');
