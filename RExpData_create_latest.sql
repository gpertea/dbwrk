-- Table: public.subjects
-- DROP TABLE public.subjects;

CREATE TYPE subjRace AS
 ENUM ('AA','AS', 'CAUC', 'HISP', 'Multi-Racial', 'Other');

CREATE TYPE subjSex AS
 ENUM ('M','F', 'O');

--CREATE TYPE subjDx AS
-- ENUM ('Control', 'Schizo', 'Bipolar', 'MDD', 'PTSD', 'AD', 'BpNOS', 'Other');
-- MDD = Major Depressive Disorder
-- AD = Alzheimer's Dementia
-- BpNOS = Bipolar Not Otherwise Specified
DROP TABLE IF EXISTS dx;

CREATE TABLE dx ( -- Diagnosis table
   id serial PRIMARY KEY, 
   dx varchar(26) NOT NULL, --short name/abbreviation to display
   name varchar(72) -- full name, no abbreviation
);
--CREATE INDEX idx_dx_alts ON dx USING GIN(alts);
INSERT INTO dx (dx, name) VALUES
 ('Control', NULL),
 ('Schizo', 'Schizophrenia'),
 ('MDD', 'Major Depressive Disorder'),
 ('PTSD', 'Post traumatic stress disorder'),
 ('R/O PTSD', 'Rule Out PTSD'),
 ('Autism', NULL),
 ('ADHD', 'Attention deficit hyperactivity disorder'),
 ('Anxiety', NULL),
 ('AD', 'Alzheimer''s Disease'),
 ('preclinicalAD', 'preclinical Alzheimer''s Disease'),
 ('Bipolar', NULL),
 ('BpNOS', 'Bipolar Not Otherwise Specified'),
 ('Dementia', NULL),
 ('ED', 'Eating disorder'),
 ('OCD', 'Obsessive compulsive disorder'),
 ('Alcohol', 'Alcohol dependence'),
 ('Substance', 'Substance dependence'),
 ('Tics', NULL),
 ('Williams', 'Williams'' syndrome'),
 ('Neuro', NULL),
 ('Medical', NULL);


CREATE TABLE subjects (
    id serial PRIMARY KEY, -- internal unique subject identifier (int)
    brnum varchar(24), -- BrNum or other unique alphanumeric identifier
    brint integer, -- for BrNums only the integer (numeric) part
    age numeric(5,2) NOT NULL,
    sex subjSex,
    race subjRace,
    dx_id integer NOT NULL REFERENCES dx (id),
    mod varchar(42), -- manner of death
    pmi numeric(5,1), -- ?
    xdata text -- additional info if/when available
);

CREATE UNIQUE INDEX idx_subj_brnum ON subjects (brnum);
CREATE UNIQUE INDEX idx_subj_bri ON subjects (brint);
CREATE INDEX idx_subj_sex ON subjects (sex);
CREATE INDEX idx_subj_race ON subjects (race);
CREATE INDEX idx_subj_dx ON subjects (dx_id);
CREATE INDEX idx_subj_age ON subjects (age);

-- ======================================================== --

CREATE TABLE regions (
 id smallserial PRIMARY KEY,
 name varchar(42), -- common abbreviation or name to use for display
 fullname varchar(72), -- full name unless name is not an abbreviation
 alts varchar[],  -- alternate spellings for this region
 partof smallint --references id for subregions,e.g. dentate gyrus is part of hippocampus
);
 
CREATE UNIQUE INDEX idx_regions_n ON regions (name);
CREATE INDEX idx_r_alts ON regions USING GIN(alts);
-- how to test for an alternative spelling/names:
--   SELECT id,name FROM regions WHERE name = 'HIPPO' OR alts @>(ARRAY['HIPPO']) 

CREATE TABLE samples (
    id serial PRIMARY KEY, -- internal unique sample identifier
    name varchar(42) NOT NULL,  -- RNum/DNum/other alphanumeric sample ID in full 
    subj_id integer NOT NULL REFERENCES subjects (id),
    r_id smallint, --REFERENCES regions.id; allow NULLs for now
    sdate date -- sample date?
);

CREATE UNIQUE INDEX idx_samples_num ON samples (name);
CREATE INDEX idx_samples_subj ON samples (subj_id);
CREATE INDEX idx_samples_r ON samples (r_id);

-- Table: exp_RNASeq 
-- RNA-Seq experimental data

CREATE TABLE datasets (
    id serial PRIMARY KEY,
    name varchar(64),
    public boolean,  -- data can be exposed to the public
    restricted boolean, -- LIBD internally restricted
    info text
);

