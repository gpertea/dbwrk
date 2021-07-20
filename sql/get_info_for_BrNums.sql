select brnum, dx, p.race, p.sex, p.age, d.name as dataset, 
s.name as rnum,  r.name as region, e.bamfile 
from exp_rnaseq e, datasets d, subjects p, regions r, dx, samples s
where e.s_id = s.id and s.subj_id=p.id and d.id=e.dataset_id 
    and dx_id=dx.id and s.r_id=r.id
    -- and d.name in ('','','')
    and brnum in ('Br5415','Br5485','Br5459','Br5475','Br5888','Br5135','Br5209',
    'Br5398','Br5235','Br5287')