function save_nNOS_network(allLines,connOut,dir)

if ~exist(dir,'dir')
    error('Directory does not exist.');
end
olddir=pwd;
cd(dir);
for n=1:numel(allLines)
    fname=sprintf('%.4d.dat',n);
    f=fopen(fname,'w');
    fprintf(f,'%f %f %f %f\n',allLines{n}');
    fclose(f);
end

f=fopen('junc.dat','w');
%for n=1:size(connOut,1) %wow....
    fprintf(f,'%d %d %d %d %f %f\n',connOut');
%end
fclose(f);

cd(olddir);