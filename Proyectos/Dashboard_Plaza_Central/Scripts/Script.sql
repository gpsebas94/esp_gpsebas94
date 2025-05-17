
/**********************************************************************************************************
***********************************************************************************************************
**************************************** POWER BI REPORTE MENSUAL *****************************************
***********************************************************************************************************
**********************************************************************************************************/
/*
REALIZADO : Juan Sebastian Gonzalez
FECHA: 22 DE JULIO DEL 2021

El siguiente query actualiza las siguientes hojas del Power BI. 
- Funnel Campañas
- Funnel Tipo Comunicación
- Engagement Categoria
- Redenciones

NOTA: Con un F5 se actualiza todo
*/

/*********** DETALLE BASE DE ENVÍO VS VENTAS **************/

-- CRUCE CAMPAÑAS
drop table if exists #CampañasPlazaCentral
	SELECT c.Campañas_id, c.Descripcion DescCampaña, c.CodigoCampaña,
            p.Perfiles_id, p.Descripcion DescPerfil, p.CodigoPerfil,
            cast(ISNULL(M.Fecha, p.Creado) as date) FechaPeriodo, b.Tel_Celular,
            b.BasesDeEnvio_Id, b.Email, b.NoDocumento, b.EsGrupoControl,m.apertura,m.clicksTotales,a.Nombre CategoriaObjetivoEnvio
      INTO #CampañasPlazaCentral
      FROM Campañas.dbo.Campañas c
      LEFT JOIN Campañas.dbo.Perfiles p
        ON c.Campañas_id = p.Campañas_id
      LEFT JOIN Campañas.dbo.BasesDeEnvio b
        ON b.Perfiles_id = p.Perfiles_id
       LEFT JOIN Campañas.dbo.Metricas m
        ON b.BasesDeEnvio_Id = m.BasesDeEnvio_Id
       LEFT JOIN Campañas.dbo.Plataformas pl
        ON p.Plataformas_Id = pl.Plataformas_id
	   LEFT JOIN Campañas.dbo.AliasCampañas a
	    ON a.AliasCampañas_Id = p.AliasCampañas_Id
     WHERE c.Cuentas_Id = 150 

-- CRUCE FACTURAS
drop table if exists #facturasPlazaCentral
	 Select C.NoDocumento,C.Tel_celular,C.Email,FechaInscripcionFactura,t.Nombre Comercio,S.Nombre Subcategoria,r.Nombre Categoria,Facturas_Id,c.ClientesPlazaCentral_Id,F.MontoFactura
	 into #facturasPlazaCentral
	 from  PlazaCentral.dbo.S_Usuarios w
	 left join PlazaCentral.dbo.S_Facturas F
	 on w.Usuarios_Id=F.Usuarios_Id
	 left join PlazaCentral.dbo.ClientesPlazaCentral c
	 ON c.ClientesPlazaCentral_Id = W.ClientesPlazaCentral_Id
	 inner join PlazaCentral.dbo.S_Comercios t
	 on t.Comercios_Id=F.Comercios_Id
	 inner join PlazaCentral.dbo.S_SubCategorias s
	 on s.SubCategorias_Id=t.SubCategorias_Id
	 inner join PlazaCentral.dbo.S_Categorias r
	 on r.Categorias_Id=s.Categorias_id

-- CRUCE FACTURAS Y CAMPAÑAS
drop table if exists #CrucePlazaCentral
SELECT Campañas_id, DescCampaña, Perfiles_id, FechaPeriodo,BasesDeEnvio_Id,a.Apertura,a.ClicksTotales, Email, NoDocumento,DescPerfil,CategoriaObjetivoEnvio,
		ClientesPlazaCentral_Id, Facturas_Id, Comercio,Subcategoria,Categoria,MontoFactura,FechaInscripcionFactura, Dias,  Cruce,  Tel_Celular,
		ROW_NUMBER() over (partition by Facturas_Id order by Dias ) OrdenFacturas
 into #CrucePlazaCentral
from (		
SELECT Campañas_id, DescCampaña, Perfiles_id, FechaPeriodo, BasesDeEnvio_Id,a.Apertura,a.ClicksTotales, a.Email, a.NoDocumento,DescPerfil,CategoriaObjetivoEnvio,
		ClientesPlazaCentral_Id, Facturas_Id,Comercio,Subcategoria,Categoria,MontoFactura, FechaInscripcionFactura, DATEDIFF(DD, FechaPeriodo,FechaInscripcionFactura) Dias, EsGrupoControl, a.Tel_Celular, 
		'NoDoc' Cruce
from #CampañasPlazaCentral a
left join #facturasPlazaCentral v	
on a.NoDocumento = v.NoDocumento -- NODOC
and a.FechaPeriodo <= v.FechaInscripcionFactura  
and DATEDIFF(DD, FechaPeriodo,FechaInscripcionFactura) between 0 and 7 
and (a.Apertura=1 or ClicksTotales=1)
) a 
WHERE NOT EXISTS ( SELECT fACTURAS_ID FROM PlazaCentral.dbo.DetalleBasesdeenvioVentas e 
WHERE e.fACTURAS_ID = A.fACTURAS_ID ) 


-- CREA BK DE TABLA DETALLE BASES DE ENVÍO VS VENTAS
drop table if exists PlazaCentral.dbo.DetalleBasesdeenvioVentas_bk_Power_BI
Select  * 
	INTO PlazaCentral.dbo.DetalleBasesdeenvioVentas_bk_Power_BI
from PlazaCentral.dbo.DetalleBasesdeenvioVentas

-- INSERTAR REGISTROS EN TABLA
INSERT INTO PlazaCentral.dbo.DetalleBasesdeenvioVentas(Campañas_id,DescCampaña,Perfiles_id,FechaPeriodo,BasesDeEnvio_Id,
Apertura,ClicksTotales,Email,NoDocumento,DescPerfil,CategoriaObjetivo,ClientesPlazaCentral_Id,Facturas_Id,Comercio,Subcategoria,
Categoria,MontoFactura,FechaInscripcionFactura,Dias,Cruce,Tel_Celular,Orden)
SELECT Campañas_id,DescCampaña,Perfiles_id,FechaPeriodo,BasesDeEnvio_Id,
Apertura,ClicksTotales,Email,NoDocumento,DescPerfil,CategoriaObjetivoEnvio,ClientesPlazaCentral_Id,Facturas_Id,Comercio,Subcategoria,
Categoria,cast(MontoFactura as int),FechaInscripcionFactura,cast(Dias as int),Cruce,Tel_Celular,OrdenFacturas	
from #CrucePlazaCentral
where Facturas_Id is not null and OrdenFacturas=1
	

/********************* FUNNEL ***********************/
If Object_id('tempdb..#PublicoFunnel') is not null
	drop table #PublicoFunnel
