function [ typeList ] = decisionTree_test_currCell( testSet_CR, testSet_LS, testSet_MB, testSet_SMS )

load("curr_crossValModels_191024.mat");
typeList = cell(height(testSet_CR), 2);

for currCell_LS =  1:height(testSet_LS)
    
    % Check the currCell's index in ALL FOUR tables and assign
    % if it does not exist in any of the four tables, go to next cell.
    
    % LS index is currCell
    currCellName = cell2mat(testSet_LS.cellName(currCell_LS));
    typeList{currCell_LS,1} = currCellName;
    
    % 1 - CR - All / (1B SBC) & (2 Non-SBC)
    
    currCell_CR = find(strcmp(testSet_CR.cellName, currCellName));
    if isempty(currCell_CR)
        cellType = 'unclassified: missing CR';
        
    else
        
        avgCrossValModels_1 = decisionTree_avgCrossValModels( crossValModel_1, testSet_CR, ...
            'full_negContrast', 'full_posContrast', currCell_CR);
        
        if avgCrossValModels_1 == 1
            
            % 1b - LS - (1 All SBC) / (* sSBC) & (* bSBC)
            avgCrossValModels_1b = decisionTree_avgCrossValModels( crossValModel_1b, testSet_LS, ...
                'afterstim_maxHz', 'ONSET_peakTransientHz', currCell_LS);
            
            if avgCrossValModels_1b == 1
                cellType = 'SBC sustained';
            else
                cellType = 'SBC bursty';
            end
            
        else
            
            % 2 - (1 All non-SBC) / (3 ON+OO) & (6 OFF)
            
            currCell_SMS = find(strcmp(testSet_SMS.cellName, currCellName));
            if isempty(currCell_SMS)
                cellType = 'unclassified: missing SMS';
            else
                
                %
                %START POLARITY
                %
                
                avgCrossValModels_2 = decisionTree_avgCrossValModels( crossValModel_2, testSet_SMS, ...
                    'maxONResponse_spikesBaselineSubtracted', 'maxOFFresponse_ONOFFRatio', currCell_SMS);
                if avgCrossValModels_2 == 1
                    
                    % 6 OFF
                    avgCrossValModels_6 = decisionTree_avgCrossValModels( crossValModel_6, testSet_LS, ...
                        'baseline_firing', 'afterstim_maxHz', currCell_LS);
                    if avgCrossValModels_6 == 1
                        
                        % 6b OFF alpha
                        avgCrossValModels_6b = decisionTree_avgCrossValModels( crossValModel_6b, testSet_LS, ...
                            'baseline_firing', 'afterstim_maxHz', currCell_LS);
                        if avgCrossValModels_6b == 1
                            cellType = 'OFF sustained alpha';
                        else
                            cellType = 'OFF transient alpha';
                        end
                        
                    else
                        
                        % 7 OFF nonalphas
                        avgCrossValModels_7 = decisionTree_avgCrossValModels( crossValModel_7, testSet_LS, ...
                            'baseline_firing', 'afterstim_maxHz', currCell_LS);
                        if avgCrossValModels_7 == 1
                            cellType = 'OFF OS';
                        else
                            
                            % 8 OFF transient / 8b OFF T very T & (* OFF T MeRF)
                            avgCrossValModels_8 = decisionTree_avgCrossValModels( crossValModel_8, testSet_LS, ...
                                'OFFSET_duration', 'OFFSET_spikes', currCell_LS);
                            if avgCrossValModels_8 == 1
                                cellType = 'OFF transient shelf';
                            else
                                
                                %8b - (* OFF T T & * F-mini OFF)
                                avgCrossValModels_8b = decisionTree_avgCrossValModels( crossValModel_8b, testSet_LS, ...
                                    'OFFSET_spikes', 'afterstim_maxHz', currCell_LS);
                                if avgCrossValModels_8b == 1
                                    cellType = 'OFF transient transient';
                                else
                                    cellType = 'F-mini OFF';
                                end
                                
                            end
                        end
                        
                    end
                    
                % END OF OFF CELLS
                % BEGIN THE ON AND OO...
                else
                    %...NOW!
                    % 3 ON + OO / (4 ON+OO DS) & (5 ON+OO nonDS)
                    
                    currCell_MB = find(strcmp(testSet_MB.cellName, currCellName));
                    if isempty(currCell_MB)
                        cellType = 'unclassified: missing MB';
                        
                    else
                        avgCrossValModels_3 = decisionTree_avgCrossValModels( crossValModel_3, testSet_MB, ...
                            'DSI', 'dumbDSI', currCell_MB);
                        
                        if avgCrossValModels_3 == 1
                            % 4 DS / (* ON DS) & (* OO DS)
                            avgCrossValModels_4 = decisionTree_avgCrossValModels( crossValModel_4, testSet_LS, ...
                                'ONSET_peakTransientHz', 'ONSET_latencyToMax', currCell_LS);
                            
                            if avgCrossValModels_4 == 1
                                cellType = 'ON DS';
                            else
                                cellType = 'ON-OFF DS';
                            end
                            
                        else
                            % 5 (3 ON+OO nonDS) / (9 Reactive) & (13 Persistent)
                            avgCrossValModels_5 = decisionTree_avgCrossValModels( crossValModel_5, testSet_LS, ...
                                'ONSET_duration', 'ONSET_maxHz', currCell_LS);
                            
                            if avgCrossValModels_5 == 1
                                % 9 - Reactive / (10 SMOO Others) (* HD1) (* ON T MeRF)
                                avgCrossValModels_9 = decisionTree_avgCrossValModels( crossValModel_9, testSet_SMS, ...
                                    'ON_suppression_by600um', 'maxONresponse_spikes', currCell_SMS);
                                
                                if avgCrossValModels_9 == 1
                                    cellType = 'HD1';
                                    
                                else
                                    % 9b
                                    avgCrossValModels_9b = decisionTree_avgCrossValModels( crossValModel_9b, testSet_SMS, ...
                                        'ON_suppression_by600um', 'maxONresponse_spikes', currCell_SMS);
                                    
                                    if avgCrossValModels_9b == 1
                                        cellType = 'ON transient trumpet';
                                    else
                                        
                                        %10 - (9 SMOO others) / (11 SMOO others) & (* HD2)
                                        avgCrossValModels_10 = decisionTree_avgCrossValModels( crossValModel_10, testSet_SMS, ...
                                            'maxOFFresponse_spikes', 'maxONresponse_spotSize', currCell_SMS);
                                        
                                        if avgCrossValModels_10 == 1
                                            cellType = 'HD2';
                                        else
                                            
                                            %11 - (10 SMOO others) / (12 SMOO others) & (* UHD)
                                            avgCrossValModels_11 = decisionTree_avgCrossValModels( crossValModel_11, testSet_SMS, ...
                                                'ON_suppression_by600um', 'maxONresponse_ONOFFRatio', currCell_SMS);
                                            
                                            if avgCrossValModels_11 == 1
                                                cellType = 'UHD';
                                            else
                                                
                                                %12 - (11 SMOO others) / (* ON T SmRF) & (* F-mini ON)
                                                avgCrossValModels_12 = decisionTree_avgCrossValModels( crossValModel_12, testSet_SMS, ...
                                                    'ON_suppression_by600um', 'maxONresponse_ONOFFRatio', currCell_SMS);
                                                
                                                if avgCrossValModels_12 == 1
                                                    cellType = 'ON transient slide';
                                                else
                                                    cellType = 'F-mini ON';
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                
                                
                                %13 (5 ON Persistent) / (14 Late) & (15 Early)
                                avgCrossValModels_13 = decisionTree_avgCrossValModels( crossValModel_13, testSet_LS, ...
                                    'ONSET_latencyToMax', 'stimInt_spikes', currCell_LS);
                                
                                if avgCrossValModels_13 == 1
                                    % 15 - (13 Early) / (16 Low suppression) & (17 High suppression)
                                    
                                    avgCrossValModels_15 = decisionTree_avgCrossValModels( crossValModel_13, testSet_SMS, ...
                                        'ON_suppression_by1200um', 'ON_suppression_by600um', currCell_SMS);
                                    
                                    if avgCrossValModels_15 == 1
                                        %16 - (15 Low suppression) / (* ON alpha) & (* M2)
                                        
                                        avgCrossValModels_16 = decisionTree_avgCrossValModels( crossValModel_16, testSet_SMS, ...
                                            'maxONresponse_spikes', 'maxONresponse_spotSize', currCell_SMS);
                                        
                                        if avgCrossValModels_16 == 1
                                            cellType = 'M2';
                                        else
                                            cellType = 'ON alpha';
                                            
                                        end
                                        
                                    else
                                        %17 - (15 High suppression) / (18 Stong response) & (* 915)
                                        avgCrossValModels_17 = decisionTree_avgCrossValModels( crossValModel_17, testSet_LS, ...
                                            'ONSET_duration', 'stimInt_spikes', currCell_LS);
                                        
                                        if avgCrossValModels_17 == 1
                                            cellType = '915';
                                        else
                                            %18 - (17 Strong response) / (* ON bursty) & (* PixON)
                                             avgCrossValModels_18 = decisionTree_avgCrossValModels( crossValModel_18, testSet_LS, ...
                                            'afterStim_spikes', 'stimInt_spikes', currCell_LS);
                                            if avgCrossValModels_18 == 1
                                                cellType = 'ON bursty';
                                            else
                                                cellType = 'PixON';
                                            end
                                        end
                                    end
                                else 
                                        % 14 - (13 Late) / (* LED) & (* ON D)
                                        avgCrossValModels_14 = decisionTree_avgCrossValModels( crossValModel_14, testSet_LS, ...
                                            'afterstim_maxHz', 'afterStim_spikes_baselineSubtracted', currCell_LS);
                                        
                                        if avgCrossValModels_14 == 1
                                            cellType = 'ON delayed';
                                        else
                                            cellType = 'LED';
                                        end
                                end
                            end
                        end
                    end
                end
            end  
        end
    end
    typeList{currCell_LS,2} = cellType;
end
