function V = allIndicesPairwise(x,y)
Lx = length(x);
Ly = length(y);
V = zeros(Lx*Ly, 2);

z=1;
for i=1:length(x)
    for j=1:length(y)
        V(z,:) = [x(i) y(j)];
        z=z+1;
    end
end