-- get the json data for React (RNASeq only):
------ large samples table with numeric IDs for dx, region, dataset
WITH w as (SELECT enumsortorder as id, enumlabel AS dx
  FROM pg_enum e
  JOIN pg_type t ON e.enumtypid = t.oid
  WHERE t.typname = 'subjdx')
 SELECT json_agg(j) FROM (SELECT sample_id as id, dataset_id as dset,
       w.id , p.race, p.sex, TRUNC(p.age::NUMERIC, 1) as age, s.r_id as reg 
       FROM  exp_rnaseq x, samples s, subjects p, w
  WHERE s_id=s.id AND s.subj_id=p.id AND p.dx::text=w.dx) j

-- Dx table
select json_agg(j) from (SELECT enumsortorder as id, enumlabel AS dx
  FROM pg_enum e
  JOIN pg_type t ON e.enumtypid = t.oid
  WHERE t.typname = 'subjdx') j

-- datasets
SELECT json_agg(j) FROM (SELECT id, name from DATASETS order by ID) j

-- regions
SELECT json_agg(j) FROM (SELECT id, name FROM regions) j

-------------------------------------------------


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
