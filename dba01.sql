-- Idempotent
/*
if object_id('s42.p42') is not null drop procedure s42.p42
if object_id('s42.v42') is not null drop view  s42.v42
if object_id('s42.t42') is not null drop table s42.t42
if schema_id('s42') is null drop schema s42
*/
--
if schema_id('s42') is null exec sp_executesql N'create schema s42'
go
if object_id('s42.t42') is null
	create table s42.t42(
	ID int primary key
	, Description sysname
	)
go
create or alter view s42.v42 as select * from s42.t42
go
create or alter function s42.f42()
RETURNS TABLE
as
RETURN
	select * from s42.v42
GO
create or alter procedure s42.p42 as select * from s42.f42()
go
if not exists(select 1 from s42.t42 where id=42) insert into s42.t42 values(42, '42')
if not exists(select 1 from s42.t42 where id=911) insert into s42.t42 values(911, '911')
if not exists(select 1 from s42.t42 where id=1433) insert into s42.t42 values(1433, '1433')
go
exec s42.p42
go
