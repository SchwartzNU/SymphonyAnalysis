function  [output] = fliprows(input)
    
    %Swaps rows of an input matrix(m x n) such that
    %output matrix(i,j) = input matrix(m-i+1,j)
    
    [row,col] = size(input);
    output = zeros(row,col);
    for i=1:row
        
        output(i,:) = input(row-i+1,:);
        
    end
end