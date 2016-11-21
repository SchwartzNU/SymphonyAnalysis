classdef WhiteNoiseIorVAnalysis < AnalysisTree
    properties
        StartTime = 0;
        EndTime = 0;
    end
    
    methods
        function obj = WhiteNoiseIorVAnalysis(cellData, dataSetName, params)
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
            
            nameStr = [cellData.savedFileName ': ' dataSetName ': WhiteNoiseIorVAnalysis'];
            obj = obj.setName(nameStr);
            dataSet = cellData.savedDataSets(dataSetName);
            obj = obj.copyAnalysisParams(params);
            obj = obj.copyParamsFromSampleEpoch(cellData, dataSet, ...
                {'RstarMean', 'RstarIntensity', params.ampModeParam, params.holdSignalParam});
            obj = obj.buildCellTree(1, cellData, dataSet, {'seedIsRepeated'});
        end
        
        function obj = doAnalysis(obj, cellData)
            rootData = obj.get(1);
            leafIDs = obj.findleaves();
            nonRepLeaf = leafIDs(1);
            repLeaf = leafIDs(2);
            
            nonRepNode = obj.get(nonRepLeaf);
            repNode = obj.get(repLeaf);
            
            L = length(nonRepNode.epochID);
            %F_omega = [];
            
            for i=1:L
                
                curEpoch = cellData.epochs(nonRepNode.epochID(i));
                randSeed = curEpoch.get('randSeed');
                
                %generate stimulus
                rng(randSeed);
            
                scaleFactor = curEpoch.get('sampleRate') / 1E3; %ms to samples
                waveVec = ones(1, (curEpoch.get('preTime') + curEpoch.get('stimTime') + curEpoch.get('tailTime') * scaleFactor) .* curEpoch.get('ampHoldSignal'));
                stimPart =  LowPassFilter(randn(1, curEpoch.get('stimTime')*scaleFactor), curEpoch.get('filterFreq'), 1/curEpoch.get('sampleRate'));
                stimPart = curEpoch.get('ampHoldSignal') + curEpoch.get('noiseSD') * stimPart/std(stimPart);
                waveVec(curEpoch.get('preTime')*scaleFactor+1:(curEpoch.get('preTime')+curEpoch.get('stimTime'))*scaleFactor) = stimPart;
                waveVec = waveVec(curEpoch.get('preTime')*scaleFactor+1:(curEpoch.get('preTime')+curEpoch.get('stimTime'))*scaleFactor);
                S_t = waveVec - mean(waveVec);
                
                sampleRate = curEpoch.get('sampleRate');
                stimSamples = round(sampleRate*curEpoch.get('stimTime')/1E3);
                S_omega = fft(S_t); %convert stimulus to frequency space
                dataVec = curEpoch.getData();
                
                %parse data vector
                
                baselinePart = dataVec(1:round(sampleRate*curEpoch.get('preTime')/1E3));
                R_t = dataVec(round(sampleRate*curEpoch.get('preTime')/1E3)+1:round(sampleRate*curEpoch.get('preTime')/1E3)+round(sampleRate*curEpoch.get('stimTime')/1E3));
                R_t = R_t - mean(baselinePart);
                R_omega = fft(R_t-mean(R_t));
                    
                %calculate filter
                F_omega = R_omega.*conj(S_omega');
                %./(S_omega'.*conj(S_omega'));
                %filter_omega = resp_omega./stim_omega';
                %freq_cutoff = 35/(sampleRate/length(R_t));
                %F_omega(1+freq_cutoff:length(F_omega) - freq_cutoff, :) = 0;
            end
            
            %F_omega_avg = mean(F_omega,2); %average filter across epochs
            F_t = real(ifft(F_omega));
            F_t = F_t(1:3000);
            F_t = F_t./max(F_t); %normalize to max
            keyboard
            M = length(repNode.epochID);
            R_rep = [];
            
            for k=1:M
                
                curEpoch = cellData.epochs(nonRepNode.epochID(i));
                sampleRate = curEpoch.get('sampleRate');
                stimSamples = round(sampleRate*curEpoch.get('stimTime')/1E3);
                
                if k==1
                    
                    randSeed = curEpoch.get('randSeed');

                    %generate stimulus
                    rng(randSeed);   
                    nFrames = ceil((curEpoch.get('stimTime')/1000) * (curEpoch.get('patternRate') / curEpoch.get('framesPerStep')));
                    waveVec = randn(1,nFrames);   
                    waveVec = waveVec .* curEpoch.get('noiseSD'); %set SD
                    waveVec = waveVec + curEpoch.get('meanLevel'); %add mean
                    waveVec(waveVec>1) = 1; %clip out of bounds values
                    waveVec(waveVec>curEpoch.get('meanLevel')*2) = curEpoch.get('meanLevel')*2; %clip out of bounds values
                    waveVec(waveVec<0) = 0;
                    S_rep = waveVec - mean(waveVec);
                    S_rep = resample(S_rep, stimSamples, length(S_rep));
                    
                end
                
                dataVec = curEpoch.getData();
                
                %parse data vector
                
                baselinePart = dataVec(1:round(sampleRate*curEpoch.get('preTime')/1E3));
                resp = dataVec(round(sampleRate*curEpoch.get('preTime')/1E3)+1:round(sampleRate*curEpoch.get('preTime')/1E3)+round(sampleRate*curEpoch.get('stimTime')/1E3));
                resp = resp - mean(baselinePart);
                resp = resp - mean(resp);
                R_rep = [R_rep,resp];
                    
            end
            
            R_mean = mean(R_rep,2);
            R_pred = conv(S_rep,F_t);
            R_pred = R_pred(1:length(R_mean));
            figure
            scatter(R_pred,R_mean);
            
        end
    end
    
    methods(Static)
        
        function plotMeanTraces(node, cellData)
            
        end
    end
end