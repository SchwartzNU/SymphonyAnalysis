function rootData = AddCosFit(rootData)
    if strcmp(rootData.ampMode, 'Cell attached')
        beta0 = [33 3 3 3 3];
        beta = nlinfit(rootData.barAngle, rootData.spikeCount_stimInterval_grndBlSubt.mean_c ,@TwoCos,beta0);

        if beta(2) < 0 
            beta(3) = beta(3) + 180;
            beta(2) = -1 * beta(2);
        end

        if beta(4) < 0 
            beta(5) = beta(5) + 180;
            beta(4) = -1 * beta(4);
        end

        if beta(3) < 0
            beta(3) = beta(3) + 180;
        elseif beta(3) > 180
            beta(3) = beta(3) - 180;
        end

        if beta(5) < 0
            beta(5) = beta(5) + 180;
        elseif beta(5) > 180
            beta(5) = beta(5) - 180;
        end


        rootData.spikeCount_stimInterval_grndBlSubt.beta = beta;
    end

    function y = TwoCos(beta,x)

        y = beta(1) + beta(2)*cosd(2*(x + beta(3))) + beta(4)*cosd(4*(x + beta(5)));

    end
end