SELECT C.CodigoCampaña,C.Descripcion, P.CodigoPerfil,p.Descripcion  DescPerfil ,COALESCE(CAST(P.FechaEnvio as date), CAST(P.Creado AS DATE)) FechaPeriodo,1 Potencial, 
		cast(M.Envio as int) Envio, cast(M.Apertura as int) Apertura, cast(M.Click as int)+m.ClicksTotales Click, cast(M.Desuscripcion as int) Desuscripcion, 
		cast(M.Rebote as int) Rebote, B.Email,B.Tel_Celular,B.NoDocumento,b.BasesDeEnvio_Id,pl.Nombre Plataforma, pl.Medio, c.FuenteSiebel, iif(p2.CodigoPerfil is null, 
		p.CodigoPerfil, p2.CodigoPerfil) CodigoPerfilPadre, iif(p2.Descripcion is null, p.Descripcion, p2.Descripcion) DescPerfilPadre,A.Nombre AliasCampañas, 
		C.Descripcion  DescCampaña
 INTO #PublicoFunnel
FROM campañas.dbo.Campañas C
LEFT JOIN campañas.dbo.Perfiles P
ON P.Campañas_id = C.Campañas_id
LEFT JOIN campañas.dbo.BasesDeEnvio B
ON P.Perfiles_id = B.Perfiles_id
LEFT JOIN campañas.dbo.Metricas M
ON M.BasesDeEnvio_Id = B.BasesDeEnvio_Id
LEFT JOIN campañas.dbo.Plataformas PL
ON PL.Plataformas_id = P.Plataformas_Id
LEFT JOIN Campañas.dbo.Perfiles p2
ON p.PerfilRaiz_Id = p2.Perfiles_id
LEFT JOIN Campañas.dbo.AliasCampañas A
ON A.AliasCampañas_Id = P.AliasCampañas_Id
--WHERE convert(nvarchar(7),coalesce(P.FechaEnvio,P.Creado),126)='2021-06' 
WHERE C.Cuentas_Id = 150		
AND B.EsGrupoControl = 0
AND C.Campañas_id<>8303
AND p.Perfiles_Id not in (53776,54092,54112,54305)



/*********** FUNNEL CAMPAÑAS *****************/
drop table if exists PBDB.dbo.FunnelCampañas
SELECT  year(a.FechaPeriodo) Año,left(cast(a.FechaPeriodo as date),7) Mes,month(cast(a.FechaPeriodo as date)) Mes_,a.CodigoCampaña, 
case when month(cast(a.FechaPeriodo as date)) = 1 then 'ENE'
	 when month(cast(a.FechaPeriodo as date)) = 2 then 'FEB'
	 when month(cast(a.FechaPeriodo as date)) = 3 then 'MAR'
	 when month(cast(a.FechaPeriodo as date)) = 4 then 'ABR'
	 when month(cast(a.FechaPeriodo as date)) = 5 then 'MAY'
	 when month(cast(a.FechaPeriodo as date)) = 6 then 'JUN'
	 when month(cast(a.FechaPeriodo as date)) = 7 then 'JUL'
	 when month(cast(a.FechaPeriodo as date)) = 8 then 'AGO'
	 when month(cast(a.FechaPeriodo as date)) = 9 then 'SEP'
	 when month(cast(a.FechaPeriodo as date)) = 10 then 'OCT'
	 when month(cast(a.FechaPeriodo as date)) = 11 then 'NOV'
	 ELSE 'DIC'
end	Mes_Campañas,
	a.DescCampaña as Nombre_de_Campaña, a.CodigoPerfil, a.DescPerfil,
	sum(Potencial) Publico,sum(isnull(Envio,0)) Envio, format((cast(sum(isnull(Envio,0)) as float)/(cast(sum(Potencial) as float))),'P2') [% Envío],
	(sum(isnull(Envio,0))-sum(isnull(Rebote,0))) Efectivos,sum(isnull(a.Apertura,0)) Apertura, 
	iif((cast((sum(isnull(Envio,0))-sum(isnull(Rebote,0))) as float)) = 0, format(0,'P2'),format((cast(sum(isnull(a.Apertura,0)) as float)/(cast((sum(isnull(Envio,0))-sum(isnull(Rebote,0))) as float))),'P2')) [% Apertura],
	sum(isnull(Click,0)) Click,
	iif((sum(isnull(a.Apertura,0)))=0,format(0,'P2'),format((cast(sum(isnull(Click,0)) as float)/(cast(sum(isnull(a.Apertura,0)) as float))),'P2')) [% Click],
	sum(isnull(Desuscripcion,0)) Desuscripcion,sum(isnull(Rebote,0)) Rebote,sum(iif(b.facturas_id is null,0,1)) Ventas,
	sum(iif(b.MontoFactura is null,0,MontoFactura)) Monto,a.Plataforma,a.Medio 
into PBDB.dbo.FunnelCampañas
from #PublicoFunnel a
left join PlazaCentral.dbo.DetalleBasesdeenvioVentas b
on a.BasesDeEnvio_Id = b.BasesDeEnvio_Id
group by year(a.FechaPeriodo),left(cast(a.FechaPeriodo as date),7),month(cast(a.FechaPeriodo as date)),
case when month(cast(a.FechaPeriodo as date)) = 1 then 'ENE'
	 when month(cast(a.FechaPeriodo as date)) = 2 then 'FEB'
	 when month(cast(a.FechaPeriodo as date)) = 3 then 'MAR'
	 when month(cast(a.FechaPeriodo as date)) = 4 then 'ABR'
	 when month(cast(a.FechaPeriodo as date)) = 5 then 'MAY'
	 when month(cast(a.FechaPeriodo as date)) = 6 then 'JUN'
	 when month(cast(a.FechaPeriodo as date)) = 7 then 'JUL'
	 when month(cast(a.FechaPeriodo as date)) = 8 then 'AGO'
	 when month(cast(a.FechaPeriodo as date)) = 9 then 'SEP'
	 when month(cast(a.FechaPeriodo as date)) = 10 then 'OCT'
	 when month(cast(a.FechaPeriodo as date)) = 11 then 'NOV'
	 ELSE 'DIC'
end,a.CodigoCampaña, a.DescCampaña,a.CodigoPerfil, a.DescPerfil,a.Plataforma, a.Medio
order by CodigoCampaña,CodigoPerfil



/*********** FUNNEL TIPO COMUNICACIÓN *****************/
drop table if exists PBDB.dbo.FunnelCampañas2
SELECT year(a.FechaPeriodo) Año,left(cast(a.FechaPeriodo as date),7) Mes,month(cast(a.FechaPeriodo as date)) Mes_,
case when month(cast(a.FechaPeriodo as date)) = 1 then 'ENE'
	 when month(cast(a.FechaPeriodo as date)) = 2 then 'FEB'
	 when month(cast(a.FechaPeriodo as date)) = 3 then 'MAR'
	 when month(cast(a.FechaPeriodo as date)) = 4 then 'ABR'
	 when month(cast(a.FechaPeriodo as date)) = 5 then 'MAY'
	 when month(cast(a.FechaPeriodo as date)) = 6 then 'JUN'
	 when month(cast(a.FechaPeriodo as date)) = 7 then 'JUL'
	 when month(cast(a.FechaPeriodo as date)) = 8 then 'AGO'
	 when month(cast(a.FechaPeriodo as date)) = 9 then 'SEP'
	 when month(cast(a.FechaPeriodo as date)) = 10 then 'OCT'
	 when month(cast(a.FechaPeriodo as date)) = 11 then 'NOV'
	 ELSE 'DIC'
