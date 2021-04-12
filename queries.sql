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

-- say subj_tmp has a list of brnums but missing some entries that are in subjects
-- show the missing entries (as found in subjects table), listing the samples
-- from each of them; also shows how the new publication ID should be generated
with x as (select s.id, brnum, brint, dx from subjects s, dx 
    where s.dx_id=dx.id AND NOT EXISTS (select * from subj_tmp t where s.brint=t.brint))
 SELECT 'S'||trim(to_char(x.id, '00000')) as pub_id, brnum, brint, dx, string_agg(s.name,',') as samples 
 from x, samples s where s.subj_id=x.id GROUP BY x.id, brnum, brint, dx

-- update as needed:

------------ more complex filters ------
-- show per region counts for AA and CAUC, Control vs Schizo:
SELECT r.id, r.name, COUNT(r_id) as num 
	  FROM exp_rnaseq x
	   JOIN  samples s ON x.s_id=s.id
	   JOIN subjects p ON p.id=s.subj_id
	   RIGHT OUTER JOIN regions r ON s.r_id=r.id
	   WHERE (race='CAUC' or race='AA') AND dataset_id in (2,3,4,5) AND dx in ('Control','Schizo')
	   GROUP BY 1 ORDER BY 1

--- extracting regex substring from a field in a query:
SELECT t.name, s.name, x.sample_id, substring(sample_id from '[^_]+_[^_]+') as smp_id, 
 'P'||trim(to_char(p.id, '00000')) as p_id, brnum, brint, dx, sex, race, age, pmi 
  FROM subjects p, dx d, samples s, exp_rnaseq x, datasets t WHERE s.subj_id=p.id 
  AND d.id=p.dx_id AND s.id=x.s_id AND t.id=x.dataset_id
  AND sample_id LIKE 'R%\_%\_%'
  ORDER BY 1

------ fix bamfile field in exp_rnaseq with multiple bam files to only include the directory once,
-------- then add any additional bam files separated by comma 
------------ get a column with array index (1-based) when unnesting:
SELECT x.id, x.s_name, x.sample_id, a.s, a.ix INTO TEMP xupd_tmp 
  FROM datasets d, exp_rnaseq x, unnest(string_to_array(bamfile, ';')) with ORDINALITY a(s, ix)
  WHERE d.id = x.dataset_id AND array_length(string_to_array(bamfile, ';'),1)>1;
-- update for ix > 1
UPDATE xupd_tmp set s=substring(s, '[^/]+$') where ix>1;
-- check if the re-aggregation looks OK:
SELECT id, array_to_string(ARRAY_AGG(s ORDER BY ix),',') AS rebamfile
  FROM xupd_tmp GROUP BY id;
-- update exp_rnaseq accordingly
WITH u as (SELECT id, array_to_string(ARRAY_AGG(s ORDER BY ix),',') as rebamfile
       FROM xupd_tmp GROUP BY id)
  UPDATE exp_rnaseq x set bamfile=rebamfile FROM u where u.id=x.id
-- now double check we don't have any more entries like this
SELECT x.id, x.s_name, x.sample_id, a.s, a.ix
 FROM datasets d, exp_rnaseq x, unnest(string_to_array(bamfile, ';')) with ORDINALITY a(s, ix)
 WHERE d.id = x.dataset_id AND array_length(string_to_array(bamfile, ';'),1)>1;
--
DROP TABLE xupd_tmp;

