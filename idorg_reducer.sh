#!/bin/sh                                                                    

# Calling sequence
# $ qsub -v cfgfile=/path/to/config.yaml /path/to/script.R

## set name of script                                                           
#PBS -N ben-idorg_reducer                                           

## send the environment variables
#PBS -V
#PBS -q route                                                                   
#PBS -l walltime=192:00:00                            
#PBS -l select=1:ncpus=8:mem=256GB    

# log options (in addition to logging by script)                                                            
#PBS -e /mnt/storage/data/edna/mednaTaxaRef/egrey                                                   
#PBS -o /mnt/storage/data/edna/mednaTaxaRef/egrey                                                     

# mail options
#PBS -m bea
#PBS -M btupper@bigelow.org

## access resources
module use /mod/bigelow
module load R   
       
CODEPATH=$(head -n 1 ~/.referee)
cd $CODEPATH     
Rscript ${CODEPATH}/idorg_reducer.R ${cfgfile}