end	Mes_Campañas,
	AliasCampañas as Categoria_Comunicacion,
	sum(Potencial) Publico,sum(isnull(Envio,0)) Envio,format((cast(sum(isnull(Envio,0)) as float)/(cast(sum(Potencial) as float))),'P2') [% Envío],
	(sum(isnull(Envio,0))-sum(isnull(Rebote,0))) Efectivos ,sum(isnull(a.Apertura,0)) Apertura,
	iif((cast((sum(isnull(Envio,0))-sum(isnull(Rebote,0))) as float)) = 0, format(0,'P2'),format((cast(sum(isnull(a.Apertura,0)) as float)/(cast((sum(isnull(Envio,0))-sum(isnull(Rebote,0))) as float))),'P2')) [% Apertura],
	sum(isnull(Click,0)) Click, iif(sum(isnull(a.Apertura,0))=0,format(0,'P2'),format((cast(sum(isnull(Click,0)) as float)/(cast(sum(isnull(a.Apertura,0)) as float))),'P2')) [% Click],
	sum(isnull(Desuscripcion,0)) Desuscripcion,sum(isnull(Rebote,0)) Rebote,sum(iif(b.facturas_id is null,0,1)) Ventas,
	sum(iif(b.MontoFactura is null,0,MontoFactura)) Monto,a.Plataforma,a.Medio 
into PBDB.dbo.FunnelCampañas2
from #PublicoFunnel a
left join PlazaCentral.dbo.DetalleBasesdeenvioVentas b
on a.BasesDeEnvio_Id = b.BasesDeEnvio_Id
where AliasCampañas is not null
group by year(a.FechaPeriodo),left(cast(a.FechaPeriodo as date),7),month(cast(a.FechaPeriodo as date)),
case when month(cast(a.FechaPeriodo as date)) = 1 then 'ENE'
	 when month(cast(a.FechaPeriodo as date)) = 2 then 'FEB'
	 when month(cast(a.FechaPeriodo as date)) = 3 then 'MAR'
	 when month(cast(a.FechaPeriodo as date)) = 4 then 'ABR'
	 when month(cast(a.FechaPeriodo as date)) = 5 then 'MAY'
	 when month(cast(a.FechaPeriodo as date)) = 6 then 'JUN'
	 when month(cast(a.FechaPeriodo as date)) = 7 then 'JUL'
	 when month(cast(a.FechaPeriodo as date)) = 8 then 'AGO'
	 when month(cast(a.FechaPeriodo as date)) = 9 then 'SEP'
	 when month(cast(a.FechaPeriodo as date)) = 10 then 'OCT'
	 when month(cast(a.FechaPeriodo as date)) = 11 then 'NOV'
	 ELSE 'DIC'
end,AliasCampañas,a.Plataforma, a.Medio
order by 1


/*********** FUNNEL TIPO CATEGORÍA *****************/

--drop table if exists PBDB.dbo.FunnelCampañasCategorias
--SELECT year(a.FechaPeriodo) Año,left(cast(a.FechaPeriodo as date),7) Mes,month(cast(a.FechaPeriodo as date)) Mes_,
--case when month(cast(a.FechaPeriodo as date)) = 1 then 'ENE'
--	 when month(cast(a.FechaPeriodo as date)) = 2 then 'FEB'
--	 when month(cast(a.FechaPeriodo as date)) = 3 then 'MAR'
--	 when month(cast(a.FechaPeriodo as date)) = 4 then 'ABR'
--	 when month(cast(a.FechaPeriodo as date)) = 5 then 'MAY'
--	 when month(cast(a.FechaPeriodo as date)) = 6 then 'JUN'
--	 when month(cast(a.FechaPeriodo as date)) = 7 then 'JUL'
--	 when month(cast(a.FechaPeriodo as date)) = 8 then 'AGO'
--	 when month(cast(a.FechaPeriodo as date)) = 9 then 'SEP'
--	 when month(cast(a.FechaPeriodo as date)) = 10 then 'OCT'
--	 when month(cast(a.FechaPeriodo as date)) = 11 then 'NOV'
--	 ELSE 'DIC'
--end	Mes_Campañas,
--	Categoria,sum(a.Potencial) Publico,sum(isnull(a.Envio,0)) Envio,
--	format((cast(sum(isnull(Envio,0)) as float)/(cast(sum(Potencial) as float))),'P2') [% Envío],
--	(sum(isnull(Envio,0))-sum(isnull(Rebote,0))) Efectivos ,sum(isnull(a.Apertura,0)) Apertura,
--	iif((cast((sum(isnull(Envio,0))-sum(isnull(Rebote,0))) as float)) = 0, format(0,'P2'),format((cast(sum(isnull(a.Apertura,0)) as float)/(cast((sum(isnull(Envio,0))-sum(isnull(Rebote,0))) as float))),'P2')) [% Apertura],
--	sum(isnull(Click,0)) Click, iif(sum(isnull(a.Apertura,0))=0,format(0,'P2'),format((cast(sum(isnull(Click,0)) as float)/(cast(sum(isnull(a.Apertura,0)) as float))),'P2')) [% Click],
--	sum(isnull(Desuscripcion,0)) Desuscripcion,sum(isnull(Rebote,0)) Rebote,sum(iif(b.facturas_id is null,0,1)) Ventas,
--	sum(iif(b.MontoFactura is null,0,MontoFactura)) Monto,a.Plataforma,a.Medio --,b.FechaPeriodo
--into PBDB.dbo.FunnelCampañasCategorias
--from #PublicoFunnel a
-- left join PlazaCentral.dbo.DetalleBasesdeenvioVentas b
--	on a.BasesDeEnvio_Id = b.BasesDeEnvio_Id
--where b.Categoria is not null and b.Categoria not like '%CERRADO%' and a.Plataforma is not null
--group by year(a.FechaPeriodo),left(cast(a.FechaPeriodo as date),7),month(cast(a.FechaPeriodo as date)),
--case when month(cast(a.FechaPeriodo as date)) = 1 then 'ENE'
--	 when month(cast(a.FechaPeriodo as date)) = 2 then 'FEB'
--	 when month(cast(a.FechaPeriodo as date)) = 3 then 'MAR'
--	 when month(cast(a.FechaPeriodo as date)) = 4 then 'ABR'
--	 when month(cast(a.FechaPeriodo as date)) = 5 then 'MAY'
--	 when month(cast(a.FechaPeriodo as date)) = 6 then 'JUN'
--	 when month(cast(a.FechaPeriodo as date)) = 7 then 'JUL'
--	 when month(cast(a.FechaPeriodo as date)) = 8 then 'AGO'
--	 when month(cast(a.FechaPeriodo as date)) = 9 then 'SEP'
--	 when month(cast(a.FechaPeriodo as date)) = 10 then 'OCT'
--	 when month(cast(a.FechaPeriodo as date)) = 11 then 'NOV'
--	 ELSE 'DIC'
--end,Categoria,a.Plataforma, a.Medio--,b.FechaPeriodo
--order by 1,2,3

