USE master 
GO

IF EXISTS (
	SELECT	name 
	FROM	sys.databases 
	WHERE	name = N'_Starkov' )
ALTER DATABASE [_Starkov] set single_user with rollback immediate
GO

IF EXISTS (
	SELECT	name 
	FROM	sys.databases 
	WHERE	name = N'_Starkov' )
DROP DATABASE [_Starkov]
GO

CREATE DATABASE [_Starkov]
GO

USE [_Starkov]
GO

IF OBJECT_ID('_Starkov.Meteo', 'U') IS NOT NULL
	DROP TABLE  _Starkov.Meteo
GO

CREATE TABLE Meteo (
	id	TINYINT,
	Name nvarchar(20),
	CONSTRAINT PK_m_id PRIMARY KEY (id) 
)
GO

IF OBJECT_ID('_Starkov.MeasureTypes', 'U') IS NOT NULL
	DROP TABLE  _Starkov.MeasureTypes
GO

CREATE TABLE MeasureTypes (
	id	TINYINT,
	Name nvarchar(20),
	Measure nvarchar(20),
	CONSTRAINT PK_t_id PRIMARY KEY (id) 
)
GO

INSERT INTO Meteo (id, Name) VALUES
(1, N'Yandex meteo'),
(2, N'Google meteo'),
(3, N'Yahoo! meteo')
GO

INSERT INTO MeasureTypes (id, Name, Measure) VALUES
(1, N'Влажность', N'шт'),
(2, N'Температура', N'градусов'),
(3, N'Давление', N'Па')
GO

IF OBJECT_ID('_Starkov.Measures', 'U') IS NOT NULL
	DROP TABLE  _Starkov.Measures
GO

CREATE TABLE Measures (
	Station_id	tinyint	NOT NULL,
	Measure_id	tinyint	NOT NULL,
	CatchTime	DATE	NOT NULL,
	Measure_count tinyint	NOT NULL,
	Value	float	NOT NULL,
	CONSTRAINT FK_m_id FOREIGN KEY (Station_id) REFERENCES Meteo(id) ON UPDATE CASCADE,
	CONSTRAINT FK_t_id FOREIGN KEY (Measure_id) REFERENCES MeasureTypes(id) ON UPDATE CASCADE,
)
GO

INSERT INTO Measures (Station_id, Measure_id, CatchTime, Measure_Count, Value) VALUES
	(1, 1, '20160912', 1, 30),
	(2, 1, '20160912', 1, 25),
	(3, 1, '20160912', 1, 20),
	(1, 2, '20160913', 2, 30),
	(2, 2, '20160913', 2, 20),
	(3, 2, '20160913', 2, 21),
	(1, 3, '20160914', 3, 30),
	(2, 3, '20160914', 3, 32),
	(3, 3, '20160914', 3, 31.1),
	(1, 3, '20160915', 4, 30.2),
	(2, 2, '20160915', 4, 19),
	(3, 1, '20160915', 4, 30),
	(1, 1, '20160912', 1, 32),
	(2, 1, '20160912', 1, 33),
	(3, 1, '20160912', 1, 34),
	(1, 2, '20160913', 2, 36),
	(2, 2, '20160913', 2, 39),
	(3, 2, '20160913', 2, 37),
	(1, 3, '20160914', 3, 30.7),
	(2, 3, '20160914', 3, 30.9),
	(3, 3, '20160914', 3, 30.1),
	(1, 3, '20160915', 4, 30.6),
	(2, 2, '20160915', 4, 19),
	(3, 1, '20160915', 4, 30)
GO

SELECT t.Name as "Тип измерения", 
	   s.Name as "Станция",
	   CONVERT(varchar, m.CatchTime, 106) as "Время измерения",	
	   ROUND(AVG(m.Value*m.Measure_count), 1) as "Среднее", 
	   t.Measure as "Åäèíèöû"
FROM Measures m
INNER JOIN MeasureTypes t
    ON t.id = m.Measure_id
INNER JOIN Meteo s
	ON s.id = m.Station_id
GROUP BY m.CatchTime, t.Name, t.Measure, s.Name
GO

SELECT Value as "Значение"
FROM Measures m
WHERE m.Measure_id = 2
GO

SELECT ROUND(AVG(m.Value), 1) as "Среднее значение"
FROM Measures m
WHERE m.Measure_id = 2
GO
