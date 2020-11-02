totalLen = 20000; %of simulated dendrite
GJ_separation = [20 40 80 160 320]; %microns
Iinj = [5:5:100]; %pA
darkResistance = 227; %mOhm
lightResistance = 500; %mOhm

nD = length(GJ_separation);
nI = length(Iinj);

for d=1:nD
    sep = GJ_separation(d);
    p1 = 0.5 - sep/(2*totalLen);
    p2 = 0.5 + sep/(2*totalLen);
    
    for i=1:nI        
        inj = Iinj(i);
        
        fname = ['oneD_out_loop' filesep num2str(sep) 'um_' num2str(inj) 'pA_dark.dat']        
        fid = fopen('params_oneD.txt', 'w');
        fprintf(fid,'%f\t%f\t%f\t%f\t%s\n',p1, p2, inj, darkResistance, fname);
        fclose(fid);
        tic;
        unix('/Applications/NEURON-7.4/nrn/x86_64/bin/nrngui -nogui oneD_cableModel_V2.hoc', '-echo')
        toc;
        
        fname = ['oneD_out_loop' filesep num2str(sep) 'um_' num2str(inj) 'pA_light.dat']        
        fid = fopen('params_oneD.txt', 'w');
        fprintf(fid,'%f\t%f\t%f\t%f\t%s\n',p1, p2, inj, lightResistance, fname);
        fclose(fid);
        tic;
        unix('/Applications/NEURON-7.4/nrn/x86_64/bin/nrngui -nogui oneD_cableModel_V2.hoc', '-echo')
        toc;
        
    end
 
end