/*
SELECT  year(a.FechaPeriodo) Año,left(cast(a.FechaPeriodo as date),7) Mes,Categoria,
	sum(a.Potencial) Publico,iif(Medio = 'Email',count(b.email),count(b.Tel_Celular)) Envio, format((cast(iif(Medio = 'Email',count(distinct b.email),count(distinct b.Tel_Celular)) as float)/(cast(sum(Potencial) as float))),'P2') [% Envío],
	(iif(Medio = 'Email',count(distinct b.email),count(distinct b.Tel_Celular))-sum(isnull(Rebote,0))) Efectivos,count(DISTINCT b.email) Apertura, 
	iif((cast((iif(Medio = 'Email',count(distinct b.email),count(distinct b.Tel_Celular))-sum(isnull(Rebote,0))) as float)) = 0, format(0,'P2'),format((cast(sum(isnull(a.Apertura,0)) as float)/(cast((iif(Medio = 'Email',count(distinct b.email),count(distinct b.Tel_Celular))-sum(isnull(Rebote,0))) as float))),'P2')) [% Apertura],
	sum(isnull(Click,0)) Click,
	iif((sum(isnull(a.Apertura,0)))=0,format(0,'P2'),format((cast(sum(isnull(Click,0)) as float)/(cast(sum(isnull(a.Apertura,0)) as float))),'P2')) [% Click],
	sum(isnull(Desuscripcion,0)) Desuscripcion,sum(isnull(Rebote,0)) Rebote,sum(iif(b.facturas_id is null,0,1)) Ventas,
	sum(iif(b.MontoFactura is null,0,MontoFactura)) Monto,a.Plataforma,a.Medio 
from #PublicoFunnel a
left join PlazaCentral.dbo.DetalleBasesdeenvioVentas b
on a.BasesDeEnvio_Id = b.BasesDeEnvio_Id
where b.Categoria is not null and b.Categoria not like '%CERRADO%' and a.Plataforma is not null
--and cast(a.FechaPeriodo as date) <= cast(b.FechaInscripcionFactura as date)
group by year(a.FechaPeriodo),left(cast(a.FechaPeriodo as date),7),Categoria,a.Plataforma, a.Medio--,b.FechaPeriodo
order by 1,2,3
*/
-- CRUCE CAMPAÑAS
drop table if exists #CampañasPlazaCentralCategoria
select cast(ISNULL(M.Fecha, p.Creado) as date) FechaPeriodo,b.Id_registroOrigen,b.BasesDeEnvio_Id,b.Email,b.Tel_Celular,
		m.Envio,m.Apertura,m.Click,m.Desuscripcion,m.Rebote,m.ClicksTotales,pl.Nombre Plataforma,pl.Medio,a.Nombre AliasCampaña
     INTO #CampañasPlazaCentralCategoria
      FROM Campañas.dbo.Campañas c
      LEFT JOIN Campañas.dbo.Perfiles p
        ON c.Campañas_id = p.Campañas_id
      LEFT JOIN Campañas.dbo.BasesDeEnvio b
        ON b.Perfiles_id = p.Perfiles_id
       LEFT JOIN Campañas.dbo.Metricas m
        ON b.BasesDeEnvio_Id = m.BasesDeEnvio_Id
       LEFT JOIN Campañas.dbo.Plataformas pl
        ON p.Plataformas_Id = pl.Plataformas_id
	   LEFT JOIN Campañas.dbo.AliasCampañas a
	    ON a.AliasCampañas_Id = p.AliasCampañas_Id
     WHERE c.Cuentas_Id = 150 

-- CRUCE FACTURAS
drop table if exists #facturasPlazaCentralCategoria
	 Select C.NoDocumento,C.Tel_celular,C.Email,FechaInscripcionFactura,t.Nombre Comercio,S.Nombre Subcategoria,r.Nombre Categoria,Facturas_Id,c.ClientesPlazaCentral_Id,F.MontoFactura
	 into #facturasPlazaCentralCategoria
	 from  PlazaCentral.dbo.S_Usuarios w
	 left join PlazaCentral.dbo.S_Facturas F
	 on w.Usuarios_Id=F.Usuarios_Id
	 left join PlazaCentral.dbo.ClientesPlazaCentral c
	 ON c.ClientesPlazaCentral_Id = W.ClientesPlazaCentral_Id
	 inner join PlazaCentral.dbo.S_Comercios t
	 on t.Comercios_Id=F.Comercios_Id
	 inner join PlazaCentral.dbo.S_SubCategorias s
	 on s.SubCategorias_Id=t.SubCategorias_Id
	 inner join PlazaCentral.dbo.S_Categorias r
	 on r.Categorias_Id=s.Categorias_id


	drop table if exists PBDB.dbo.FunnelCampañasCategorias
select year(c.FechaPeriodo) Año,left(cast(c.FechaPeriodo as date),7) Mes,month(cast(c.FechaPeriodo as date)) Mes_,
	case when month(cast(c.FechaPeriodo as date)) = 1 then 'ENE'
		when month(cast(c.FechaPeriodo as date)) = 2 then 'FEB'
		when month(cast(c.FechaPeriodo as date)) = 3 then 'MAR'
		when month(cast(c.FechaPeriodo as date)) = 4 then 'ABR'
		when month(cast(c.FechaPeriodo as date)) = 5 then 'MAY'
		when month(cast(c.FechaPeriodo as date)) = 6 then 'JUN'
		when month(cast(c.FechaPeriodo as date)) = 7 then 'JUL'
		when month(cast(c.FechaPeriodo as date)) = 8 then 'AGO'
		when month(cast(c.FechaPeriodo as date)) = 9 then 'SEP'
		when month(cast(c.FechaPeriodo as date)) = 10 then 'OCT'
		when month(cast(c.FechaPeriodo as date)) = 11 then 'NOV'
		ELSE 'DIC'
	 end Mes_Campañas,f.Categoria,count(c.BasesDeEnvio_Id) Publico,sum(isnull(cast(c.Envio as int),0)) Envio,
	 format((cast(sum(isnull(cast(c.Envio as int),0)) as float)/(cast(count(c.BasesDeEnvio_Id) as float))),'P2') [% Envío],
	 (sum(isnull(cast(c.Envio as int),0))-sum(isnull(cast(c.Rebote as int),0))) Efectivos,sum(isnull(cast(c.Apertura as int),0)) Apertura,
	iif((cast((sum(isnull(cast(c.Envio as int),0))-sum(isnull(cast(c.Rebote as int),0))) as float)) = 0, format(0,'P2'),format((cast(sum(isnull(cast(c.Apertura as int),0)) as float)/(cast((sum(isnull(cast(c.Envio as int),0))-sum(isnull(cast(c.Rebote as int),0))) as float))),'P2')) [% Apertura],
	sum(isnull(cast(c.Click as int),0)) Click,iif((sum(isnull(cast(c.Apertura as int),0)))=0,format(0,'P2'),format((cast(sum(isnull(cast(c.Click as int),0)) as float)/(cast(sum(isnull(cast(c.Apertura as int),0)) as float))),'P2')) [% Click],
	sum(isnull(cast(c.Desuscripcion as int),0)) Desuscripcion,sum(isnull(cast(c.Rebote as int),0)) Rebote,count(distinct f.facturas_id) Ventas,--sum(iif(f.facturas_id is null,0,1)) Ventas,
		sum(iif(f.MontoFactura is null,0,f.MontoFactura)) Monto,c.Plataforma,c.Medio 
