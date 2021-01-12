UPDATE exp_RNAseq set protocol=':1' WHERE 
rnum=:0 and dataset_id = (select id from datasets where name=':2')
