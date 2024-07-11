#!/bin/sh                                                                    

# Calling sequence
# $ qsub -v cfgfile=/path/to/config.yaml /path/to/script.R

## set name of script                                                           
#PBS -N ben-gb_harvester                                           

## send the environment variables
#PBS -V
#PBS -q route                                                                   
#PBS -l walltime=384:00:00                            
#PBS -l select=1:ncpus=4:mem=128GB    

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
Rscript ${CODEPATH}/gb_harvester_chunk.R ${cfgfile}
