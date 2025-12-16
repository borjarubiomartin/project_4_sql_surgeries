-- ======================
-- Projects SQL surgeries
-- ======================
-- SHOW VARIABLES LIKE 'character_set%';

-- Check health_centres duplicates
SELECT *  
FROM intervencoes_cirurgicas_cleaned_en
WHERE health_centre = 'Instituto PortuguÃªs Oncologia  F. Gentil - Lisboa, E.P.E.'
   OR health_centre = 'Instituto PortuguÃªs Oncologia de Lisboa, EPE';

SELECT *
FROM intervencoes_cirurgicas_cleaned_en
WHERE health_centre = 'Instituto PortuguÃªs Oncologia  F. Gentil - Porto, E.P.E.'
   OR health_centre = 'Instituto PortuguÃªs Oncologia do Porto, EPE';

SELECT *
FROM intervencoes_cirurgicas_cleaned_en
WHERE health_centre = 'Centro Hospitalar do Oeste, EPE'
	OR health_centre = 'Centro Hospitalar do Oeste';
    
SELECT *
FROM intervencoes_cirurgicas_cleaned_en
WHERE health_centre = 'Hospital de Braga, EPE'
	OR health_centre = 'Hospital de Braga, PPP';

-- Standardising health_centres values: recategorise duplicated health_centres with inconsistent names 
-- Turn off safe-updates
SET SQL_SAFE_UPDATES = 0;  
-- Run update
UPDATE intervencoes_cirurgicas_cleaned_en  			
SET health_centre = CASE
    WHEN health_centre IN ('Instituto PortuguÃªs Oncologia  F. Gentil - Lisboa, E.P.E.', 
                           'Instituto PortuguÃªs Oncologia de Lisboa, EPE') 
        THEN 'Instituto Português Oncologia  F. Gentil de Lisboa, EPE'
    WHEN health_centre IN ('Instituto PortuguÃªs Oncologia  F. Gentil - Porto, E.P.E.', 
                           'Instituto PortuguÃªs Oncologia do Porto, EPE') 
        THEN 'Instituto Português Oncologia  F. Gentil do Porto, EPE'
    WHEN health_centre IN ('Centro Hospitalar do Oeste, EPE',
                           'Centro Hospitalar do Oeste') 
        THEN 'Centro Hospitalar do Oeste, EPE'
    WHEN health_centre IN ('Hospital de Braga, EPE', 
                           'Hospital de Braga, PPP') 
        THEN 'Hospital de Braga, EPE/PPP'
	WHEN health_centre IN ('Hospital de Vila Franca de Xira, EPE',
							'Hospital de Vila Franca de Xira, PPP') 
        THEN 'Hospital de Vila Franca de Xira, EPE/PPP'
	WHEN health_centre IN ('Hospital de Loures, EPE',
							'Hospital de Loures, PPP')
		THEN 'Hospital de Loures, EPE/PPP'
    ELSE health_centre
END
WHERE health_centre IN (
    'Instituto PortuguÃªs Oncologia  F. Gentil - Lisboa, E.P.E.',
    'Instituto PortuguÃªs Oncologia de Lisboa, EPE',
    'Instituto PortuguÃªs Oncologia  F. Gentil - Porto, E.P.E.',
    'Instituto PortuguÃªs Oncologia do Porto, EPE',
    'Centro Hospitalar do Oeste, EPE',
    'Centro Hospitalar do Oeste',
    'Hospital de Braga, EPE',
    'Hospital de Braga, PPP',
    'Hospital de Vila Franca de Xira, EPE',
	'Hospital de Vila Franca de Xira, PPP',
    'Hospital de Loures, EPE',
	'Hospital de Loures, PPP'
);
-- Turn safe-updates back on
SET SQL_SAFE_UPDATES = 1;

-- Check table size after standardization  
SELECT COUNT(DISTINCT (health_centre)) FROM intervencoes_cirurgicas_cleaned_en; -- there are 78 health centres in total


-- DROP TABLE IF EXISTS health_data;
-- DROP TABLE IF EXISTS hospitals;

    -- ===============================================
-- 1 Create db
CREATE DATABASE surgeries_database;
USE surgeries_database;

-- 2.1 Create hospitals table
CREATE TABLE hospitals (
    id_health_centre INT AUTO_INCREMENT PRIMARY KEY,
    health_centre VARCHAR(150) NOT NULL,
    region VARCHAR(50)
);

