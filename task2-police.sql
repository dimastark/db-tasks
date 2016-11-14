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

IF OBJECT_ID('_Starkov.Regions', 'U') IS NOT NULL
	DROP TABLE  _Starkov.Regions
GO

CREATE TABLE Regions (
	id	TINYINT,
	name NVARCHAR(30),
	CONSTRAINT PK_region_id PRIMARY KEY (id)
)
GO

IF OBJECT_ID('_Starkov.RCodes', 'U') IS NOT NULL
	DROP TABLE  _Starkov.RCodes
GO

CREATE TABLE RCodes (
	region_id tinyint,
	code tinyint,
	CONSTRAINT PK_regio_id PRIMARY KEY (code),
	CONSTRAINT FK_regio_id FOREIGN KEY (region_id) REFERENCES Regions(id) ON UPDATE CASCADE,
)
GO

IF OBJECT_ID('_Starkov.Colors', 'U') IS NOT NULL
	DROP TABLE  _Starkov.Colors
GO

CREATE TABLE Colors (
	id	TINYINT,
	name NVARCHAR(20),
	CONSTRAINT PK_color_id PRIMARY KEY (id) 
)
GO

IF OBJECT_ID('_Starkov.Marks', 'U') IS NOT NULL
	DROP TABLE  _Starkov.Colors
GO

CREATE TABLE Marks (
	id	TINYINT,
	name NVARCHAR(20),
	CONSTRAINT PK_mark_id PRIMARY KEY (id) 
)
GO

IF OBJECT_ID('_Starkov.Posts', 'U') IS NOT NULL
	DROP TABLE  _Starkov.Posts
GO

CREATE TABLE Posts (
	id			tinyint NOT NULL,
	CONSTRAINT PK_post_id PRIMARY KEY (id),
)
GO
IF OBJECT_ID ( '_Starkov.CorrectNumber', 'F' ) IS NOT NULL   
    DROP FUNCTION _Starkov.CorrectNumber
GO  

CREATE FUNCTION CorrectNumber (@num VARCHAR(30))
RETURNS tinyint
AS
BEGIN
	if (UPPER(@num) like '[АВЕКМНОРСТУХ][0-9][0-9][0-9][АВЕКМНОРСТУХ][АВЕКМНОРСТУХ]' 
		and (UPPER(@num) not like N'%000%'))
		return 1
	return 0
END
GO

IF OBJECT_ID ( '_Starkov.CorrectNumber', 'F' ) IS NOT NULL   
    DROP FUNCTION _Starkov.CorrectNumber
GO  

CREATE FUNCTION CorrectTime (@date DATETIME, @dir VARCHAR(1), @id tinyint)
RETURNS tinyint
AS
BEGIN
	if (EXISTS(SELECT catchtime, direction, auto_id FROM Records 
		WHERE catchtime = @date AND @dir != direction and @id = auto_id
	))
		return 0
	return 1
END
GO

IF OBJECT_ID('_Starkov.Autos', 'U') IS NOT NULL
	DROP TABLE  _Starkov.Autos
GO

CREATE TABLE Autos (
	id			tinyint NOT NULL,
	color_id	tinyint NOT NULL,
	mark_id		tinyint NOT NULL,
	number NVARCHAR(7) NOT NULL,
	rcode tinyint NOT NULL,
	family NVARCHAR(100) NOT NULL,
	--CHECK (dbo.CorrectNumber(number) = 1),
	CONSTRAINT PK_auto_id PRIMARY KEY (id),
	CONSTRAINT FK_regi_id FOREIGN KEY (rcode) REFERENCES RCodes(code) ON UPDATE CASCADE,
	CONSTRAINT FK_color_id FOREIGN KEY (color_id) REFERENCES Colors(id) ON UPDATE CASCADE,
	CONSTRAINT FK_mark_id FOREIGN KEY (mark_id) REFERENCES Marks(id) ON UPDATE CASCADE,
)
GO

IF OBJECT_ID('_Starkov.Records', 'U') IS NOT NULL
	DROP TABLE  _Starkov.Records
