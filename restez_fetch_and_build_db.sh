#!/bin/bash                                                                     

# Call qsub with 
# qsub -v cfgfile=/path/to/cfgfile.yaml /path/to/shell-script.sh

## set name of script                                                           
#PBS -N ben-make-db                                                            

## send the environment variables with job 
#PBS -V

## set the queue                                                                          
#PBS -q route                                                                   

## give job a looong time                       
#PBS -l walltime=200:00:00 

## use one compute node and one cpu (this will default to use 2gb of memory)                                                      
#PBS -l select=1:ncpus=4:mem=128GB    
                                                              
## output files                                  
#PBS -e /mnt/storage/data/edna/refdb/restez                                                           
#PBS -o /mnt/storage/data/edna/refdb/restez                                                      

#PBS -m bea
#PBS -M btupper@bigelow.org


## jobs to submit
module use /mod/bigelow
module load R 
CODEPATH=$(head -n 1 ~/.referee)
                                                              
Rscript $CODEPATH/restez_fetch_and_build_db.R ${cfgfile}