INTO PBDB.dbo.FunnelCampañasCategorias
from #facturasPlazaCentralCategoria f
left join #CampañasPlazaCentralCategoria c
on f.ClientesPlazaCentral_Id = c.Id_RegistroOrigen
and c.FechaPeriodo <= f.FechaInscripcionFactura  
and DATEDIFF(DD, FechaPeriodo,FechaInscripcionFactura) between 0 and 7 
where f.Categoria is not null and f.Categoria not like '%CERRADO%' and c.Plataforma is not null
group by year(c.FechaPeriodo),left(cast(c.FechaPeriodo as date),7),month(cast(c.FechaPeriodo as date)),
case when month(cast(c.FechaPeriodo as date)) = 1 then 'ENE'
	when month(cast(c.FechaPeriodo as date)) = 2 then 'FEB'
	when month(cast(c.FechaPeriodo as date)) = 3 then 'MAR'
	when month(cast(c.FechaPeriodo as date)) = 4 then 'ABR'
	when month(cast(c.FechaPeriodo as date)) = 5 then 'MAY'
	when month(cast(c.FechaPeriodo as date)) = 6 then 'JUN'
	when month(cast(c.FechaPeriodo as date)) = 7 then 'JUL'
	when month(cast(c.FechaPeriodo as date)) = 8 then 'AGO'
	when month(cast(c.FechaPeriodo as date)) = 9 then 'SEP'
	when month(cast(c.FechaPeriodo as date)) = 10 then 'OCT'
	when month(cast(c.FechaPeriodo as date)) = 11 then 'NOV'
	ELSE 'DIC'
 end,f.Categoria,c.Plataforma,c.Medio 
 order by 1,2


/******************* REDENCIONES *****************************/
drop table if exists #TodasRedenciones
Select c.Usuario_Id,convert(nvarchar(10),c.Creado,126) Creado,p.Nombre,p.Descripcion,p.Cantidad Unidades_Disponibles,p.Section,
		c.redimir,p.Estado
into #TodasRedenciones
from PlazaCentral.dbo.S_Cupones C
left join PlazaCentral.dbo.S_Premios P 
on p.Premios_id=C.Premio_id

--ROW_NUMBER() over (partition by Premios_Id order by Dias ) OrdenFacturas


drop table if exists #Redenciones
select CAST(Creado AS DATE) FechaRedencion,Usuario_id,Nombre,descripcion,Unidades_Disponibles,Section,sum(redimir) Premios_Redimidos,sum(Estado) Premios_Entregados
		--,convert(nvarchar(4),Creado,126) AñoRedencion,convert(nvarchar(7),Creado,126) MesRedencion
into #Redenciones
from #TodasRedenciones
where CAST(Creado AS DATE) is not null
group by CAST(Creado AS DATE),Usuario_id,Nombre,descripcion,Unidades_Disponibles,Section

/*
select Nombre,Descripcion,max(Unidades_Disponibles) Unidades_Disponibles,sum(Premios_Redimidos) Premios_Redimidos,sum(Premios_Entregados) Premios_Entregados
from #Redenciones
where FechaRedencion >= '2021-06-01'
and FechaRedencion <= '2021-06-30'
group by Nombre,Descripcion
*/

drop table if exists #TodasFacturas
select Facturas_Id,Usuarios_Id,convert(nvarchar(10),FechaInscripcionFactura,126) FechaFactura,MontoFactura
into #TodasFacturas
from PlazaCentral.dbo.S_Facturas 
where EstadoFactura_Id=1
and Comercios_Id<>376

drop table if exists #Facturas
select cast(FechaFactura as date) FechaFactura,Usuarios_Id, count(distinct Facturas_Id) FacturasRegistradas,sum(MontoFactura) MontoTotal
	--,convert(nvarchar(4),FechaFactura,126) AñoFactura,convert(nvarchar(7),FechaFactura,126) MesFactura
into #Facturas
from #TodasFacturas
where cast(FechaFactura as date) is not null
group by cast(FechaFactura as date),Usuarios_Id

/*
select month(FechaFactura),count(distinct Usuarios_Id) Clientes_Registran_Facturas,sum(FacturasRegistradas) FacturasRegistradas,
		sum(MontoTotal) MontoTotal
from #Facturas
where FechaFactura >= '2021-01-01'
group by month(FechaFactura)
order by 1
*/



drop table if exists PBDB.dbo.Redenciones_ReporteMensual
select AñoRedencion,MesRedencion,Mes_,
case when Mes_= 1 then 'ENE'
	 when Mes_= 2 then 'FEB'
	 when Mes_= 3 then 'MAR'
	 when Mes_= 4 then 'ABR'
	 when Mes_= 5 then 'MAY'
	 when Mes_= 6 then 'JUN'
	 when Mes_= 7 then 'JUL'
	 when Mes_= 8 then 'AGO'
	 when Mes_= 9 then 'SEP'
	 when Mes_= 10 then 'OCT'
	 when Mes_= 11 then 'NOV'
	 ELSE 'DIC'
end	Mes_Campañas,
	Nombre,Descripcion,Unidades_Disponibles,SUM(Premios_Redimidos) Premios_Redimidos,sum(Premios_Entregados) Premios_Entregados,sum(ClientesQueRegistranFacturas) ClientesQueRegistranFacturas,
	sum(FacturasRegistradas) FacturasRegistradas,sum(Monto) Monto,(sum(FacturasRegistradas)/sum(ClientesQueRegistranFacturas)) PromedioFacturasRegistradas,(sum(Monto)/sum(FacturasRegistradas)) TicketPromedio,TipoRedencion
	into PBDB.dbo.Redenciones_ReporteMensual
