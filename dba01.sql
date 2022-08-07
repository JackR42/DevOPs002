create schema s42
go
create table s42.t42(
  ID int primary key
  , Description sysname
)
go
create or alter view s42.v42
as
select * from s42.t42
go
create or alter procedure s42.p42
as
select * from s42.v42
go
insert into s42.t42 values(42, '42')
insert into s42.t42 values(42, '911')
insert into s42.t42 values(42, '1433')
go
exec s42.p42
go
