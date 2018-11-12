function y = index2SanesIndex(geneNames, sanesGeneNames, x)
%match gene name
L = length(x);
y = zeros(L,1);

for i=1:L
   temp = strmatch(geneNames{x(i)}, sanesGeneNames, 'exact');
   if ~isempty(temp)
       y(i) = temp;
   end
end

