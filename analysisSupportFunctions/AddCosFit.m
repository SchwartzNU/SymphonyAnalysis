function rootData = AddCosFit(rootData)
    if strcmp(rootData.ampMode, 'Cell attached')
        beta0 = [33 3 3 3 3];
        [beta, R,~,~, MSE] = nlinfit(rootData.barAngle, rootData.spikeCount_stimInterval_grndBlSubt.mean_c ,@TwoCos,beta0);
        
        if beta(2) < 0 
            beta(3) = beta(3) + 90;
            beta(2) = -1 * beta(2);
        end

        if beta(4) < 0 
            beta(5) = beta(5) + 45;
            beta(4) = -1 * beta(4);
        end

%         if beta(3) < 0
%             beta(3) = beta(3) + 180;
%         elseif beta(3) > 180
%             beta(3) = beta(3) - 180;
%         end
% 
%         if beta(5) < 0
%             beta(5) = beta(5) + 180;
%         elseif beta(5) > 180
%             beta(5) = beta(5) - 180;
%         end
        beta(3) = mod(beta(3),180);
        beta(5) = mod(beta(5),90);

        rootData.spikeCount_stimInterval_grndBlSubt.beta = beta;
        
        %Hack Adam 3/6/17
        for J = 1:5
            rootData.spikeCount_stimInterval_grndBlSubt.(['beta',num2str(J)]) = beta(J);
        end;
        %fit quality
        rootData.spikeCount_stimInterval_grndBlSubt.fitMSE = sqrt(MSE)./beta(1);
        rootData.spikeCount_stimInterval_grndBlSubt.fitR2 = sqrt(mean(R.^2))./beta(1);
        rootData.spikeCount_stimInterval_grndBlSubt.fitR1 = mean(abs(R))./beta(1);
        rootData.spikeCount_stimInterval_grndBlSubt.fitR2abs = sqrt(mean(R.^2));
    end

    function y = TwoCos(beta,x)

        y = beta(1) + beta(2)*cosd(2*(x - beta(3))) + beta(4)*cosd(4*(x - beta(5)));

    end
end