CREATE UNIQUE INDEX idx_datasets_name ON datasets (name);

CREATE TYPE RnaSeqProtocol AS 
 ENUM ('PolyA', 'RiboZeroGold', 'RiboZeroHMR');

CREATE TABLE exp_RNASeq (
     id serial PRIMARY KEY,
     s_id integer NOT NULL REFERENCES samples (id), -- tissue sample ID
     s_name varchar(42), --redundancy check, references samples (name)
     sample_id varchar(240),  -- as in SAMPLE_ID column in RSE
     flags bit(8), -- single reads, qc_fail, non-public, internal restricted,...
     dataset_id smallint, -- experiment group / dataset / project
     protocol RnaSeqProtocol,
     pr_date date, -- processing date
     RIN numeric(3,1),
     g_set_id int, -- feature_sets('g', id)
     g_data real[],
     t_set_id int, -- feature_sets('t', id)
     t_data real[],
     e_set_id int, -- feature_sets('e', id)
     e_data real[],
     j_set_id int, -- feature_sets('j', id)
     j_data real[],
     numReads int,
     numMapped int,
     numUnmapped int,
     mitoMapped int,
     totalMapped int,
     overallMapRate real,
     concordMapRate real,
     mitoRate real,
     rRNA_rate real,
     totalAssignedGene real,
     bamFile text
);

CREATE INDEX idx_expRNASeq_sid on exp_RNASeq (s_id);
CREATE INDEX idx_expRNASeq_sname on exp_RNASeq (s_name);
CREATE INDEX idx_expRNASeq_did on exp_RNASeq (dataset_id);
CREATE INDEX idx_expRNASeq_rin on exp_RNASeq (RIN);
CREATE UNIQUE INDEX idx_rnaseqexp_smp on exp_RNASeq (sample_id);

-- ======================================================== --

-- Table: exp_RNASeq_qc 
-- extra QC / post-processing data 
CREATE TABLE exp_RNASeq_qc (
    exp_id int PRIMARY KEY REFERENCES exp_RNASeq (id),
    FQBasicStats varchar(12)  NOT NULL,
    perBaseQual varchar(12)[]  NOT NULL,
    perSeqQual varchar(12)  NOT NULL,
    perBaseContent varchar(12)  NOT NULL,
    perTileQual varchar(12)[]  NOT NULL,
    GContent varchar(12)[]  NOT NULL,
    NContent varchar(12)[]  NOT NULL,
    SeqLengthDist varchar(12)[]  NOT NULL,
    SeqDuplication varchar(12)[]  NOT NULL,
    OverrepSeqs varchar(12)[]  NOT NULL,
    AdapterContent varchar(12)  NOT NULL,
    KmerContent varchar(12)  NOT NULL,
    SeqLength_R1 smallint  NOT NULL,
    percentGC_R1 smallint[]  NOT NULL,
    phred20_21_R1 numeric(3,1)[]  NOT NULL,
    phred48_49_R1 numeric(3,1)[]  NOT NULL,
    phred76_77_R1 numeric(3,1)[]  NOT NULL,
    phred100_R1 numeric(3,1)[]  NOT NULL,
    phredGT30_R1 real[]  NOT NULL,
    phredGT35_R1 real[]  NOT NULL,
    Adapter50_51_R1 real[]  NOT NULL,
    Adapter70_71_R1 real[]  NOT NULL,
    Adapter88_R1 real[]  NOT NULL,
    SeqLength_R2 smallint  NOT NULL,
    percentGC_R2 smallint[]  NOT NULL,
    phred20_21_R2 numeric(3,1)[]  NOT NULL,
    phred48_49_R2 numeric(3,1)[]  NOT NULL,
    phred76_77_R2 numeric(3,1)[]  NOT NULL,
    phred100_R2 numeric(3,1)[]  NOT NULL,
    phredGT30_R2 real[]  NOT NULL,
    phredGT35_R2 real[]  NOT NULL,
    Adapter50_51_R2 real[]  NOT NULL,
    Adapter70_71_R2 real[]  NOT NULL,
    Adapter88_R2 real[]  NOT NULL
);

-- ======================================================== --

-- Table: feature_sets
-- ftype can be: G (genes), E (exons), J ( junction), T (transcript), 
--               V (genomic variant?), L ( genomic location)
CREATE TABLE feature_sets (
    ftype char NOT NULL,
    id serial,
    f_ids integer[],
    PRIMARY KEY (ftype, id)
);

-- Table: genes
CREATE TYPE geneClass AS 
 ENUM ('InGen', 'Unk');