from(
select year(FechaRedencion) AñoRedencion,convert(nvarchar(7),FechaRedencion,126) MesRedencion,month(FechaRedencion) Mes_,r.Nombre,r.descripcion,r.Unidades_Disponibles Unidades_Disponibles,sum(Premios_Redimidos) Premios_Redimidos,
		sum(Premios_Entregados) Premios_Entregados,count(distinct Usuarios_Id) ClientesQueRegistranFacturas,sum(cast(isnull(FacturasRegistradas,0) as bigint)) FacturasRegistradas,
		sum(cast(isnull(MontoTotal,0) as bigint)) Monto,--(sum(FacturasRegistradas)/count(distinct Usuarios_Id)) PromedioFacturasRegistradas,(sum(MontoTotal)/sum(FacturasRegistradas)) TicketPromedio,
		case when r.Nombre like '%SONRIA%' or r.Nombre like '%PARQUEADERO%' or r.Nombre like '%MUÉVETE A TU MANERA%' 
			or r.Nombre like '%CUENTOS INFANTILES%' or r.Nombre like '%AMERICANINO%' or r.Nombre like '%BONO ACTUALIZACION DATOS%' 
			then 'Beneficio' 
			when r.Nombre = 'TULA AZUL' or r.Nombre = 'CHALECO REFLECTIVO' or r.Nombre = 'LINTERNA PARA BICICLETA' or r.Nombre = 'CLIP DEPORTIVO FLASH' or r.Nombre = 'TULA ROJO' or r.Nombre = 'TOALLA MICROFIBRA'
			or r.Section = 'a rodar'
			then 'A Rodar' else 'Catalogo' end TipoRedencion
from #Redenciones r
left join #Facturas f
on r.Usuario_id = f.Usuarios_Id
--where CAST(FechaFactura AS DATE) = CAST(FechaRedencion AS DATE)
where DATEDIFF(dd,CAST(FechaFactura AS DATE),CAST(FechaRedencion AS DATE)) BETWEEN 0 AND 2 
group by year(FechaRedencion),convert(nvarchar(7),FechaRedencion,126),month(FechaRedencion),r.Nombre,r.descripcion,Unidades_Disponibles,
		case when r.Nombre like '%SONRIA%' or r.Nombre like '%PARQUEADERO%' or r.Nombre like '%MUÉVETE A TU MANERA%' 
			or r.Nombre like '%CUENTOS INFANTILES%' or r.Nombre like '%AMERICANINO%' or r.Nombre like '%BONO ACTUALIZACION DATOS%' 
			then 'Beneficio' else 'Catalogo' end,Usuarios_Id,r.Section
)a
--where descripcion = 'MUÉVETE A TU MANERA'
group by AñoRedencion,MesRedencion,Mes_,
case when Mes_= 1 then 'ENE'
	 when Mes_= 2 then 'FEB'
	 when Mes_= 3 then 'MAR'
	 when Mes_= 4 then 'ABR'
	 when Mes_= 5 then 'MAY'
	 when Mes_= 6 then 'JUN'
	 when Mes_= 7 then 'JUL'
	 when Mes_= 8 then 'AGO'
	 when Mes_= 9 then 'SEP'
	 when Mes_= 10 then 'OCT'
	 when Mes_= 11 then 'NOV'
	 ELSE 'DIC'
end,Nombre,Descripcion,Unidades_Disponibles,TipoRedencion
ORDER BY 1,2


/******************* HOJA RESUMEN TABLA USUARIOS *****************************/

-- TODOS LOS USUARIOS
drop table if exists #Usuarios
Select year(FechaRegistro) AñoRegistro,left(cast(FechaRegistro as date),7) MesRegistro,cast(FechaRegistro as date) FechaRegistro,u.Usuarios_Id,DATEDIFF(yy,c.FechaNacimiento,getdate()) Edad2,
case when DATEDIFF(yy,c.FechaNacimiento,getdate()) between 18 and 23 then '18 a 23'
when DATEDIFF(yy,c.FechaNacimiento,getdate()) between 24 and 34 then '24 a 34'
when DATEDIFF(yy,c.FechaNacimiento,getdate()) between 35 and 49 then '35 a 49'
when DATEDIFF(yy,c.FechaNacimiento,getdate()) between 50 and 63 then '50 a 63'
when DATEDIFF(yy,c.FechaNacimiento,getdate()) between 64 and 74 then '64 a 74'
when DATEDIFF(yy,c.FechaNacimiento,getdate()) >75 then 'Mayor a 75' else 'No Registrada' end GrupoEtario,
case when Genero_id=1 then 'Hombres' when Genero_id=2 then 'Mujeres' else 'No registra' end Genero,
case when GrupoAfinidad is null then 'No registrada' else GrupoAfinidad end [Grupo Afinidad],
CASe when u.UsuarioMascota=1 then 'Clientes con mascota'  else 'Clientes sin mascota' end [Clientes con mascota],
case when u.TipoRegistro_Id=3 then 'Vecino' when TipoRegistro_Id=2 then 'Amigo' end TipoRegistro,
CASe when u.UsuarioVehiculo=1 then 'Clientes con vehiculo'  else 'Clientes sin vehiculo' end [Clientes con vehiculo],
ROW_NUMBER() over (partition by Usuarios_Id order by cast(FechaRegistro as date )) OrdenUsuarios
into #Usuarios
from PlazaCentral.dbo.S_Usuarios u
left join PlazaCentral.dbo.ClientesPlazaCentral c
on u.Usuarios_Id=c.ClientesPlazaCentral_Id
WHERE U.Nombres not like '%prueba%'
and U.Nombres not like '%test%'
and C.ClientesPlazaCentral_Id not in (60500,11649)

-- TODAS LAS FACTURAS
drop table if exists #FacturasU
SELECT YEAR(cast(FechaInscripcionFactura as date)) AñoIncripcionFactura,left(cast(FechaInscripcionFactura as date),7) MesInscripcionFactura,
	  cast(FechaInscripcionFactura as date) FechaInscripcionFactura,Facturas_Id,Usuarios_Id Usuarios_IdFactura,CAST(MontoFactura AS INT) MontoFactura, 
	  ROW_NUMBER() over (partition by Facturas_Id order by cast(FechaInscripcionFactura as date )) OrdenFacturas
into #FacturasU
FROM PlazaCentral.dbo.S_Facturas 
 WHERE MontoFactura >= 1000
and (comercios_id <> 290 or comercios_id is null)
and estadofactura_id=1
and facturas_id not IN (139675,139800,139806,139818,139824,141364,142165)

