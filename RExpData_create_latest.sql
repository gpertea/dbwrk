
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
    Num integer NOT NULL,  -- RNum/DNum
    Region varchar(30) NOT NULL,
    subj_id integer NOT NULL REFERENCES subjects (id),
    s_date date,
    exp_type varchar(30) NOT NULL, -- points to table
    exp_id integer NOT NULL -- points to id in exp_type table
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
    Symbol varchar(24),
    EntrezID int,
    Class geneClass,
    transcripts integer[] -- transcripts (id)
);

CREATE INDEX idx_g_range on genes USING GIST (crange);
CREATE INDEX idx_g_chr on genes (chr);
CREATE INDEX idx_g_bin on genes (bin);
CREATE INDEX idx_g_start on genes (cstart);
CREATE INDEX idx_g_end on genes (cend);

-- Table: transcripts

CREATE TYPE txSource AS 
  ENUM ('HAVANA', 'ENSEMBL', 'REFSEQ', 'UCSC');

CREATE TYPE featureStatus AS
 ENUM ('KNOWN', 'NOVEL');

--CREATE TYPE txType AS
--  ENUM ('gene', 'transcript', 'exon', 'CDS', 'start_codon', 'stop_codon', 'UTR','Selenocysteine');

CREATE TABLE transcripts (
    id serial PRIMARY KEY,
    ref_set smallint  NOT NULL,
    gene_id int  NOT NULL REFERENCES genes (id),
    gencodeID varchar(24), -- transcript_id, ENS (Gencode)
    havanaID varchar(24), -- havana_transcript
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
    exons integer[], -- list of exons.id 
    jx integer[] -- list of junctions.id
);

CREATE INDEX idx_t_range on transcripts USING GIST (crange);
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
    transcripts integer[] NOT NULL,
);

CREATE INDEX idx_e_gid on exons (gene_id);
CREATE INDEX idx_e_range on exons USING GIST (crange);
CREATE INDEX idx_e_chr on exons (chr);
CREATE INDEX idx_e_bin on exons (bin);
CREATE INDEX idx_e_start on exons (cstart);
CREATE INDEX idx_e_end on exons (cend);


-- Table: junctions

CREATE TYPE jxClass AS 
 ENUM ('Novel', 'AltStartEnd', 'InGen', 'ExonSkip');

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
    transcripts integer[], -- list of transcripts.id
    Class jxClass,
    isFusion boolean
);

CREATE INDEX idx_j_range on junctions USING GIST (crange);
CREATE INDEX idx_j_chr on junctions (chr);
CREATE INDEX idx_j_bin on junctions (bin);
CREATE INDEX idx_j_start on junctions (cstart);
CREATE INDEX idx_j_end on junctions (cend);

-- Table: rnaseq_exp RNA-Seq experimental data

CREATE TYPE RnaSeqProtocol AS 
 ENUM ('PolyA', 'RiboZeroGold', 'RiboZeroHMR');

CREATE TABLE RNAseq_exp (
    id serial PRIMARY KEY,
    grp varchar(12) -- experiment group
    pr_date date, -- processing date
    protocol RnaSeqProtocol  NOT NULL, 
    sample_id integer NOT NULL REFERENCES samples (id),
    RIN numeric(3,1)  NOT NULL,
    seq_sample_ids varchar[]  NOT NULL, -- e.g. R2810_C00JVACXX,R2810_C0J1FACXX
    trimmed boolean NOT NULL,
    gene_set_id int,
    gene_data real[],
    tx_set_id int,
    tx_data real[],
    exon_set_id int,
    exon_data real[],
    jx_set_id int ,
    jx_data real[],
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

CREATE INDEX idx_rnaseqexp_smp on RNAseq_exp (sample_id);

-- Table: rnaseq_exp_qc
CREATE TABLE RNAseq_exp_qc (
    exp_id int PRIMARY KEY REFERENCES RNAseq_exp (id),
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
);

