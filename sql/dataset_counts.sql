SELECT d.id, d.name, d.public, COUNT(*) as num 
	  FROM exp_rnaseq e, datasets d
	   WHERE e.dataset_id = d.id
	    GROUP BY 1 ORDER BY 1
/*
--same counts per region, but including ALL regions, including those with 0 rna-seq
SELECT r.id, r.name, COUNT(r_id) as num 
	  FROM exp_rnaseq x
	   JOIN  samples s ON x.s_id=s.id
	   RIGHT OUTER JOIN regions r ON s.r_id=r.id
	   GROUP BY 1 ORDER BY 1
*/