#!/bin/sh                                                                    



## set name of script                                                           
#PBS -N ben-taxizer                                                 

## send the environment variables with job 
#PBS -V
#PBS -q route                                                                   
#PBS -l walltime=192:00:00                            
#PBS -l select=1:ncpus=4:mem=128GB    
                                                              
## output files placed in output directory in the user vcc’s home directory                                     
#PBS -e /mnt/storage/data/edna/mednaTaxaRef/egrey                                                   
#PBS -o /mnt/storage/data/edna/mednaTaxaRef/egrey                                                     

#PBS -m bea
#PBS -M btupper@bigelow.org

## jobs to submit
module use /mod/bigelow
module load R   
       
CODEPATH=/mnt/storage/data/edna/packages/referee
cd $CODEPATH     
Rscript ${CODEPATH}/idorg.R ${config}
