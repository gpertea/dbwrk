-- select all exp_rnaseq entries for a specific brain region and Dx


-- Get counts by Datasets:
SELECT d.id, d.name, count(*) as num
  from datasets d, exp_rnaseq x 
  WHERE d.id = x.dataset_id
  GROUP BY 1 ORDER BY 2
-- slightly faster way to do joined aggregations like these:
WITH x AS ( SELECT dataset_id, COUNT(*) as num
	          FROM exp_rnaseq	GROUP BY 1 )
 SELECT d.id, d.name, num 
   FROM x, datasets d WHERE x.dataset_id=d.id

-- show exp sample counts by brain region
--   to add a numeric ID for each result row:
-- SELECT ROW_NUMBER() OVER (ORDER BY dx) as id, 
 SELECT r.name as region, COUNT(*) as num 
	  FROM exp_rnaseq x, samples s, regions r
	   WHERE x.s_id = s.id AND s.r_id=r.id
	    GROUP BY 1

-- show counts by region and dataset (sorted by region)
SELECT r.name, d.name, COUNT(*) as num 
	  FROM exp_rnaseq x, samples s, regions r, datasets d
	   WHERE x.s_id = s.id AND s.r_id=r.id AND x.dataset_id=d.id
	    GROUP BY 1, 2 ORDER BY 1

-- show counts by region and diagnosis (sorted by region, diagnosis)
SELECT r.name, p.dx, COUNT(*) as num 
	  FROM exp_rnaseq x, samples s, regions r, subjects p
	   WHERE x.s_id = s.id AND s.r_id=r.id AND s.subj_id=p.id
	    GROUP BY 1, 2 ORDER BY 1,2

-- show all cases with duplicate RNums and their datasets
WITH dups as (SELECT s_name, COUNT(*) from exp_rnaseq 
           GROUP BY s_name HAVING COUNT(*)>1)
 SELECT x.s_name, x.sample_id, d.name as dataset
   FROM exp_rnaseq x, datasets d, dups 
     WHERE dups.s_name=x.s_name AND d.id=x.dataset_id
       ORDER BY s_name, d.name

--- list all DLPFC RNums with all the phenotype data
SELECT x.s_name, d.name, x.sample_id, r.name, dx, sex, race, age
	  FROM exp_rnaseq x, samples s, regions r, datasets d, subjects p
	   WHERE x.s_id = s.id AND r.name='DLPFC' AND d.id=x.dataset_id
	   AND s.r_id=r.id AND s.subj_id=p.id
	   order by dataset_id