GO

CREATE TABLE Records (
	id		tinyint NOT NULL,
	post_id	tinyint	NOT NULL,
	auto_id tinyint NOT NULL,
	catchtime	DATETIME	NOT NULL,
	direction CHAR	NOT NULL,
	CHECK (dbo.CorrectTime(catchtime, direction, auto_id) = 1),
	CHECK (direction = '\' or direction = '/'),
	CONSTRAINT FK_post_id FOREIGN KEY (post_id) REFERENCES Posts(id) ON UPDATE CASCADE,
	CONSTRAINT FK_auto_id FOREIGN KEY (auto_id) REFERENCES Autos(id) ON UPDATE CASCADE,
)
GO

--IF OBJECT_ID ( '_Starkov.on_insert_auto', 'TR' ) IS NOT NULL   
--    DROP FUNCTION _Starkov.on_insert_auto
--GO

--CREATE TRIGGER on_insert_auto ON Autos FOR INSERT AS
--BEGIN
--	if EXISTS (SELECT number, rcode FROM inserted WHERE dbo.CorrectNumber(number, rcode) = 0 OR dbo.CorrectNumber(number, rcode) = 2)
--	BEGIN
--	  PRINT 'Некорректный номер'
--	  ROLLBACK TRANSACTION
--	END
--END
--GO

IF OBJECT_ID ( '_Starkov.on_insert_rec', 'TR' ) IS NOT NULL   
    DROP FUNCTION _Starkov.on_insert_rec
GO

CREATE TRIGGER on_insert_rec ON Records FOR INSERT AS
BEGIN
	if EXISTS (
		SELECT catchtime, direction, auto_id
		FROM inserted WHERE dbo.CorrectTime(catchtime, direction, auto_id) = 0
	)
	BEGIN
	  PRINT 'Некорректная запись'
	  ROLLBACK TRANSACTION
	END
END
GO

IF OBJECT_ID ( '_Starkov.GetRegion', 'F' ) IS NOT NULL   
    DROP FUNCTION _Starkov.GetRegion
GO  



IF OBJECT_ID ( '_Starkov.GetAutoType', 'F' ) IS NOT NULL   
    DROP FUNCTION _Starkov.GetAutoType
GO

CREATE FUNCTION GetAutoType (
					@fromPost tinyint, 
					@toPost tinyint, 
					@fromReg tinyint, 
					@toReg tinyint
)
RETURNS VARCHAR(30)
AS
BEGIN
	if (@fromPost != @toPost AND @fromReg != @toReg)
		RETURN 'Транзитный'
	if (@fromPost = @toPost AND @fromReg != @toReg)
		RETURN 'Иногородний'
	if (@fromReg = 1)
		RETURN 'Местный'
	RETURN 'Прочий'
END
GO

INSERT INTO Regions(id, name) VALUES
(1, N'Свердловская область'),
(2, N'Московская область'),
(3, N'Чукотский автономный округ'),
(4, N'Совнгард'),
(5, N'Какой-то регион')
GO

INSERT INTO RCodes(region_id, code) VALUES
(1, 11), (1, 12), (2, 21), (2, 22),
(3, 31), (3, 32), (4, 41), (4, 42),
(5, 51), (5, 52)
GO

INSERT INTO Colors(id, name) VALUES
(1, N'Красный'),
(2, N'Зеленый'),
(3, N'Синий'),
(4, N'Желтый'),
(5, N'Фиолетовый')
GO

INSERT INTO Marks(id, name) VALUES
(1, N'BMW'),
(2, N'VOLVO'),
(3, N'LADA')
GO

INSERT INTO Posts(id) VALUES
(1),(2),(3),(4),(5)
GO

INSERT INTO Autos (id, color_id, mark_id, number, rcode, family) VALUES
	(1, 1, 1, 'A123АА', 11, N'Аиванов'),
	(2, 1, 2, 'В224АА', 21, N'Биванов'),
	(3, 1, 3, 'С114АА', 31, N'Виванов'),
	(4, 1, 1, 'А213АА', 21, N'Гиванов'),
	(5, 1, 2, 'В124АА', 22, N'Диванов'),
	(6, 2, 3, 'С223АА', 31, N'Живанов'),
	(7, 2, 1, 'А113АА', 51, N'Зиванов'),
	(8, 2, 2, 'В214АА', 52, N'Киванов'),
	(9, 2, 3, 'С123АА', 32, N'Ливанов'),
	(10, 3, 1, 'А214АА', 31, N'Миванов'),
	(11, 3, 2, 'В113АА', 21, N'Ниванов'),
	(12, 3, 3, 'С224АА', 22, N'Пиванов'),
	(13, 3, 1, 'А124АА', 12, N'Риванов'),
	(14, 3, 2, 'В213АА', 22, N'Сиванов'),
	(15, 4, 3, 'С124АА', 11, N'Тиванов'),
	(16, 4, 1, 'А224АА', 42, N'Фиванов'),
	(17, 4, 2, 'Н114АА', 22, N'Хиванов'),
	(18, 4, 3, 'Т223АА', 32, N'Чиванов'),
	(19, 5, 1, 'Х123АА', 31, N'Уиванов'),
	(20, 5, 2, 'Х213АА', 41, N'Еиванов')
	--(21, 5, 2, 'Щ213', 31, N'Неправильнов')
GO

INSERT INTO Records (id, post_id, auto_id, catchtime, direction) VALUES
	(1, 1, 1, N'20120618 10:34:08 AM', N'\'),
	(2, 2, 1, N'20120618 10:34:09 AM', N'/'),
	(3, 2, 2, N'20120618 10:34:08 AM', N'/'),
	(4, 1, 2, N'20120618 10:34:09 AM', N'\'),
	(5, 3, 3, N'20120618 10:34:08 AM', N'\'),
	(6, 4, 3, N'20120618 10:34:09 AM', N'/'),
	(7, 4, 4, N'20120618 10:34:08 AM', N'/'),
	(8, 3, 4, N'20120618 10:34:09 AM', N'\'),
	(9, 5, 5, N'20120618 10:34:08 AM', N'\'),
	(10, 1, 5, N'20120618 10:34:09 AM', N'/'),
	(11, 1, 6, N'20120618 10:34:08 AM', N'/'),
	(12, 1, 6, N'20120618 10:34:09 AM', N'\'),
	(13, 2, 7, N'20120618 10:34:08 AM', N'\'),
	(14, 2, 7, N'20120618 10:34:09 AM', N'/'),
	(15, 3, 8, N'20120618 10:34:08 AM', N'/'),
	(16, 3, 8, N'20120618 10:34:09 AM', N'\'),
	(17, 4, 9, N'20120618 10:34:08 AM', N'\'),
	(18, 5, 9, N'20120618 10:34:09 AM', N'/'),
	(19, 5, 10, N'20120618 10:34:08 AM', N'/'),
	(20, 1, 10, N'20120618 10:34:09 AM', N'\'),
	(21, 2, 11, N'20120618 10:34:08 AM', N'\'),
	(22, 2, 11, N'20120618 10:34:09 AM', N'/'),
	(23, 1, 12, N'20120618 10:34:08 AM', N'/'),
	(24, 2, 12, N'20120618 10:34:09 AM', N'\'),
	(25, 1, 13, N'20120618 10:34:08 AM', N'\'),
	(26, 3, 13, N'20120618 10:34:09 AM', N'/'),
	(27, 1, 14, N'20120618 10:34:08 AM', N'/'),
	(28, 3, 14, N'20120618 10:34:09 AM', N'\'),
	(29, 5, 15, N'20120618 10:34:08 AM', N'/'),
	(30, 1, 15, N'20120618 10:34:09 AM', N'\'),
	(31, 2, 16, N'20120618 10:34:08 AM', N'\'),
	(32, 1, 16, N'20120618 10:34:09 AM', N'/'),
	(33, 2, 17, N'20120618 10:34:08 AM', N'/'),
	(34, 1, 17, N'20120618 10:34:09 AM', N'\'),
	(35, 3, 18, N'20120618 10:34:08 AM', N'\'),
	(36, 3, 18, N'20120618 10:34:09 AM', N'/'),
	(37, 1, 19, N'20120618 10:34:08 AM', N'/'),
	(38, 4, 19, N'20120618 10:34:09 AM', N'\'),
	(39, 5, 20, N'20120618 10:34:08 AM', N'\'),
	(40, 4, 20, N'20120618 10:34:09 AM', N'/')
GO

SELECT a.family as "Владельцы зеленых авто"
FROM Autos a
INNER JOIN Colors c
    ON c.id = a.color_id
WHERE c.name = 'Зеленый'
GO

SELECT a.family as "Владельцы BMW"
FROM Autos a
INNER JOIN Marks m
    ON m.id = a.mark_id
WHERE m.name = 'BMW'
GO

SELECT a.family as "Автовладельцы",
	   r.name as "Регион",
	   a.number as "Номер"
FROM Autos a
INNER JOIN RCodes rc
ON rc.code = a.rcode
INNER JOIN Regions r
ON r.id = rc.region_id
WHERE r.name = 'Какой-то регион'
GO

DECLARE @Temp TABLE
(
   fr_city tinyint,
   to_city tinyint,
   fr_post tinyint,
   to_post tinyint
);

INSERT INTO 
    @Temp
SELECT rr3.region_id,
	   rr1.post_id,
	   rr1.post_id,
	   rr2.post_id
FROM Autos a
JOIN Records rr1
    ON rr1.auto_id = a.id AND rr1.direction = N'\'
JOIN Records rr2
	ON rr2.auto_id = a.id AND rr2.direction = N'/'
JOIN RCodes rr3
	ON rr3.code = a.rcode
GROUP BY a.family, a.number, rr1.post_id, rr2.post_id, rr3.region_id

SELECT dbo.GetAutoType(fr_post, to_post, fr_city, to_city) as 'Тип', COUNT(*) as 'Количество' FROM @Temp
GROUP BY dbo.GetAutoType(fr_post, to_post, fr_city, to_city)
GO

DECLARE @Temp TABLE
(
   auto_id tinyint,
   fr_city tinyint,
   to_city tinyint,
   fr_post tinyint,
   to_post tinyint
);

INSERT INTO 
    @Temp
SELECT a.id,
	   rr3.region_id,
	   rr1.post_id,
	   rr1.post_id,
	   rr2.post_id
FROM Autos a
JOIN Records rr1
    ON rr1.auto_id = a.id AND rr1.direction = N'\'
JOIN Records rr2
	ON rr2.auto_id = a.id AND rr2.direction = N'/'
JOIN RCodes rr3
	ON rr3.code = a.rcode
GROUP BY a.family, a.number, rr1.post_id, rr2.post_id, rr3.region_id, a.id

SELECT a.family as 'Владелец', 
	   a.number + CAST(a.rcode AS VARCHAR) as 'Номер авто',
	   FORMAT (r1.catchtime, 'mm\:hh\:ss', 'ru-RU' ) as 'Время въезда', 
	   FORMAT (r2.catchtime, 'mm\:hh\:ss', 'ru-RU' ) as 'Время выезда',
	   regs.name as 'Родной регион авто'
FROM @Temp t
JOIN Autos a
	ON a.id = t.auto_id
JOIN Records r1
	ON r1.direction = '/' and r1.auto_id = t.auto_id
JOIN Records r2
	ON r2.direction = '\' and r2.auto_id = t.auto_id
JOIN RCodes r
	ON r.code = a.rcode
JOIN Regions regs
	ON r.region_id = regs.id
WHERE dbo.GetAutoType(fr_post, to_post, fr_city, to_city) = 'Местный'
GROUP BY a.family, r1.catchtime, 
         r2.catchtime, fr_post, to_post, 
		 fr_city, to_city, regs.name, a.number,
		 a.rcode
GO