CREATE TABLE genes (
    id serial PRIMARY KEY,
    g_id varchar(24) NOT NULL,  --gencodeID/rowID in RSE data, or StringTie ID
    chr varchar(24)  NOT NULL,
    strand char(1),
    cstart int  NOT NULL,
    cend int  NOT NULL,
    bin int,
    crange int4range,
    ensemblID varchar(24),
    havanaID varchar(24),
    gene_type varchar(42),
    Symbol varchar(24),
    EntrezID int,
    Class geneClass,
    transcripts integer[] -- transcripts (id)
);

CREATE INDEX idx_g_range on genes USING GIST (crange);
CREATE INDEX idx_g_id on genes (g_id);
CREATE INDEX idx_g_chr on genes (chr);
CREATE INDEX idx_g_bin on genes (bin);
CREATE INDEX idx_g_start on genes (cstart);
CREATE INDEX idx_g_end on genes (cend);

-- Table: transcripts

CREATE TYPE txSource AS 
  ENUM ('HAVANA', 'ENSEMBL', 'REFSEQ', 'UCSC', 'STRG', 'OTHER');

CREATE TYPE featureStatus AS
 ENUM ('KNOWN', 'NOVEL');

--CREATE TYPE txType AS
--  ENUM ('gene', 'transcript', 'exon', 'CDS', 'start_codon', 'stop_codon', 'UTR','Selenocysteine');

CREATE TABLE transcripts (
    id serial PRIMARY KEY,
    t_id varchar(24) NOT NULL, -- transcript_id (also rowID in rowData(rse_transcript))
    gid int NOT NULL REFERENCES genes (id),
    havana_id varchar(24), -- havana_transcript
    chr varchar(24)  NOT NULL,
    strand char(1),
    cstart int  NOT NULL,
    cend int  NOT NULL,
    bin int,
    crange int4range,
    source txSource,
    tx_status featureStatus, -- gene_status in rowData(rse_tx)
    tx_level smallint, -- ? not sure what this means
    tx_name varchar(24), -- like gene Symbol but with a number added
    tx_support_level smallint,
    tx_tag varchar(42), -- tag column
    tx_ont varchar(24), -- ont column
    prot_id varchar(24),
    ccds_id varchar(24),
    r_exons int4range[], -- array of exon ranges, for convenience
    r_cds int4range[], -- array of CDS segments, if it's coding
    exons integer[], -- list of exons.id entries
    jx integer[] -- list of junctions.id
);

CREATE INDEX idx_t_range on transcripts USING GIST (crange);
CREATE INDEX idx_t_tid on transcripts (t_id);
CREATE INDEX idx_t_gid on transcripts (gid);
CREATE INDEX idx_t_havana on transcripts (havana_id);
CREATE INDEX idx_t_chr on transcripts (chr);
CREATE INDEX idx_t_bin on transcripts (bin);
CREATE INDEX idx_t_start on transcripts (cstart);
CREATE INDEX idx_t_end on transcripts (cend);

-- Table: exons
CREATE TABLE exons (
    id serial PRIMARY KEY,
    gene_id int,
    chr varchar(24) NOT NULL,
    strand char(1),
    cstart int  NOT NULL,
    cend int  NOT NULL,
    bin int,
    crange int4range,
    transcripts integer[] NOT NULL
);

CREATE INDEX idx_e_gid on exons (gene_id);
CREATE INDEX idx_e_range on exons USING GIST (crange);
CREATE INDEX idx_e_chr on exons (chr);
CREATE INDEX idx_e_bin on exons (bin);
CREATE INDEX idx_e_start on exons (cstart);
CREATE INDEX idx_e_end on exons (cend);


CREATE TYPE jxClass AS 
 ENUM ('Novel', 'AltStartEnd', 'InGen', 'ExonSkip');

-- Table: junctions

CREATE TABLE junctions (
    id serial PRIMARY KEY,
    gene_id int,
    chr varchar(24) NOT NULL,
    strand char(1),
    cstart int  NOT NULL,
    cend int  NOT NULL,
    bin int,
    crange int4range,
    inGencode boolean,
    inGencodeStart boolean,
    inGencodeEnd boolean,
    transcripts integer[], -- list of transcripts.id having this junction
    Class jxClass,
    isFusion boolean
);

CREATE INDEX idx_j_range on junctions USING GIST (crange);
CREATE INDEX idx_j_chr on junctions (chr);
CREATE INDEX idx_j_bin on junctions (bin);
CREATE INDEX idx_j_start on junctions (cstart);
CREATE INDEX idx_j_end on junctions (cend);

