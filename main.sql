CREATE DATABASE linnKirill
use linnKirill

--1
CREATE TABLE AADRESS (
    aadress_ID  INT IDENTITY(1,1) PRIMARY KEY,
    riik        VARCHAR(100),
    linn        VARCHAR(100),
    tanav       VARCHAR(200),
    maja        VARCHAR(20),
    korter      VARCHAR(20),
    postiindeks VARCHAR(20)
);

CREATE TABLE ISIK (
    isik_ID   INT IDENTITY(1,1) PRIMARY KEY,
    eesnimi   VARCHAR(100),
    perenimi  VARCHAR(100),
    isikukood VARCHAR(20),
    sugu      CHAR(1)
);

CREATE TABLE ELAMINE (
    elamine_ID INT IDENTITY(1,1) PRIMARY KEY,
    isik_ID    INT,
    aadress_ID INT,
    alates     DATE,
    kuni       DATE,
    kommentaar VARCHAR(500)
);

--2
ALTER TABLE ELAMINE ADD CONSTRAINT FK_ISIK    FOREIGN KEY (isik_ID)    REFERENCES ISIK(isik_ID);
ALTER TABLE ELAMINE ADD CONSTRAINT FK_AADRESS FOREIGN KEY (aadress_ID) REFERENCES AADRESS(aadress_ID);

INSERT INTO AADRESS (riik, linn, tanav, maja, korter, postiindeks) VALUES
    ('Eesti',  'Tallinn',  'Narva mnt',       '5',  '12', '10117'),
    ('Eesti',  'Tartu',    'Riia',             '2',  NULL, '51010'),
    ('Eesti',  'Pärnu',    'Rüütli',           '40', '3',  '80010'),
    ('Läti',   'Riia',     'Brīvības iela',    '10', NULL, 'LV-1010'),
    ('Soome',  'Helsinki', 'Mannerheimintie',  '1',  '5',  '00100');

INSERT INTO ISIK (eesnimi, perenimi, isikukood, sugu) VALUES
    ('Mart',   'Tamm', '38001011234', 'M'),
    ('Liis',   'Kask', '49505054321', 'N'),
    ('Jaan',   'Mägi', '37212123456', 'M'),
    ('Anna',   'Lepp', '50010109876', 'N'),
    ('Peeter', 'Lill', '36506061111', 'M');

INSERT INTO ELAMINE (isik_ID, aadress_ID, alates, kuni, kommentaar) VALUES
    (1, 1, '2020-01-01', NULL,         'Põhielukoht'),
    (1, 2, '2018-06-01', '2019-12-31', 'Üliõpilane'),
    (2, 3, '2021-03-15', NULL,         NULL),
    (3, 1, '2019-09-01', '2022-08-31', 'Töö tõttu'),
    (4, 4, '2022-01-10', NULL,         'Välismaal'),
    (5, 5, '2023-05-01', NULL,         'Komandeeringul');

--3
GRANT SELECT, INSERT, UPDATE ON ELAMINE TO isikKirill;
GRANT SELECT, INSERT, UPDATE ON ISIK    TO isikKirill;
GRANT SELECT                 ON AADRESS TO isikKirill;

--4

DENY ALTER       ON ELAMINE TO isikKirill;
DENY ALTER       ON ISIK    TO isikKirill;
DENY ALTER       ON AADRESS TO isikKirill;
DENY CREATE TABLE           TO isikKirill;

--5
CREATE TABLE logi (
    id               INT IDENTITY(1,1) PRIMARY KEY,
    kasutaja         VARCHAR(200),
    kuupaev          DATETIME,
    sisestatudAndmed VARCHAR(MAX)
);

select * from logi
GRANT SELECT, INSERT ON logi TO isikKirill;

--6
CREATE TRIGGER trg_ELAMINE_UPDATE
ON ELAMINE AFTER UPDATE
AS
BEGIN
    INSERT INTO logi (kasutaja, sisestatudAndmed)
    SELECT SYSTEM_USER,
           CONCAT('elamine_ID: ', e.elamine_ID,
                  ', alates: ',   e.alates,
                  ', kuni: ',     e.kuni,
                  ', kommentaar: ', e.kommentaar,
                  ', eesnimi: ',  i.eesnimi,
                  ', perenimi: ', i.perenimi,
                  ', isikukood: ', i.isikukood,
                  ', riik: ',     a.riik,
                  ', linn: ',     a.linn,
                  ', tanav: ',    a.tanav,
                  ', maja: ',     a.maja)
    FROM inserted e
    JOIN ISIK    i ON e.isik_ID    = i.isik_ID
    JOIN AADRESS a ON e.aadress_ID = a.aadress_ID;
END;