-- 2.2 Create health_data table
CREATE TABLE health_data (
    year INT NOT NULL,
    month INT NOT NULL,
    id_health_centre INT NOT NULL,  -- foreign key
    conventional_surgeries INT, 
    scheduled_surgeries INT,
    ambulatory_surgeries INT,
    urgent_surgeries INT,
    tot_patients_waiting INT,
    patients_normal_waiting_time INT,
    pct_patients_normal_waiting_time FLOAT,
    FOREIGN KEY (id_health_centre) REFERENCES hospitals(id_health_centre)
);

-- 3. Insert data into tables
INSERT INTO hospitals (health_centre, region)
SELECT DISTINCT health_centre, region
FROM intervencoes_cirurgicas_cleaned_en;

INSERT INTO health_data (
    year,
    month,
    id_health_centre,
    conventional_surgeries,
    scheduled_surgeries,
    ambulatory_surgeries,
    urgent_surgeries,
    tot_patients_waiting,
    patients_normal_waiting_time,
    pct_patients_normal_waiting_time
)
SELECT
    i.year,
    i.month,
    h.id_health_centre,
    i.conventional_surgeries,
    i.scheduled_surgeries,
    i.ambulatory_surgeries,
    i.urgent_surgeries,
    w.tot_patients_waiting,
    w.patients_normal_waiting_time,
    w.pct_patients_normal_waiting_time
FROM intervencoes_cirurgicas_cleaned_en i
INNER JOIN inscritos_cleaned_en w
    ON i.health_centre = w.health_centre
    AND i.year = w.year
    AND i.month = w.month
INNER JOIN hospitals h
    ON i.health_centre = h.health_centre
WHERE i.health_centre IS NOT NULL
  AND w.health_centre IS NOT NULL;

-- 4.1 Check table sizes    
SELECT COUNT(*) FROM hospitals;  -- there are 78 health centres in total
SELECT COUNT(*) FROM health_data;  -- there are 3098 observations of waiting time in total after the join
SELECT COUNT(*) FROM intervencoes_cirurgicas_cleaned_en;  -- tot obs. 6447
SELECT COUNT(*) FROM inscritos_cleaned_en;  -- there are 3927 observations of waiting time in total in the original dataset

-- 4.2 Preview first rows 
SELECT * FROM intervencoes_cirurgicas_cleaned_en LIMIT 10;
SELECT * FROM inscritos_cleaned_en LIMIT 10;
SELECT * FROM hospitals
	ORDER BY health_centre;
SELECT * FROM health_data LIMIT 10;

-- 4.3 Check table size after standardization  
SELECT COUNT(*) FROM hospitals;  -- there are 78 health centres in total
SELECT * FROM hospitals
	ORDER BY health_centre;

-- 4.4. Check years and months available
SELECT DISTINCT year FROM health_data ORDER BY year;  -- study period spans from 2018 to 2025
SELECT DISTINCT month FROM health_data ORDER BY month;

-- EDA
-- 5. Summary of hospitals by region
SELECT region,
	COUNT(*) AS num_health_centres,
    ROUND( (COUNT(*) / (SELECT COUNT(*) FROM hospitals) ) * 100, 2) AS pct_hospitals
FROM hospitals
GROUP BY region
ORDER BY num_health_centres DESC;

CREATE VIEW num_health_centres AS  -- created first view  INCORPORAR EN PPT
SELECT region,
	COUNT(*) AS num_hospitals,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM hospitals), 2) AS pct_hospitals
FROM hospitals
GROUP BY region WITH ROLLUP;

