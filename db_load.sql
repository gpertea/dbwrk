-- Update subregion->region referencing (regions.partof)
-- Amygdala:
UPDATE regions r SET partof=b.id
  FROM (SELECT id FROM regions where name ILIKE 'amygdala') as b
  WHERE fullname LIKE '%_amygdala'
