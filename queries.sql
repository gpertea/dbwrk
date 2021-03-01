-- Get counts by Datasets:
SELECT d.id, d.name, count(*) as num
  from datasets d, exp_rnaseq x 
  WHERE d.id = x.dataset_id
  GROUP BY 1 ORDER BY 2
  
--- to retrieve this as JSON:  
SELECT json_agg(qry) FROM (
select d.id, d.name, count(*) as num
  from datasets d, exp_rnaseq x 
  where d.id = x.dataset_id
  GROUP BY 1 ORDER BY 2) qry
  
-- slightly faster way to do joined aggregations like this:
WITH x AS ( SELECT dataset_id, COUNT(*) as num
	FROM exp_rnaseq	GROUP BY 1 )
SELECT d.id, d.name, num 
  FROM x, datasets d WHERE x.dataset_id=d.id

-- counts of RNA-Seq experiments per region :
SELECT r.id, r.name, COUNT(*) as num 
	  FROM exp_rnaseq x, samples s, regions r
	   WHERE x.s_id = s.id AND s.r_id=r.id
	    ORDER BY 1 GROUP BY 1

--same counts per region, but including ALL regions, including those with 0 rna-seq
SELECT r.id, r.name, COUNT(r_id) as num 
	  FROM exp_rnaseq x
	   JOIN  samples s ON x.s_id=s.id
	   RIGHT OUTER JOIN regions r ON s.r_id=r.id
	   GROUP BY 1 ORDER BY 1


-- get counts per Diagnosis
--SELECT ROW_NUMBER() OVER (ORDER BY dx) as id,
SELECT dx, COUNT(*) 
	  FROM exp_rnaseq x, samples s, subjects p
	   WHERE x.s_id = s.id AND s.subj_id=p.id
	    GROUP BY 1 ORDER by 1
      

-- counts by race
SELECT json_agg(t) FROM
(SELECT ROW_NUMBER() OVER (ORDER BY race) as id, 
  race as name, COUNT(*) as num 
	  FROM exp_rnaseq x, samples s, subjects p
	   WHERE x.s_id = s.id AND s.subj_id=p.id
	    GROUP BY 2) t


-- counts by sex
SELECT json_agg(t) FROM
(SELECT ROW_NUMBER() OVER (ORDER BY sex) as id, 
  sex as name, COUNT(*) as num 
	  FROM exp_rnaseq x, samples s, subjects p
	   WHERE x.s_id = s.id AND s.subj_id=p.id
	    GROUP BY 2) t


------------ more complex filters ------
-- show per region counts for AA and CAUC, Control vs Schizo:
SELECT r.id, r.name, COUNT(r_id) as num 
	  FROM exp_rnaseq x
	   JOIN  samples s ON x.s_id=s.id
	   JOIN subjects p ON p.id=s.subj_id
	   RIGHT OUTER JOIN regions r ON s.r_id=r.id
	   WHERE (race='CAUC' or race='AA') AND dataset_id in (2,3,4,5) AND dx in ('Control','Schizo')
	   GROUP BY 1 ORDER BY 1
