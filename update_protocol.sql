UPDATE exp_RNAseq set protocol=':1' WHERE 
s_name=':0' and dataset_id = (select id from datasets where name=':2')
