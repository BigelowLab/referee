#!/bin/sh                                                                    

# Call qsub with 
# qsub -v cfgfile=/path/to/cfgfile.yaml /path/to/idorg-batch.sh

## set name of script                                                           
#PBS -N ben-idorg                                                 

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


#PBS -J 0-4
groups=(invertebrate plant vertebrate mammalian rodent)


## jobs to submit
module use /mod/bigelow
module load R   
       
CODEPATH=$(head -n 1 ~/.referee)
cd $CODEPATH     
Rscript ${CODEPATH}/idorg.R ${cfgfile} ${groups[${PBS_ARRAY_INDEX}]}
