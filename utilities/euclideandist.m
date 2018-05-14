function [dist] = euclideandist(array, point)

dist = zeros(size(array,1),1);

for i = 1:size(array,1)
    
    dist(i) = pdist2(array(i,:),point);
end

end