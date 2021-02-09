-- Update subregion->region referencing (regions.partof)
-- Amygdala:
UPDATE regions r SET partof=b.id
  FROM (SELECT id FROM regions where name ILIKE 'amygdala') as b
  WHERE fullname LIKE '%_amygdala'
-- cortex
UPDATE regions r SET partof=b.id
  FROM (SELECT id FROM regions where name = 'Ctx') as b
  WHERE fullname LIKE '%_cortex' AND name != 'Ctx'

-- Checking regions from R data:
-- load reg_tmp table with: data.frame("id"=as.numeric(0), "name"=unique(smp$region))
UPDATE reg_tmp t SET id=r.id FROM regions r 
 WHERE lower(t.name) = lower(r.name) OR 
   lower(t.name)=ANY(alts) OR r.fullname ILIKE t.name || '%'
--check if any regions were not identified properly
 select name from reg_tmp where id=0
