function Y = slope(X)
    
    %Calculates pairwise slope of line segments from an array of points
    [m,n] = size(X);
    Y = zeros(1,m*(m-1)./2);
    k = 1;
    for i = 1:m-1
        
        for j = 1:n-1
            
            slpx = (X(i,j) - X((i+1):m,j));
            slpy = (X(i,(j+1)) - X((i+1):m,(j+1)));
            Y(k:(k+m-i-1)) = slpy./slpx;
        end
        k = k + (m-i);
    end
end