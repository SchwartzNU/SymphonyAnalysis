function [] = runNeuronSims(rootDir)

D = dir(rootDir);
z=1;
for i=1:length(D)
    curName = D(i).name
    if ~strcmp(curName(1), '.');     
        fid = fopen('curFolder.txt', 'w');
        fprintf(fid,'%s\r',[rootDir filesep curName]);
        fclose(fid);
        %pause;
        tic;
        unix('/Applications/NEURON-7.4/nrn/x86_64/bin/nrngui -nogui GapRCurves.hoc', '-echo')
        toc;
        %pause;
        
        z=z+1;
    end
 
end


