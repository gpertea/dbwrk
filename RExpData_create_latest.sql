
-- Table: subjects
CREATE TABLE subjects (
    id serial PRIMARY KEY,
    BrNum smallint NOT NULL,
    Age numeric(5,2) NOT NULL,
    Sex character NOT NULL,
    Race varchar(4),
    Dx varchar(25)
);

CREATE INDEX idx_subj_brnum ON subjects (BrNum);
CREATE INDEX idx_subj_sex ON subjects (Sex);
CREATE INDEX idx_subj_race ON subjects (Race);
CREATE INDEX idx_subj_dx ON subjects (Dx);

-- Table: samples
CREATE TABLE samples (
    id serial PRIMARY KEY,
    Num integer NOT NULL,  
    Region varchar(30) NOT NULL,
    subj_id integer NOT NULL REFERENCES subjects (id),
    cr_date date,
    pr_date date,
    exp_type varchar(30)  NOT NULL,
    exp_id integer NOT NULL
);

CREATE INDEX idx_samples_subj ON samples (subj_id);
CREATE INDEX idx_samples_region ON samples (Region);
CREATE INDEX idx_samples_num ON samples (Num);
CREATE UNIQUE INDEX idx_sample_expdata ON samples (exp_type, exp_id)


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

CREATE TYPE featureStatus AS
 ENUM ('KNOWN', 'NOVEL');
 
CREATE TABLE genes (
    id serial PRIMARY KEY,
    chr varchar(24)  NOT NULL,
    strand char(1),
    cstart int  NOT NULL,
    cend int  NOT NULL,
    bin int,
    crange int4range,
    gencodeID varchar(24),
    ensemblID varchar(24),
    havanaID varchar(24),
    gene_type varchar(42),
    Symbol varchar(42),
    EntrezID int,
    Class geneClass,
    transcripts integer[] -- transcripts (id)
);


-- Table: transcripts

CREATE TYPE txSource AS 
  ENUM ('HAVANA', 'ENSEMBL', 'REFSEQ', 'UCSC');

CREATE TABLE transcripts (
    id serial PRIMARY KEY,
    ref_set smallint  NOT NULL,
    gene_id int  NOT NULL REFERENCES genes (id),
    gencodeID varchar(24),
    havanaID varchar(24), -- havana_transcript
    chr varchar(24)  NOT NULL,
    strand char(1),
    cstart int  NOT NULL,
    cend int  NOT NULL,
    bin int,
    crange int4range,
    source txSource,
    tx_type varchar(42),
    tx_status featureStatus,
    tx_level smallint,
    tx_name varchar(24), --like gene Symbol but with a number added
    tx_support_level smallint,
    tx_tag varchar(42),
    tx_ont varchar(24),
    prot_id varchar(24),
    ccds_id varchar(24),
    exons integer[],
    jx integer[]
);

-- Table: exons
CREATE TABLE exons (
    id serial PRIMARY KEY,
    gene_id int,
    chr varchar(24)  NOT NULL,
    strand char(1),
    cstart int  NOT NULL,
    cend int  NOT NULL,
    bin int,
    crange int4range,
    transcripts integer[] NOT NULL,
);

CREATE INDEX idx_exons_gid ON exons (gene_id);
CREATE INDEX idx_exons_chr ON exons (chr);

-- Table: junctions

CREATE TYPE jxClass AS 
 ENUM ('Novel', 'AltStartEnd', 'InGen', 'ExonSkip');

CREATE TABLE junctions (
    id serial PRIMARY KEY,
    gene_id int,
    new_gene_id int,
    chr varchar(24) NOT NULL,
    strand char(1),
    cstart int  NOT NULL,
    cend int  NOT NULL,
    bin int,
    crange int4range,
    inGencodeStart boolean,
    inGencodeEnd boolean,
    transcripts integer[],
    class jxClass,
    isFusion boolean
);

CREATE INDEX idx_jx_range on junctions USING GIST (crange);
CREATE INDEX idx_jx_chr on junctions (chr);
CREATE INDEX idx_jx_bin on junctions (bin);
CREATE INDEX idx_jx_start on junctions (cstart);
CREATE INDEX idx_jx_start on junctions (cend);

-- Table: rnaseq_exp
CREATE TABLE RNAseq_exp (
    id serial PRIMARY KEY,
    grp varchar(12)  NOT NULL,
    protocol varchar(12)  NOT NULL,
    sample_id integer NOT NULL,
    RIN numeric(3,1)  NOT NULL,
    seq_sample_ids varchar[]  NOT NULL,
    trimmed boolean  NOT NULL,
    gene_set_id int,
    gene_data real[],
    tx_set_id int,
    tx_data real[],
    exon_set_id int,
    exon_data real[],
    jx_set_id int NOT NULL,
    jx_data real[] NOT NULL,
    bamFile varchar  NOT NULL,
    numReads int NOT NULL,
    numMapped int NOT NULL,
    numUnmapped int NOT NULL,
    overallMapRate real NOT NULL,
    concordMapRate real NOT NULL,
    totalMapped int  NOT NULL,
    mitoMapped int  NOT NULL,
    mitoRate real  NOT NULL,
    rRNA_rate real  NOT NULL,
    totalAssignedGene real
);

-- Table: rnaseq_exp_qc
CREATE TABLE rnaseq_exp_qc (
    rnaseq_exp_id int  NOT NULL,
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
    Adapter88_R2 real[]  NOT NULL,
    CONSTRAINT PK_rnaseq_exp PRIMARY KEY (rnaseq_exp_id)
);