--7
CREATE TRIGGER trg_ELAMINE_INSERT
ON ELAMINE AFTER INSERT
AS
BEGIN
    INSERT INTO logi (kasutaja, sisestatudAndmed)
    SELECT SYSTEM_USER,
           CONCAT('elamine_ID: ', e.elamine_ID,
                  ', alates: ',   e.alates,
                  ', kuni: ',     e.kuni,
                  ', kommentaar: ', e.kommentaar,
                  ', eesnimi: ',  i.eesnimi,
                  ', perenimi: ', i.perenimi,
                  ', isikukood: ', i.isikukood,
                  ', riik: ',     a.riik,
                  ', linn: ',     a.linn,
                  ', tanav: ',    a.tanav,
                  ', maja: ',     a.maja)
    FROM inserted e
    JOIN ISIK    i ON e.isik_ID    = i.isik_ID
    JOIN AADRESS a ON e.aadress_ID = a.aadress_ID;
END;


--10

CREATE PROCEDURE usp_IsikuAadressid @isik_ID INT
AS
    SELECT i.eesnimi, i.perenimi, a.riik, a.linn, a.tanav, a.maja, e.alates, e.kuni
    FROM ELAMINE e
    JOIN ISIK    i ON e.isik_ID    = i.isik_ID
    JOIN AADRESS a ON e.aadress_ID = a.aadress_ID
    WHERE e.isik_ID = @isik_ID;

CREATE PROCEDURE usp_LinnaelanikudByLinn @linn VARCHAR(100)
AS
    SELECT i.eesnimi, i.perenimi, a.linn, a.tanav, e.alates, e.kuni
    FROM ELAMINE e
    JOIN ISIK    i ON e.isik_ID    = i.isik_ID
    JOIN AADRESS a ON e.aadress_ID = a.aadress_ID
    WHERE a.linn = @linn;

CREATE PROCEDURE usp_LisaElamine
    @isik_ID INT, @aadress_ID INT, @alates DATE, @kuni DATE = NULL, @kommentaar VARCHAR(500) = NULL
AS
    INSERT INTO ELAMINE (isik_ID, aadress_ID, alates, kuni, kommentaar)
    VALUES (@isik_ID, @aadress_ID, @alates, @kuni, @kommentaar);

EXEC usp_IsikuAadressid 1;
EXEC usp_LinnaelanikudByLinn 'Tallinn';
EXEC usp_LisaElamine 3, 3, '2024-06-01', NULL, 'Lisatud protseduuriga';

--11

CREATE VIEW vw_AktiivsedElamised AS
    SELECT i.eesnimi, i.perenimi, i.isikukood, a.riik, a.linn, a.tanav, a.maja, e.alates
    FROM ELAMINE e
    JOIN ISIK    i ON e.isik_ID    = i.isik_ID
    JOIN AADRESS a ON e.aadress_ID = a.aadress_ID
    WHERE e.kuni IS NULL;
GO

CREATE VIEW vw_AjaloolineElamumine AS
    SELECT i.eesnimi, i.perenimi, a.riik, a.linn, e.alates, e.kuni,
           DATEDIFF(DAY, e.alates, e.kuni) AS paevadeArv
    FROM ELAMINE e
    JOIN ISIK    i ON e.isik_ID    = i.isik_ID
    JOIN AADRESS a ON e.aadress_ID = a.aadress_ID
    WHERE e.kuni IS NOT NULL;
GO

CREATE VIEW vw_RiikideStatistika AS
    SELECT a.riik, a.linn, COUNT(DISTINCT e.isik_ID) AS elanikkeArv
    FROM ELAMINE e
    JOIN ISIK    i ON e.isik_ID    = i.isik_ID
    JOIN AADRESS a ON e.aadress_ID = a.aadress_ID
    WHERE e.kuni IS NULL
    GROUP BY a.riik, a.linn;
GO

 
SELECT * FROM vw_AktiivsedElamised;
SELECT * FROM vw_AjaloolineElamumine;
SELECT * FROM vw_RiikideStatistika;


--12 

CREATE TABLE isik_audit (
    audit_id     INT IDENTITY(1,1) PRIMARY KEY,
    kasutaja     VARCHAR(200),
    muutmise_aeg DATETIME,
    isik_ID      INT,
    vana_eesnimi VARCHAR(100),
    uus_eesnimi  VARCHAR(100),
    vana_perenimi VARCHAR(100),
    uus_perenimi  VARCHAR(100)
);



CREATE TRIGGER trg_ISIK_AUDIT
ON ISIK AFTER UPDATE
AS
BEGIN
    INSERT INTO isik_audit (kasutaja, isik_ID, vana_eesnimi, uus_eesnimi, vana_perenimi, uus_perenimi)
    SELECT SYSTEM_USER, d.isik_ID, d.eesnimi, i.eesnimi, d.perenimi, i.perenimi
    FROM deleted d
    JOIN inserted i ON d.isik_ID = i.isik_ID;
END;



UPDATE ISIK SET eesnimi = 'Martti' WHERE isik_ID = 1;
SELECT * FROM isik_audit;
