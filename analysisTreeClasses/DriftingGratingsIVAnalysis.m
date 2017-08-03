classdef DriftingGratingsIVAnalysis < AnalysisTree
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
        function obj = DriftingGratingsIVAnalysis(treeObj, params)
            %treeObj is previous tree (cell tree, children are analyses)
            Data_pref=[];
            Data_null=[];
            Voltages=[];
            
            prompt = 'Enter preferred angle (nearest multiple of 30) ';
            prefang = input(prompt);
            prompt = 'Enter null angle (nearest multiple of 30) ';
            nullang = input(prompt);
            
            % Grab data from analysis tree
            for i=1:length(treeObj.Node)
                if isfield(treeObj.Node{i},'class')
                    if strcmp(treeObj.Node{i}.class,'DriftingGratingsAnalysis')
                        curNode = treeObj.Node{i};
                        if strcmp(curNode.ampMode, 'Whole cell')
                            Voltages = [Voltages; curNode.ampHoldSignal];
                            for j = 1:size(treeObj.Node{i+3}.gratingAngle,2)
                                if treeObj.Node{i+3+j}.splitValue == prefang
                                    Data_pref = [Data_pref; treeObj.Node{i+3+j}.cycleAvg_y.value];
                                end
                                if treeObj.Node{i+3+j}.splitValue == nullang
                                    Data_null = [Data_null; treeObj.Node{i+3+j}.cycleAvg_y.value];
                                end 
                            end
                            temporal_freq = treeObj.Node{i+2}.splitValue;
                                
                        end
                    end
                end
            end
            
            %Sliding window average data
            Data_pref = movmean(Data_pref,50,2);
            Data_null = movmean(Data_null,50,2);
            timepts = 1000 * size(Data_pref,2)/((10/temporal_freq) * 10000); %10kHz sampling frequency
            time_ind = linspace(0,size(Data_pref,2),timepts + 1);
            Curr_pref = [];
            Curr_null = [];
            %Curr_prefang_sem = [];
            %Curr_nullang_sem = [];
            
            % Grab currents for specific time points
            for i = 1:length(Voltages)
                for j = 1:timepts
                    Curr_pref(i,j) = mean(Data_pref(i,time_ind(j)+1:time_ind(j+1)));
                    Curr_null(i,j) = mean(Data_null(i,time_ind(j)+1:time_ind(j+1)));
                    %Curr_prefang_sem(i,j) = std(Data_prefang(i,time_ind(j)+1:time_ind(j+1)))/sqrt(max(time_ind)/timepts);
                    %Curr_nullang_sem(i,j) = std(Data_nullang(i,time_ind(j)+1:time_ind(j+1)))/sqrt(max(time_ind)/timepts);
                    
                end
            end
            
            %Sort Currents and Voltages
            IV_pref = [Voltages,Curr_pref];
            IV_null = [Voltages,Curr_null];
            IV_pref = sortrows(IV_pref);
            IV_null = sortrows(IV_null);
            Voltages = sort(Voltages);
            %Fit IV curves to currents
            Inh_coeff = [0.0105,0.5536]; %Inhibition IV curve linear fit
            GJ_coeff = [0,0.6567]; %Gap junction IV curve linear fit
            %Coeff_matrix = [0.0105,0.5536;0,0.6567]; %Inhibition and gap junction IV curve slopes and intercepts
            Cinh_pref = zeros(1,length(timepts));
            Cinh_null = zeros(1,length(timepts));
            Cgj_pref = zeros(1,length(timepts));
            Cgj_null = zeros(1,length(timepts));
            
            for i = 1:timepts
                
                C_pref = polyfit(Voltages,Curr_pref(:,i),1);
                C_null = polyfit(Voltages,Curr_null(:,i),1);
