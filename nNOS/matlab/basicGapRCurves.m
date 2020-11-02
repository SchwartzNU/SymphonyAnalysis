cellDir = 'BowtieSlice';
rg = [1e50 1e10 1e5 1e3 1e1];
midCell = 21;
clear A B
for i = 1:5
    f = fopen(sprintf('%s/gap%d.rinput',cellDir,i));
    A(:,i) = fscanf(f,'%f');
    fclose(f);
    f = fopen(sprintf('%s/gap%d.cc',cellDir,i));
    B(:,i) = fscanf(f,'%f');
    fclose(f);
end