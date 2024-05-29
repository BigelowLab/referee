#!/bin/sh                                                                    



## set name of script                                                           
#PBS -N ben-taxizer                                                 

## send the environment variables with job 
#PBS -V
#PBS -q route                                                                   
#PBS -l walltime=192:00:00                            
#PBS -l select=1:ncpus=4:mem=64GB    
                                                              
#PBS -e /mnt/storage/data/edna/mednaTaxaRef/egrey                                                   
#PBS -o /mnt/storage/data/edna/mednaTaxaRef/egrey                                                     

#PBS -m bea
#PBS -M btupper@bigelow.org

## jobs to submit
module use /mod/bigelow
module load R   
       
CODEPATH=$(head -n 1 ~/.referee)
cd $CODEPATH     
Rscript ${CODEPATH}/idorg_reducer.R ${config}