drop table if exists PBDB.dbo.PowerBI_Clientes
select u.*,
case when Facturas_Id is null then 'No registran' else 'Registran' end TieneFacturas, F.*,
		case when LEFT(cast(u.FechaRegistro as date),7) = left(cast(f.FechaInscripcionFactura as date),7) then 'Nuevos'  
			 when LEFT(cast(u.FechaRegistro as date),7) < left(cast(f.FechaInscripcionFactura as date),7) or datediff(mm,cast(u.FechaRegistro as date),cast(getdate() as date)) > 2 then 'Antiguos' 
			 when datediff(mm,cast(u.FechaRegistro as date),cast(getdate() as date)) <= 2 then 'Nuevos' 
			 when datediff(mm,cast(u.FechaRegistro as date),cast(getdate() as date)) > 2 then 'Antiguos' 
			 End Tipo_Cliente
		--CASE WHEN LEFT(cast(u.FechaRegistro as date),7) = left(cast(f.FechaInscripcionFactura as date),7) 
		--or (datediff(dd,cast(u.FechaRegistro as date),cast(f.FechaInscripcionFactura as date)) <= 60 and Facturas_Id is null) then 'Nuevos'
		--	 WHEN LEFT(cast(u.FechaRegistro as date),7) < left(cast(f.FechaInscripcionFactura as date),7) then 'Antiguos'
		--	 End Tipo_Cliente
into PBDB.dbo.PowerBI_Clientes
from #Usuarios u
left join #FacturasU f
on u.Usuarios_Id = f.Usuarios_IdFactura
order by  1,2,3

-- CENTRAL COINS 
drop table if exists PBDB.dbo.CentralCoins
SELECT YEAR(CAST(Creado AS date)) AñoCentralCoins,left(CAST(Creado AS date),7) MesCentralCoins,CAST(Creado AS date) FechaCreado,
		usuarios_id usuarios_idCoins,CASE WHEN Puntos > 0 THEN Puntos End CentralCoins_Acumulados,
	   case when Puntos < 0 then usados*-1 End CentralCoins_Redimidos,
	   ROW_NUMBER() over (partition by usuarios_id order by cast(Creado as date )) OrdenCoins
into PBDB.dbo.CentralCoins
FROM PlazaCentral.dbo.S_puntos 
where left(CAST(Creado AS date),7) <= left(CAST(getdate() AS date),7)


-- ITEMS
drop table if exists PBDB.dbo.ItemsUsuarios
select * 
into PBDB.dbo.ItemsUsuarios
from(
select coalesce(AñoIncripcionFactura,AñoRegistro) Año,coalesce(MesInscripcionFactura,MesRegistro) Mes,Usuarios_Id,[Clientes con mascota] ITEM,count(distinct Usuarios_Id) Cantidad
from PlazaCentral.dbo.PowerBI_Clientes
group by coalesce(AñoIncripcionFactura,AñoRegistro),coalesce(MesInscripcionFactura,MesRegistro),Usuarios_Id,[Clientes con mascota]
union 
select coalesce(AñoIncripcionFactura,AñoRegistro) Año,coalesce(MesInscripcionFactura,MesRegistro) Mes,Usuarios_Id,[Clientes con vehiculo],count(distinct Usuarios_Id) Cantidad
from PlazaCentral.dbo.PowerBI_Clientes
group by coalesce(AñoIncripcionFactura,AñoRegistro),coalesce(MesInscripcionFactura,MesRegistro),Usuarios_Id,[Clientes con vehiculo]
union 
select coalesce(AñoIncripcionFactura,AñoRegistro) Año,coalesce(MesInscripcionFactura,MesRegistro) Mes,Usuarios_Id,TipoRegistro,count(distinct Usuarios_Id) Cantidad
from PlazaCentral.dbo.PowerBI_Clientes
group by coalesce(AñoIncripcionFactura,AñoRegistro),coalesce(MesInscripcionFactura,MesRegistro),Usuarios_Id,TipoRegistro
) a
order by 1,2


/************ HOJA FACTURAS REGISTRADAS **********/
drop table if exists PBDB.dbo.FacturasRegistradas
SELECT year(cast(FechaInscripcionFactura as date)) Año,left(cast(FechaInscripcionFactura as date),7) Mes,month(cast(FechaInscripcionFactura as date)) MesN,
case when month(cast(FechaInscripcionFactura as date)) = 1 then 'ENE'
	 when month(cast(FechaInscripcionFactura as date)) = 2 then 'FEB'
	 when month(cast(FechaInscripcionFactura as date)) = 3 then 'MAR'
	 when month(cast(FechaInscripcionFactura as date)) = 4 then 'ABR'
	 when month(cast(FechaInscripcionFactura as date)) = 5 then 'MAY'
	 when month(cast(FechaInscripcionFactura as date)) = 6 then 'JUN'
	 when month(cast(FechaInscripcionFactura as date)) = 7 then 'JUL'
	 when month(cast(FechaInscripcionFactura as date)) = 8 then 'AGO'
	 when month(cast(FechaInscripcionFactura as date)) = 9 then 'SEP'
	 when month(cast(FechaInscripcionFactura as date)) = 10 then 'OCT'
	 when month(cast(FechaInscripcionFactura as date)) = 11 then 'NOV'
	 ELSE 'DIC'
end	MesEntero,
		 Count(Distinct Usuarios_Id) Clientes_Registran_Facturas, SUM(Clientes_Nuevos) Clientes_Nuevos_Registran,
		 SUM(Facturas_Registradas_del_Mes) Facturas_Registradas_del_Mes,SUM(MontoFactura) MontoFactura,avg(MontoFactura) Ticket_Promedio,
		 (SUM(MontoFactura)/Count(Distinct Usuarios_Id)) as Gasto_Promedio_por_Persona
into PBDB.dbo.FacturasRegistradas
FROM (
 SELECT cast(s.FechaInscripcionFactura as date) FechaInscripcionFactura,s.Usuarios_Id,
		IIF(left(cast(t.FechaRegistro as date),7) = left(cast(s.FechaInscripcionFactura as date),7),1,0) Clientes_Nuevos,
		count(1) as Facturas_Registradas_del_Mes,MontoFactura 
 FROM PlazaCentral.dbo.S_Facturas s
	INNER JOIN PlazaCentral.dbo.S_Usuarios t
	ON s.Usuarios_Id =t.Usuarios_Id
 WHERE left(cast(s.FechaInscripcionFactura as date),7) >= '2019-01'
		and cast(t.FechaRegistro as date) <= cast(s.FechaInscripcionFactura as date)
		AND s.MontoFactura >= 1000
		and ((s.comercios_id <> 290 or s.comercios_id is null)
		and s.estadofactura_id=1
		and s.facturas_id not IN (139675,139800,139806,139818,139824,141364,142165)
		and t.Nombres not like '%prueba%'
		and t.Nombres not like '%test%')
		and t.ClientesPlazaCentral_Id not in (60500,11649)
	GROUP BY year(cast(s.FechaInscripcionFactura as date)),left(cast(s.FechaInscripcionFactura as date),7),month(cast(s.FechaInscripcionFactura as date)),
		cast(t.FechaRegistro as date),cast(s.FechaInscripcionFactura as date),MontoFactura,s.Usuarios_Id
) a
GROUP BY year(cast(FechaInscripcionFactura as date)),left(cast(FechaInscripcionFactura as date),7),month(cast(FechaInscripcionFactura as date))
ORDER BY 1,2



 /************ HOJA AVANCE CATEGORÍAS **********/
 drop table if exists PBDB.dbo.AvanceCategorias
