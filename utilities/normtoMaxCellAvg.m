function [respMean,respErr,normResp] = normtoMaxCellAvg(Data)
    
    %normalizes responses to max, shift array to max value circularly and
    %averages data across cells
    Data = abs(Data);
    [row,col] = size(Data);     %get the dimensions of Data matrix
    %initiate
    normResp = zeros(row,col);
    for i=1:row
        normResp(i,:) = Data(i,:)./max(Data(i,:));     %normalize to max
        j = find(normResp(i,:)==1);      %find preferred stimulus
        normResp(i,:) = circshift(normResp(i,:),-min(j)+7,2);    %shift max to middle
    end
    respMean = transpose(mean(normResp,1));
    respErr = transpose(std(normResp,1)/sqrt(row));
    
end