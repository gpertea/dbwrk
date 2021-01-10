-- Table: public.subjects
-- DROP TABLE public.subjects;

CREATE TYPE subjRace AS
 ENUM ('AA','AS', 'CAUC', 'HISP', 'Other');

CREATE TYPE subjSex AS
 ENUM ('M','F', 'O');

CREATE TYPE subjDx AS
 ENUM ('Control', 'Schizo', 'Bipolar', 'MDD', 'PTSD', 'Other');

CREATE TABLE subjects (
    id serial PRIMARY KEY, -- internal unique subject identifier
    brnum varchar(24), -- BrNum or other unique subject identifier
    age real NOT NULL,
    sex subjSex,
    race subjRace,
    dx subjDx,
    age_death real,
    xdata text -- additional info if available
);

CREATE UNIQUE INDEX idx_subj_brnum ON subjects (brnum);
CREATE INDEX idx_subj_sex ON subjects (sex);
CREATE INDEX idx_subj_race ON subjects (race);
CREATE INDEX idx_subj_dx ON subjects (dx);
CREATE INDEX idx_subj_age ON subjects (age);

-- ======================================================== --

-- Table: samples
CREATE TYPE sampleRegion AS
 ENUM ('Amygdala', 'BasoAmyg', 'Caudate', 'dACC', 'DentateGyrus', 'DLPFC', 
 'Habenula', 'HIPPO', 'MedialAmyg', 'mPFC', 'NAc', 'sACC');

CREATE TABLE samples (
    id serial PRIMARY KEY, -- internal unique sample identifier
    num integer,  -- RNum/DNum
    subj_id integer NOT NULL REFERENCES subjects (id),
    region sampleRegion NOT NULL,
    sdate date -- sample date?
);

CREATE INDEX idx_samples_num ON samples (num);
CREATE INDEX idx_samples_subj ON samples (subj_id);
CREATE INDEX idx_samples_region ON samples (region);

-- Table: exp_RNASeq 
-- RNA-Seq experimental data

CREATE TABLE datasets (
    id serial PRIMARY KEY,
    name varchar(64),
    info text
);

CREATE UNIQUE INDEX idx_datasets_name ON datasets (name);

CREATE TYPE RnaSeqProtocol AS 
 ENUM ('PolyA', 'RiboZeroGold', 'RiboZeroHMR');

CREATE TABLE exp_RNASeq (
    id serial PRIMARY KEY,
    s_id integer NOT NULL REFERENCES samples (id),
    rnum int,
    sample_id varchar(64),  -- as seen in SAMPLE_ID column in RSE
    dataset_id smallint, -- experiment group / dataset / project
    protocol RnaSeqProtocol, 
    pr_date date, -- processing date
    RIN numeric(3,1),
    g_set_id int,
    g_data real[],
    t_set_id int,
    t_data real[],
    e_set_id int,
    e_data real[],
    j_set_id int , -- to feature_sets.id
    j_data real[],
    numReads int NOT NULL,
    numMapped int NOT NULL,
    numUnmapped int NOT NULL,
    mitoMapped int  NOT NULL,
    totalMapped int  NOT NULL,
    overallMapRate real NOT NULL,
    concordMapRate real NOT NULL,
    mitoRate real  NOT NULL,
    rRNA_rate real  NOT NULL,
    totalAssignedGene real,
    bamFile varchar
);

CREATE INDEX idx_expRNASeq_sid on exp_RNASeq (s_id);
CREATE INDEX idx_expRNASeq_rnum on exp_RNASeq (rnum);
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
CREATE INDEX idx_g_ensid on genes (ensembleid);
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
--    new_gene_id int, -- ?
    chr varchar(24) NOT NULL,
    strand char(1),
    cstart int  NOT NULL,
    cend int  NOT NULL,
    bin int,
    crange int4range,
    inGencode boolean,
    inGencodeStart boolean,
    inGencodeEnd boolean,
    transcripts integer[], -- list of transcripts.id having this exon
    Class jxClass,
    isFusion boolean
);

CREATE INDEX idx_j_range on junctions USING GIST (crange);
CREATE INDEX idx_j_chr on junctions (chr);
CREATE INDEX idx_j_bin on junctions (bin);
CREATE INDEX idx_j_start on junctions (cstart);
CREATE INDEX idx_j_end on junctions (cend);

