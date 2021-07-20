update exp_rnaseq 
 set bamfile=REPLACE(bamfile,
 '/dcl01/lieber/ajaffe/lab/brainseq_phase3/processed_data/HISAT2_out/',
 '/dcl01/lieber/RNAseq/Datasets/BrainSeq_hg38/Phase3/processed_data/HISAT2_out/')
 where dataset_id=5
 