Select year(cast(f.FechaInscripcionFactura as date)) Año,left(cast(f.FechaInscripcionFactura as date),7) Mes,
month(cast(F.FechaInscripcionFactura as date)) MesN,
case when month(cast(F.FechaInscripcionFactura as date)) = 1 then 'ENE'
	 when month(cast(F.FechaInscripcionFactura as date)) = 2 then 'FEB'
	 when month(cast(F.FechaInscripcionFactura as date)) = 3 then 'MAR'
	 when month(cast(F.FechaInscripcionFactura as date)) = 4 then 'ABR'
	 when month(cast(F.FechaInscripcionFactura as date)) = 5 then 'MAY'
	 when month(cast(F.FechaInscripcionFactura as date)) = 6 then 'JUN'
	 when month(cast(F.FechaInscripcionFactura as date)) = 7 then 'JUL'
	 when month(cast(F.FechaInscripcionFactura as date)) = 8 then 'AGO'
	 when month(cast(F.FechaInscripcionFactura as date)) = 9 then 'SEP'
	 when month(cast(F.FechaInscripcionFactura as date)) = 10 then 'OCT'
	 when month(cast(F.FechaInscripcionFactura as date)) = 11 then 'NOV'
	 ELSE 'DIC'
end	MesEntero,
	r.Nombre Categoria,f.Facturas_Id,f.MontoFactura Monto
into PBDB.dbo.AvanceCategorias
from PlazaCentral.dbo.S_Facturas f
left join PlazaCentral.dbo.S_Usuarios w
on w.Usuarios_Id=F.Usuarios_Id
left join PlazaCentral.dbo.ClientesPlazaCentral c
ON c.ClientesPlazaCentral_Id = W.ClientesPlazaCentral_Id
inner join PlazaCentral.dbo.S_Comercios t
on t.Comercios_Id=F.Comercios_Id
inner join PlazaCentral.dbo.S_SubCategorias s
on s.SubCategorias_Id=t.SubCategorias_Id
inner join PlazaCentral.dbo.S_Categorias r
on r.Categorias_Id=s.Categorias_id
WHERE left(cast(f.FechaInscripcionFactura as date),7) >= '2019-01'
and r.Categorias_Id not in(9,15)


SELECT *
FROM PlazaCentral.dbo.ClientesPlazaCentral

 /************ HOJA TOP - BOTTOM MARCAS **********/
 drop table if exists PBDB.dbo.TopBottomMarcas
Select Year(f.FechaInscripcionFactura) Año,concat(Year(f.FechaInscripcionFactura),'-',right('0'+cast(Month(f.FechaInscripcionFactura) as varchar(2)),2)) Mes,
	month(cast(F.FechaInscripcionFactura as date)) MesN,
	case when month(cast(F.FechaInscripcionFactura as date)) = 1 then 'ENE'
	 when month(cast(F.FechaInscripcionFactura as date)) = 2 then 'FEB'
	 when month(cast(F.FechaInscripcionFactura as date)) = 3 then 'MAR'
	 when month(cast(F.FechaInscripcionFactura as date)) = 4 then 'ABR'
	 when month(cast(F.FechaInscripcionFactura as date)) = 5 then 'MAY'
	 when month(cast(F.FechaInscripcionFactura as date)) = 6 then 'JUN'
	 when month(cast(F.FechaInscripcionFactura as date)) = 7 then 'JUL'
	 when month(cast(F.FechaInscripcionFactura as date)) = 8 then 'AGO'
	 when month(cast(F.FechaInscripcionFactura as date)) = 9 then 'SEP'
	 when month(cast(F.FechaInscripcionFactura as date)) = 10 then 'OCT'
	 when month(cast(F.FechaInscripcionFactura as date)) = 11 then 'NOV'
	 ELSE 'DIC'
end	MesEntero,
	iif(c.Genero is null,'ND',c.Genero) Genero ,
	case when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) between 18 and 23 then '18 a 23'
		 when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) between 24 and 34 then '24 a 34'
		 when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) between 35 and 49 then '35 a 49'
		 when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) between 50 and 63 then '50 a 63'
		 when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) between 64 and 74 then '64 a 74'
		 when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) >75 then 'Mayor a 75' else 'No Registrada' end GrupoEtario,
	t.nombre Marca,count(1) Ventas
into PBDB.dbo.TopBottomMarcas
from PlazaCentral.dbo.S_Facturas f
left join PlazaCentral.dbo.S_Usuarios w
on w.Usuarios_Id=F.Usuarios_Id
left join PlazaCentral.dbo.ClientesPlazaCentral c
ON c.ClientesPlazaCentral_Id = W.ClientesPlazaCentral_Id
inner join PlazaCentral.dbo.S_Comercios t
on t.Comercios_Id=F.Comercios_Id
inner join PlazaCentral.dbo.S_SubCategorias s
on s.SubCategorias_Id=t.SubCategorias_Id
inner join PlazaCentral.dbo.S_Categorias r
on r.Categorias_Id=s.Categorias_id
where r.Categorias_Id not in(9,15)
group by Year(f.FechaInscripcionFactura),concat(Year(f.FechaInscripcionFactura),'-',right('0'+cast(Month(f.FechaInscripcionFactura) as varchar(2)),2)),t.Nombre,
		month(cast(F.FechaInscripcionFactura as date)), case when month(cast(F.FechaInscripcionFactura as date)) = 1 then 'ENE'
	 when month(cast(F.FechaInscripcionFactura as date)) = 2 then 'FEB'
	 when month(cast(F.FechaInscripcionFactura as date)) = 3 then 'MAR'
	 when month(cast(F.FechaInscripcionFactura as date)) = 4 then 'ABR'
	 when month(cast(F.FechaInscripcionFactura as date)) = 5 then 'MAY'
	 when month(cast(F.FechaInscripcionFactura as date)) = 6 then 'JUN'
	 when month(cast(F.FechaInscripcionFactura as date)) = 7 then 'JUL'
	 when month(cast(F.FechaInscripcionFactura as date)) = 8 then 'AGO'
	 when month(cast(F.FechaInscripcionFactura as date)) = 9 then 'SEP'
	 when month(cast(F.FechaInscripcionFactura as date)) = 10 then 'OCT'
	 when month(cast(F.FechaInscripcionFactura as date)) = 11 then 'NOV'
	 ELSE 'DIC'end, iif(c.Genero is null,'ND',c.Genero),
	case when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) between 18 and 23 then '18 a 23'
		 when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) between 24 and 34 then '24 a 34'
		 when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) between 35 and 49 then '35 a 49'
		 when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) between 50 and 63 then '50 a 63'
		 when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) between 64 and 74 then '64 a 74'
		 when DATEDIFF(yy,cast(c.FechaNacimiento as date),getdate()) >75 then 'Mayor a 75' else 'No Registrada' end 
order by 2 desc