-- 6. 
-- total_surgeries = conventional + ambulatory + urgent  INCORPORAR EN PPT
SELECT 
    h.health_centre,

    -- Totals
    SUM(d.conventional_surgeries) AS total_conventional_surgeries,
    SUM(d.ambulatory_surgeries)  AS total_ambulatory_surgeries,
    SUM(d.urgent_surgeries)      AS total_urgent_surgeries,

    -- Scheduled (derived, it is the sum of conventional + ambulatory
    SUM(d.conventional_surgeries) 
        + SUM(d.ambulatory_surgeries) AS total_scheduled_surgeries,

    -- Correct total surgeries (NO double counting)
    (SUM(d.conventional_surgeries)
     + SUM(d.ambulatory_surgeries)
     + SUM(d.urgent_surgeries)) AS total_surgeries,

    -- Percentages relative to total_surgeries
    ROUND(SUM(d.conventional_surgeries) /
        (SUM(d.conventional_surgeries)
         + SUM(d.ambulatory_surgeries)
         + SUM(d.urgent_surgeries)) * 100, 2) AS pct_conventional,

    ROUND(SUM(d.ambulatory_surgeries) /
        (SUM(d.conventional_surgeries)
         + SUM(d.ambulatory_surgeries)
         + SUM(d.urgent_surgeries)) * 100, 2) AS pct_ambulatory,

    ROUND(SUM(d.urgent_surgeries) /
        (SUM(d.conventional_surgeries)
         + SUM(d.ambulatory_surgeries)
         + SUM(d.urgent_surgeries)) * 100, 2) AS pct_urgent

FROM hospitals h
JOIN health_data d 
    ON h.id_health_centre = d.id_health_centre

GROUP BY h.health_centre
ORDER BY h.health_centre;

-- CREATE VAR over_max_waiting_time  ADIOCIONAR EN EL PPT
SET SQL_SAFE_UPDATES = 0;
ALTER TABLE health_data
ADD COLUMN over_max_waiting_time INT;
UPDATE health_data
SET over_max_waiting_time =
    CASE
        WHEN tot_patients_waiting IS NULL THEN NULL
        WHEN patients_normal_waiting_time IS NULL THEN NULL
        ELSE tot_patients_waiting - patients_normal_waiting_time
    END;
SET SQL_SAFE_UPDATES = 1;
-- Visualise the updated tab inscritos_cleaned_en
CREATE VIEW health_data_general AS
SELECT id_health_centre, tot_patients_waiting, patients_normal_waiting_time, over_max_waiting_time
FROM health_data
LIMIT 20;

-- Calculate % of patients with waiting time over the normal limit
ALTER TABLE health_data
ADD COLUMN pct_over_max_waiting_time DECIMAL(6,2);
SET SQL_SAFE_UPDATES = 0;
UPDATE health_data
SET pct_over_max_waiting_time =
	CASE
        WHEN tot_patients_waiting IS NULL THEN NULL
        WHEN patients_normal_waiting_time IS NULL THEN NULL
        ELSE (over_max_waiting_time / tot_patients_waiting) * 100
    END;
SET SQL_SAFE_UPDATES = 1;
-- Visualise the updated tab health_data
CREATE VIEW health_data_general AS  -- created second view  INCORPORAR EN PPT
SELECT
	d.id_health_centre,
    d.tot_patients_waiting,
    d.patients_normal_waiting_time,
    d.pct_patients_normal_waiting_time,
    d.over_max_waiting_time,
    d.pct_over_max_waiting_time,
    h.health_centre
FROM health_data d
INNER JOIN hospitals h
    ON d.id_health_centre = h.id_health_centre;

-- USE PEARSON R STATISTIC TO ASSESS CORRELATION BETWEEN: pct_over_max_waiting_time   dep var 
-- and  scheduled_surgeries indep var
SELECT
    ROUND(
        (
            (COUNT(*) * SUM(scheduled_surgeries * pct_over_max_waiting_time)) -
            (SUM(scheduled_surgeries) * SUM(pct_over_max_waiting_time))
        ) /
        SQRT(
            (COUNT(*) * SUM(scheduled_surgeries * scheduled_surgeries) -
             SUM(scheduled_surgeries) * SUM(scheduled_surgeries))
            *
            (COUNT(*) * SUM(pct_over_max_waiting_time * pct_over_max_waiting_time) -
             SUM(pct_over_max_waiting_time) * SUM(pct_over_max_waiting_time))
        )
    , 2) AS pearson_r
FROM health_data;

  
  -- using over_max_waiting_time as dep var (not used in the final scatter plot visualization for ppt)
-- 
SELECT
    ROUND(
        (
            (COUNT(*) * SUM(scheduled_surgeries * over_max_waiting_time)) -
            (SUM(scheduled_surgeries) * SUM(over_max_waiting_time))
        ) /
        SQRT(
            (COUNT(*) * SUM(scheduled_surgeries * scheduled_surgeries) -
             SUM(scheduled_surgeries) * SUM(scheduled_surgeries))
            *
            (COUNT(*) * SUM(over_max_waiting_time * over_max_waiting_time) -
             SUM(over_max_waiting_time) * SUM(over_max_waiting_time))
        )
    , 2) AS pearson_r
FROM health_data;

SET SQL_SAFE_UPDATES = 0;
ALTER TABLE health_data
ADD COLUMN health_centre_performance VARCHAR(20);
UPDATE health_data
SET health_centre_performance =
    CASE
        WHEN pct_over_max_waiting_time <= 20 THEN 'EXITOSO (<= 20)'
        WHEN pct_over_max_waiting_time > 20 AND pct_over_max_waiting_time < 40 THEN 'ACEPTABLE (< 40)'
        WHEN pct_over_max_waiting_time >= 40 AND pct_over_max_waiting_time < 60 THEN 'ATENCION (< 60)'
        WHEN pct_over_max_waiting_time >= 60 AND pct_over_max_waiting_time < 80 THEN 'CRITICO (< 80)'
        WHEN pct_over_max_waiting_time >= 80 THEN 'SOS (>= 80)'
        ELSE NULL
    END
    WHERE pct_over_max_waiting_time IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;

-- This view uses the year average of pct_over_max_waiting_time for each health centre
CREATE VIEW health_centre_performance2 AS
SELECT 
    d.year,
    h.health_centre,
    AVG(d.pct_over_max_waiting_time) AS avg_pct_over_max_waiting_time,
    CASE
        WHEN AVG(d.pct_over_max_waiting_time) <= 20 THEN 'EXITOSO (<= 20)'
        WHEN AVG(d.pct_over_max_waiting_time) > 20 AND AVG(d.pct_over_max_waiting_time) < 40 THEN 'ACEPTABLE (< 40)'
        WHEN AVG(d.pct_over_max_waiting_time) >= 40 AND AVG(d.pct_over_max_waiting_time) < 60 THEN 'ATENCION (< 60)'
        WHEN AVG(d.pct_over_max_waiting_time) >= 60 AND AVG(d.pct_over_max_waiting_time) < 80 THEN 'CRITICO (< 80)'
        WHEN AVG(d.pct_over_max_waiting_time) >= 80 THEN 'SOS (>= 80)'
        ELSE NULL
    END AS performance
FROM health_data d
INNER JOIN hospitals h 
    ON d.id_health_centre = h.id_health_centre
WHERE d.pct_over_max_waiting_time IS NOT NULL
GROUP BY h.health_centre, d.year
ORDER BY avg_pct_over_max_waiting_time DESC;



CREATE VIEW health_centre_performance3 AS
SELECT 
    d.year,
    d.id_health_centre,
    h.health_centre,
    d.pct_over_max_waiting_time,
    CASE
        WHEN d.pct_over_max_waiting_time <= 20 THEN 'EXITOSO (<= 20)'
        WHEN d.pct_over_max_waiting_time > 20 AND d.pct_over_max_waiting_time < 40 THEN 'ACEPTABLE (< 40)'
        WHEN d.pct_over_max_waiting_time >= 40 AND d.pct_over_max_waiting_time < 60 THEN 'ATENCION (< 60)'
        WHEN d.pct_over_max_waiting_time >= 60 AND d.pct_over_max_waiting_time < 80 THEN 'CRITICO (< 80)'
        WHEN d.pct_over_max_waiting_time >= 80 THEN 'SOS (>= 80)'
        ELSE NULL
    END AS performance_dec2024
FROM health_data d
INNER JOIN hospitals h 
    ON d.id_health_centre = h.id_health_centre
WHERE d.year = 2024
	AND d.month = 12
	AND d.scheduled_surgeries IS NOT NULL
	AND d.pct_over_max_waiting_time IS NOT NULL
ORDER BY pct_over_max_waiting_time DESC;

-- Categories of performance: 'EXITOSO (<= 20)'; > 20 AND < 40 'ACEPTABLE' ; >= 40 AND < 60 : 'ATENCION' ; >= 60 AND < 80 : 'CRITICO ; >= 80 : 'SOS'
CREATE VIEW health_centre_performance4 AS
SELECT 
    d.year,
    d.month,
    d.id_health_centre,
    h.health_centre,
    d.pct_over_max_waiting_time,
    CASE
        WHEN d.pct_over_max_waiting_time <= 20 THEN 'EXITOSO'
        WHEN d.pct_over_max_waiting_time > 20 AND d.pct_over_max_waiting_time < 40 THEN 'ACEPTABLE'
        WHEN d.pct_over_max_waiting_time >= 40 AND d.pct_over_max_waiting_time < 60 THEN 'ATENCION'
        WHEN d.pct_over_max_waiting_time >= 60 AND d.pct_over_max_waiting_time < 80 THEN 'CRITICO'
        WHEN d.pct_over_max_waiting_time >= 80 THEN 'SOS'
        ELSE NULL
    END AS performance_dec2024_2018
FROM health_data d
INNER JOIN hospitals h 
    ON d.id_health_centre = h.id_health_centre
WHERE d.month = 12
	AND d.scheduled_surgeries IS NOT NULL
	AND d.pct_over_max_waiting_time IS NOT NULL
ORDER BY d.year, d.id_health_centre, pct_over_max_waiting_time DESC;