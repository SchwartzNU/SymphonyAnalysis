function y = sanesIndex2index(geneNames, sanesGeneNames, x)
%match gene name
L = length(x);
y = zeros(L,1);

for i=1:L
   temp = strmatch(sanesGeneNames{x(i)}, geneNames, 'exact');
   if ~isempty(temp)
       y(i) = temp;
   end
end