%                 Pref_weights = Coeff_matrix\C_pref';
%                 Null_weights = Coeff_matrix\C_null';
%                 Cinh_pref(i) = Pref_weights(1);
%                 Cgj_pref(i) = Pref_weights(2);
%                 Cinh_null(i) = Null_weights(1);
%                 Cgj_null(i) = Null_weights(2);
                Cinh_pref(i) = C_pref(1)/Inh_coeff(1);
                Cgj_pref(i) = (C_pref(2) - (Cinh_pref(i)*Inh_coeff(2)))/GJ_coeff(2);
                Cinh_null(i) = C_null(1)/Inh_coeff(1);
                Cgj_null(i) = (C_null(2) - (Cinh_null(i)*Inh_coeff(2)))/GJ_coeff(2);
                
            end
            
            %Plot IV fits
            Inh_pref = ((Inh_coeff(1)*Voltages) + Inh_coeff(2))*Cinh_pref;
            GJ_pref = ((GJ_coeff(1)*Voltages) + GJ_coeff(2))*Cgj_pref;
            Total_pref = Inh_pref + GJ_pref;
            Inh_null = ((Inh_coeff(1)*Voltages) + Inh_coeff(2))*Cinh_null;
            GJ_null = ((GJ_coeff(1)*Voltages) + GJ_coeff(2))*Cgj_null;
            Total_null = Inh_null + GJ_null;
            figure;
            subplot(2,3,1)
            plot(Voltages,Inh_pref(:,25),'r-');
            hold on;
            plot(Voltages,GJ_pref(:,25),'g-');
            plot(Voltages,Total_pref(:,25),'b-');
            plot(Voltages,IV_pref(:,26),'k-');
            hold off;
            title(['Preferred angle at t = ' num2str(25*((size(Data_pref,2))/(10*timepts))) ' ms']);
            subplot(2,3,2)
            plot(Voltages,Inh_null(:,25),'r-');
            hold on;
            plot(Voltages,GJ_null(:,25),'g-');
            plot(Voltages,Total_null(:,25),'b-');
            plot(Voltages,IV_null(:,26),'k-');
            hold off;
            title(['Null angle at t = ' num2str(25*((size(Data_pref,2))/(10*timepts))) ' ms']);
            subplot(2,3,3)
            plot(Voltages,Inh_pref(:,50),'r-');
            hold on;
            plot(Voltages,GJ_pref(:,50),'g-');
            plot(Voltages,Total_pref(:,50),'b-');
            plot(Voltages,IV_pref(:,51),'k-');
            hold off;
            title(['Preferred angle at t = ' num2str(50*((size(Data_pref,2))/(10*timepts))) ' ms']);
            subplot(2,3,4)
            plot(Voltages,Inh_null(:,50),'r-');
            hold on;
            plot(Voltages,GJ_null(:,50),'g-');
            plot(Voltages,Total_null(:,50),'b-');
            plot(Voltages,IV_null(:,51),'k-');
            hold off;
            title(['Null angle at t = ' num2str(50*((size(Data_pref,2))/(10*timepts))) ' ms']);
            subplot(2,3,5)
            plot(Voltages,Inh_pref(:,75),'r-');
            hold on;
            plot(Voltages,GJ_pref(:,75),'g-');
            plot(Voltages,Total_pref(:,75),'b-');
            plot(Voltages,IV_pref(:,76),'k-');
            hold off;
            title(['Preferred angle at t = ' num2str(75*((size(Data_pref,2))/(10*timepts))) ' ms']);
            subplot(2,3,6)
            plot(Voltages,Inh_null(:,75),'r-');
            hold on;
            plot(Voltages,GJ_null(:,75),'g-');
            plot(Voltages,Total_pref(:,75),'b-');
            plot(Voltages,IV_null(:,76),'k-');
            hold off;
            title(['Null angle at t = ' num2str(75*((size(Data_pref,2))/(10*timepts))) ' ms']);
            
            %Plot coefficients
            time = linspace(0,(size(Data_pref,2)/10),timepts+1);
            figure
            plot(time(2:end),Cinh_pref,'r-');
            hold on;
            plot(time(2:end),Cgj_pref,'g-');
            hold off;
            xlabel('Time(ms)');
            ylabel('Weight units');
            title('Preferred angle coefficients');
            legend('Inhibition','Gap Junction');
            figure
            plot(time(2:end),Cinh_null,'r-');
            hold on;
            plot(time(2:end),Cgj_null,'g-');
            hold off
            xlabel('Time(ms)');
            ylabel('Weight units');
            title('Null angle coefficients');
            legend('Inhibition','Gap Junction');
            
        end
    end
end
