# referee
Scripts for building reference databases for Maine eDNA project

Here we store **scripts** and ancillary **functions** for building reference databases. **Data** is stored elsewhere.  

All scripts are run with a configuration input - we have chosen YAML as the configuration format. 

Generalized workflow...

  + User inputs a listing list (CSV, binomial name species name)

  + `taxizer` attempts to populate a complete taxonomy with IDs
  
  + `fastah` attempts to building a FASTA file of reference sequences for species with IDs
  
  