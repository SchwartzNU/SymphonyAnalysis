classdef DriftingGratingsPhaseDifferenceAnalysis < AnalysisTree
    %This is not like the other analysis classes. It needs to be run on an
    %already constructed tree with drifting gratings data at two different holding potentials.
    %The tree passed in will be the original analysis tree.
    %This class will rebuild that tree.
    %TreeBrowserGUI should be made to replace its analysisTree object with
    %the new one created by this class.
    properties
        %currently these properties are not used
        StartTime = 0;
        EndTime = 0;
        respType = 'peak'
    end
    
    methods
        function obj = DriftingGratingsPhaseDifferenceAnalysis(treeObj, params)
            %treeObj is previous tree (cell tree, children are analyses)
            posVData=[];
            negVData=[];
            posCount=1;
            negCount=1;
            for i=1:length(treeObj.Node)
                if isfield(treeObj.Node{i},'class')
                    if strcmp(treeObj.Node{i}.class,'DriftingGratingsAnalysis')
                        curNode = treeObj.Node{i};
                        if strcmp(curNode.ampMode, 'Whole cell')
                            if curNode.ampHoldSignal>0
                                angles=length(treeObj.Node{i+3}.gratingAngle);
                                
                                for j=1:angles
                                    
                                    childNode = treeObj.Node{i+3+j};
                                    posVData(j,:,posCount) = childNode.cycleAvg_y.value;
                                
                                end
                                posCount=posCount+1;
                            
                            else
                                angles=length(treeObj.Node{i+3}.gratingAngle);
                                
                                for j=1:angles
                                    
                                    childNode = treeObj.Node{i+3+j};
                                    negVData(j,:,negCount) = childNode.cycleAvg_y.value;
                                
                                end
                                negCount=negCount+1;
                                
                            end
                            
                        end
                        
                    end
                end
            end
            
            diffVals=[];
            F1amplitude=[];
            k=1;
            combinations=(posCount-1)*(negCount-1);
            m=zeros(1,combinations);
            n=zeros(1,combinations);
            for i=1:posCount-1
                
                for j=1:negCount-1
               
                    diffVals(:,:,k)=posVData(:,:,i) - negVData(:,:,j);
                    k=k+1;
                    m(j)=i;
                    n(j)=j;
                end
                
            end
            
            for i=1:size(diffVals,1)
                
                ft=fft(diffVals(i,:));
                F1amplitude(i,:)=abs(ft(2))/length(ft)*2;
                
            end
            
            time = linspace(0,0.5,length(diffVals));
            minDiff = [];
            chargeT25_neg = zeros(angles,size(diffVals,3));
            chargeT25_pos = zeros(angles,size(diffVals,3));
            currentT25_neg = zeros(angles,size(diffVals,3));
            currentT25_pos = zeros(angles,size(diffVals,3));
            for i=1:size(diffVals,3)
                figure
                title(['Difference between posVNode ' num2str(m(i)) ' and negVNode ' num2str(n(i))]);
                for j=1:angles
                    %minDiff = [minDiff;min(diffVals(j,:,:))];
                    meanSubtData = negVData(j,:,i) - mean(negVData(j,:,i));
                    [minVal,pos] = min(meanSubtData);
                    shift = (length(negVData)/2) - pos;
%                     if shift<0
%                         shift = -shift;
%                     end
                    meanSubtData = circshift(meanSubtData,shift,2);
                    diffValsShift = circshift(diffVals(j,:,i),shift,2);
                    
                    T25_up = getThresCross(meanSubtData, 0.25*minVal, 1);
                    T25_down = getThresCross(meanSubtData, 0.25*minVal, -1);
                    timeDiff_up = T25_up - (length(negVData)/2);
                    timeDiff_down = T25_down - (length(negVData)/2);
                    T25_up = T25_up(timeDiff_up>0);
                    T25_down = T25_down(timeDiff_down<0);
                    [~, prePos] = max(T25_down);
                    [~, postPos] = min(T25_up);
                    intervalT25 = (T25_up(postPos) - T25_down(prePos)) / 10000;
                    chargeT25_neg(j,i) = sum(meanSubtData(T25_down(prePos):T25_up(postPos)))*intervalT25;
                    chargeT25_pos(j,i) = sum(diffValsShift(T25_down(prePos):T25_up(postPos)))*intervalT25;
                    currentT25_neg(j,i) = mean(meanSubtData(T25_down(prePos):T25_up(postPos)));
                    currentT25_pos(j,i) = mean(diffValsShift(T25_down(prePos):T25_up(postPos)));
                    
                    subplot(4,3,j)
                    plot(time,diffVals(j,:,i),'r');
                    hold on
                    plot(time,negVData(j,:,i),'b');
                    xlabel('Time(s)');
                    ylabel('Current(pA)');
                    title(['Grating Angle =', num2str(360*(j-1)/size(diffVals,1))]);
                end
                
            end 
            
%             for i=1:size(diffVals,3)
%                 figure
%                 for j=1:angles
%                     subplot(4,3,j)
%                     grid on
%                     plot(diffVals(j,:,i),negVData(j,:,i));
%                     xlabel('Inhibitory Current(pA)');
%                     ylabel('Gap junction current(pA)');
%                     axis([min(diffVals(j,:,:)) max(diffVals(j,:,:)) min(negVData(j,:,:)) max(negVData(j,:,:))]);
%                     title(['Grating Angle =', num2str(360*(j-1)/size(diffVals,1))]);
%                     %legend('Inhibition','Gap junction');
%                 end
%             end
            
            figure
            gratingAngle = linspace(0,330,12)';
            plot(gratingAngle,chargeT25_neg,'b');
            hold on
            plot(gratingAngle,chargeT25_pos,'r');
            xlabel('Grating Angle (degrees)');
            ylabel('Charge at gapJ minima (fC)');
            legend('Gap Junction','Inhibition');
            
            figure
            plot(gratingAngle,currentT25_neg,'b');
            hold on
            plot(gratingAngle,currentT25_pos,'r')
            xlabel('Grating Angle (degrees)');
            ylabel('Current at gapJ minima (fC)');
            legend('Gap Junction','Inhibition');
            keyboard
        end
    end
end
   