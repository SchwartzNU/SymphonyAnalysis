#!/bin/bash                                                                     
#MSUB -q normal                                                                 
#MSUB -l walltime=46:00:00                                                      
#MSUB -N findSelectiveGenePairs_pVal                                                  
#MSUB -M greg.schwartz@northwestern.edu                                             
#MSUB -l nodes=1:ppn=20                                                         
#MSUB -l partition=quest4                                                       
#MSUB -j oe                                                                     

cd $PBS_O_WORKDIR

module load matlab/r2016a

matlab -nosplash -nodesktop -singleCompThread -r fullSelectiveExpressionMatrix_pairs_par > log_findSelectiveGenePairs_logRatio.txt
# exit                