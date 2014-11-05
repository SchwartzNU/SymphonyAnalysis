classdef MovingBarAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 10000;
        respType = 'Abs Peak';
    end
    
    methods
        function obj = MovingBarAnalysis(cellData, dataSetName, params)
            if nargin < 3
                params.deviceName = 'Amplifier_Ch1';
            end
            if strcmp(params.deviceName, 'Amplifier_Ch1')
                params.ampModeParam = 'ampMode';
                params.holdSignalParam = 'ampHoldSignal';
            else
                params.ampModeParam = 'amp2Mode';
                params.holdSignalParam = 'amp2HoldSignal';
            end            
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': MovingBarAnalysis'];            
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, params.holdSignalParam, 'barLength', 'barWidth', 'distance', 'barSpeed', 'offsetX', 'offsetY'});
            obj = obj.buildCellTree(1, cellData, dataSet, {'barAngle'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            L = length(leafIDs);
            allBaselineSpikes = []; 
            for i=1:L
                curNode = obj.get(leafIDs(i));
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    [baselineSpikes, respUnits, baselineLen] = getEpochResponses(cellData, curNode.epochID, 'Baseline spikes', 'DeviceName', rootData.deviceName, ...
                        'BaselineTime', 250, 'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    [spikes, respUnits, intervalLen] = getEpochResponses(cellData, curNode.epochID, 'Spike count', 'DeviceName', rootData.deviceName, ...
                        'BaselineTime', 250, 'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    N = length(spikes);
                    %'EndTime', 250);
                else
                    [resp, respUnits] = getEpochResponses(cellData, curNode.epochID, obj.respType, 'DeviceName', rootData.deviceName, ...
                        'BaselineTime', 250, 'StartTime', obj.StartTime, 'EndTime', obj.EndTime);
                    N = length(resp);
                end
                
                curNode.N = N;
                
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    allBaselineSpikes = [allBaselineSpikes, baselineSpikes];
                    curNode.spikes = spikes;
                else
                    curNode.resp = resp;
                    curNode.respMean = mean(resp);
                    curNode.respSEM = std(resp)./sqrt(N);
                end
                
                obj = obj.set(leafIDs(i), curNode);
            end
            %subtract baseline
            baselineMean = mean(allBaselineSpikes);
            if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                for i=1:L
                    curNode = obj.get(leafIDs(i));
                    curNode.resp = curNode.spikes - (baselineMean * intervalLen/baselineLen);
                    curNode.respMean = mean(curNode.resp);
                    curNode.respSEM = std(curNode.resp)./sqrt(curNode.N);
                    obj = obj.set(leafIDs(i), curNode);
                end
            end
            
            obj = obj.percolateUp(leafIDs, ...
                'respMean', 'respMean', ...
                'respSEM', 'respSEM', ...
                'N', 'N', ...
                'splitValue', 'barAngle');
            
%             %DSI
%             rootData = obj.get(1);
%             Nangles = length(rootData.barAngle);
%             RDx=0;
%             RDy=0;
%             for j=1:Nangles
%                 RDx=RDx+(rootData.respMean(j)*cos(rootData.barAngle(j)*pi/180));
%                 RDy=RDy+(rootData.respMean(j)*sin(rootData.barAngle(j)*pi/180));
%             end
%             
%                     
%             RDmag = sqrt(RDx^2 + RDy^2);
%             RDang = atand(RDy/RDx);
%             if RDx<0
%               RDang = 180 + RDang;
%             end
% 
%             [PrefD,PrefDind]=max(rootData.respMean);
%             NullDdir=rem(180+rootData.barAngle(PrefDind), 360);
%             NullDind=find(rootData.barAngle==NullDdir);
%             NullD=rootData.respMean(NullDind);
%             DSI=(PrefD-NullD)/(PrefD+NullD);
%             rootData.DSI = DSI;
%             rootData.RDx = RDx;
%             rootData.RDy = RDy;
%             rootData.RDmag = RDmag;
%             rootData.RDang = RDang;
%             obj = obj.set(1, rootData);
%             
%             %OSI
%             ROx=0;
%             ROy=0;
%             for j=1:Nangles
%                 if 0<= (rootData.barAngle(j)*pi/180) <=90
%                    ROx=ROx+(rootData.respMean(j)*cos(rootData.barAngle(j)*pi/180));
%                    ROy=ROy+(rootData.respMean(j)*sin(rootData.barAngle(j)*pi/180));
%                 end
%                 
%                 if 90<= (rootData.barAngle(j)*pi/180) <=180
%                    ROx=ROx+(rootData.respMean(j)*abs(cos(rootData.barAngle(j)*pi/180)));
%                    ROy=ROy+(rootData.respMean(j)*sin(rootData.barAngle(j)*pi/180));
%                 end
%                 
%                 if 180<= (rootData.barAngle(j)*pi/180) <=270
%                    ROx=ROx+(rootData.respMean(j)*abs(cos(rootData.barAngle(j)*pi/180)));
%                    ROy=ROy+(rootData.respMean(j)*abs(sin(rootData.barAngle(j)*pi/180)));
%                 end
%                 
%                 if 270<= (rootData.barAngle(j)*pi/180) <=360
%                    ROx=ROx+(rootData.respMean(j)*cos(rootData.barAngle(j)*pi/180));
%                    ROy=ROy+(rootData.respMean(j)*abs(sin(rootData.barAngle(j)*pi/180)));
%                 end
%                       
%             end
%             
%                     
%             ROmag = sqrt(ROx^2 + ROy^2);
%             ROang1 = atand(ROy/ROx);
%             ROang2 = 180 + ROang1;
% 
%             [PrefO,PrefOind]=max(rootData.respMean);
%             NullOdir=rem(90+rootData.barAngle(PrefOind), 360);
%             NullOind=find(rootData.barAngle==NullOdir);
%             NullO=rootData.respMean(NullOind);
%             OSI=(PrefO-NullO)/(PrefO+NullO);
%             rootData.OSI = OSI;
%             rootData.ROx = ROx;
%             rootData.ROy = ROy;
%             rootData.ROmag = ROmag;
%             rootData.ROang1 = ROang1;
%             rootData.ROang2 = ROang2;
%             obj = obj.set(1, rootData);
            
            %DSI and OSI
            rootData = obj.get(1);
            Nangles = length(rootData.barAngle);
            R=0;
            RDirn=0;
            ROrtn=0;
            
            for j=1:Nangles
                R=R+rootData.respMean(j);
                RDirn = RDirn + (rootData.respMean(j)*exp(sqrt(-1)*rootData.barAngle(j)*pi/180));
                ROrtn = ROrtn + (rootData.respMean(j)*exp(2*sqrt(-1)*rootData.barAngle(j)*pi/180));
            end
           
            DSI = abs(RDirn/R);
            OSI = abs(ROrtn/R);
            DSang = angle(RDirn/R)*180/pi;
            OSang = angle(ROrtn/R)*90/pi;
            
            if DSang < 0
                DSang = 360 + DSang;
            end
            
            if OSang < 0
                OSang = 360 + OSang;
            end
            
            rootData.DSI = DSI;
            rootData.OSI = OSI;
            rootData.DSang = DSang;
            rootData.OSang = OSang;
            obj = obj.set(1, rootData);            
            
        end
    end
    
    methods(Static)
                
        function plotData(node, cellData)
            rootData = node.get(1);
            polarerror(rootData.barAngle.*pi/180, rootData.respMean, rootData.respSEM);
            hold on;
            polar([0 rootData.DSang*pi/180], [0 (100*rootData.DSI)], 'r-');
            polar([0 rootData.OSang*pi/180], [0 (100*rootData.OSI)], 'g-');
            polar([0 ((180 + rootData.OSang)*pi/180)], [0 (100*rootData.OSI)], 'g-');
            title(['DSI = ' num2str(rootData.DSI) ', DSang = ' num2str(rootData.DSang) ...
                ' and OSI = ' num2str(rootData.OSI) ', OSang = ' num2str(rootData.OSang)]);
            hold off;
            %           if strcmp(rootData.ampMode, 'Cell attached')
            %             ylabel('Spike count (norm)');
            %           else
            %             ylabel('Charge (pC)');
            %           end
        end
        
        function plotMeanTraces(node, cellData)
            rootData = node.get(1);
            chInd = node.getchildren(1);
            L = length(chInd);
            ax = axes;
            for i=1:L
                hold(ax, 'on');
                epochInd = node.get(chInd(i)).epochID;
                if strcmp(rootData.(rootData.ampModeParam), 'Cell attached')
                    cellData.plotPSTH(epochInd, 10, rootData.deviceName, ax);
                else
                    cellData.plotMeanData(epochInd, false, [], rootData.deviceName, ax);
                end
            end
            hold(ax, 'off');
        end
        
        
    end
end

