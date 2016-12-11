use master 
go

if exists (
	select	name 
	from	sys.databases 
	where	name = N'_Starkov' )
alter database [_Starkov] set single_user with rollback immediate
go

if exists (
	select	name 
	from	sys.databases 
	where	name = N'_Starkov' )
drop database [_Starkov]
go

create database [_Starkov]
go

use [_Starkov]
go

if object_id('_Starkov.Plans', 'U') is not null
	drop table  _Starkov.Plans
go

create table Plans (
	name			varchar(100),
	mounthCost		float,
	minutesCount	float,
	overflowCost	money,
	check (mounthCost >= 0 and minutesCount >= 0 and overflowCost >= 0)
)
go

insert into Plans(name, mounthCost, minutesCount, overflowCost) values
	(N'Без абонентской платы',	0,	10, 1),
	(N'Абонентский 60 – минут', 5,	20, 1),
	(N'Безлимитный',			10,	0,	0),
	(N'Супер-пупер тариф',		0,	0,	2)
go

if object_id( '_Starkov.GetCost', 'F' ) is not null   
    drop function _Starkov.GetCost
go

create function GetCost(@name varchar(100), @count float)
returns float as
begin
	declare @overflow float; declare @plancost float; declare @minuteco float;
    select @overflow = minutesCount from Plans where @name=name
	select @plancost = mounthCost	from Plans where @name=name
	select @minuteco = overflowCost from Plans where @name=name
	if (@count < @overflow) return @plancost
	return @plancost + (@count - @overflow) * @minuteco
end
go

if object_id( '_Starkov.Median', 'F' ) is not null   
    drop function _Starkov.Median
go

create function Median(@name varchar(100), @a float, @b float)
returns float as
begin return (dbo.GetCost(@name, @a) + dbo.GetCost(@name, @b)) / 2 end
go

declare @previous float = 0;
declare @current float = 0;
declare interval_cursor cursor for  
select distinct b.minutesCount + a.mounthCost / b.overflowCost 
from Plans a, Plans b
where b.overflowCost != 0 and b.minutesCount + a.mounthCost / b.overflowCost > 0
order by b.minutesCount + a.mounthCost / b.overflowCost;

open interval_cursor
fetch next from interval_cursor   
into @current

while @@fetch_status = 0  
begin
	declare @min float = 0; declare @minName varchar(100);
	select @min = min(dbo.Median(name, @previous, @current)) from Plans
	select @minName = name from Plans where @min = dbo.Median(name, @previous, @current)
	print(N'РРЅС‚РµСЂРІР°Р»: ' 
			+ convert(varchar(100), @previous, 3) 
			+ ' -> ' 
			+  convert(varchar(100), @current, 3)
			+ ' - ' + @minName
	)
	select @previous = @current;
	fetch next from interval_cursor   
    into @current  
end

close interval_cursor;  
deallocate interval_cursor;
go
