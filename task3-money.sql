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

if object_id('_Starkov.Currencies', 'U') is not null
	drop table  _Starkov.Currencies
go

create table Currencies (
	id		tinyint,
	code	varchar(3),
	constraint uniq_curr_name unique(code),
	constraint pk_currency_id primary key (id)
)
go

insert into Currencies(id, code) values
(1, 'USD'), (2, 'RUB'), (3, 'EUR'), (4, 'JPY') --, (5, 'UAN')
go

if object_id('_Starkov.CurrencyExchange', 'U') is not null
	drop table  _Starkov.CurrencyExchange
go

create table CurrencyExchange (
	id_sell		tinyint,
	id_recv		tinyint,
	exchange	smallmoney,
	check (id_sell != id_recv or exchange=1),
	constraint uniq_exchn unique(id_sell, id_recv),
	constraint fk_sell_id foreign key (id_sell) references Currencies(id),
	constraint fk_recv_id foreign key (id_recv) references Currencies(id)
)
go

insert into CurrencyExchange(id_sell, id_recv, exchange) values
(1, 1, 1),		(1, 2, 64.9013), (1, 3, 0.9439), (1, 4, 113.2246),-- (1, 5, 6.9162),
(2, 1, 0.0154),	(2, 2, 1),		 (2, 3, 0.0145), (2, 4, 1.7445),--   (2, 5, 0.1065),
(3, 1, 1.0593), (3, 2, 68.75),	 (3, 3, 1),		 (3, 4, 119.9388),-- (3, 5, 7.3264),
(4, 1, 0.0088), (4, 2, 0.5732),	 (4, 3, 0.0083), (4, 4, 1)--,		   (4, 5, 0.0611),
--(5, 1, 0.1445), (5, 2, 9.3838),  (5, 3, 0.1364), (5, 4, 16.3706)  (5, 5, 1)
go


if object_id('_Starkov.Moneys', 'U') is not null
	drop table  _Starkov.Moneys
go

create table Moneys (
	currency_id	tinyint,
	currency_count float,
	check (currency_count > 0),
	constraint fk_money_id FOREIGN KEY (currency_id) references Currencies(id) on update cascade,
)
go

if object_id( '_Starkov.CostIn', 'F' ) is not null   
    drop function _Starkov.CostIn
go

create function CostIn(@currency varchar(3))
returns money as
begin
	declare @ret money;  
    select @ret = sum(e.exchange * m.currency_count)  
    from Moneys m
	inner join Currencies c
	on c.code = @currency
	inner join CurrencyExchange e
	on e.id_sell = m.currency_id and e.id_recv = c.id
	return @ret
end
go

if object_id( '_Starkov.CurrencyId', 'F' ) is not null   
    drop function _Starkov.CurrencyId
go

create function CurrencyId(@currency varchar(3))
returns tinyint as
begin
	declare @ret tinyint
    select @ret = id  
    from Currencies
	where code=@currency
	return @ret
end
go

if object_id( '_Starkov.CurrencyId', 'F' ) is not null   
    drop function _Starkov.CurrencyId
go

create function CurrencyCode(@currency tinyint)
returns varchar(3) as
begin
	declare @ret varchar(3)
    select @ret = code
    from Currencies
	where id=@currency
	return @ret
end
go

if object_id( '_Starkov.GetMoney', 'F' ) is not null   
    drop function _Starkov.GetMoney
go

create function GetMoney(@currency varchar(3))
returns money as
begin
	declare @retur money
	declare @ret tinyint
	select @ret = dbo.CurrencyId(@currency)
	select @retur = sum(currency_count)
	from Moneys
	where currency_id=@ret
	return @retur;

end
go

create procedure AddMoney
	@code varchar(3), 
	@count money
as
    declare @ret tinyint
	select @ret = dbo.CurrencyId(@code)
	insert into Moneys(currency_id, currency_count) values (@ret, @count)
go

create procedure RemoveMoney
	@code varchar(3),
	@count money
as
    declare @ret tinyint
	select @ret = dbo.CurrencyId(@code)
	declare @exc money
	select @exc = dbo.GetMoney(@code)
	declare @got money
	select @got = @exc - @count
	if (@exc > @count)
	begin
		delete from Moneys where currency_id=@ret
		execute AddMoney @code, @got
	end
	else
		raiserror ('Не хватает денег', 10, 1)
go

declare @cols	as nvarchar(max),
		@query	as nvarchar(max)

select @cols = stuff(
	(
		select ',' + quotename(code) 
		from Currencies
		group by id, code
		order by id
		for xml path(''), type
	).value('.', 'nvarchar(max)'), 1, 1, ''
)

set @query = 'SELECT name, ' + @cols + N' 
            from 
            (
              select c.code,
                e.exchange,
                s.code name
              from Currencies s
              left join CurrencyExchange e
                on s.id = e.id_recv
              left join Currencies c
                on e.id_sell = c.id
            ) x
            pivot 
            (
                max(exchange)
                for code in (' + @cols + N')
            ) p
			order by dbo.CurrencyId(name)'

execute (@query)
go

execute dbo.AddMoney 'USD', 200
execute dbo.RemoveMoney 'USD', 200

select distinct dbo.CurrencyCode(currency_id) as "Валюта", dbo.GetMoney(dbo.CurrencyCode(currency_id)) as "Денег в кошельке"
from Moneys
go

print(dbo.CostIn('RUB'))
go

select code as "Валюта", dbo.CostIn(code) as "Денег в этой валюте"
from Currencies
go
