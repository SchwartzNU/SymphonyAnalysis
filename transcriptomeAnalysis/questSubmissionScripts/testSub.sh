#!/bin/bash                                                                     
#MSUB -q normal                                                                 
#MSUB -l walltime=46:00:00                                                      
#MSUB -N test_genomics_generateCombMatrix                                                    
#MSUB -M greg.schwartz@northwestern.edu                                             
#MSUB -l nodes=1:ppn=20                                                         
#MSUB -l partition=quest4                                                       
#MSUB -j oe                                                                     

cd $PBS_O_WORKDIR

module load matlab/r2016a

matlab -nosplash -nodesktop -singleCompThread -r generateCombinationMatrix_par > testLog.txt
# exit                                                                          


