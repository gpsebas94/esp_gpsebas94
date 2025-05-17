Select top 10 *
from gm_COL.dbo.Distribuidores


DROP TABLE IF EXISTS #ventasCOL
Select *	
into #ventasCOL
from (
	select v.VentasCOL_Id, v.VIN, v.ClientesCOL_Id, 
		c.Nombre1, c.Apellido1,C.Razon_Social, c.Correo, c.Tel_Celular,
		case when l.EsEmpresaCalc_Livianos=1 then 'Empresa' when  l.EsEmpresaCalc_Livianos=0 then 'Natural' end 'Tipo Persona', 
		d.BAC, d.Nombre_Distribuidor Dealer, d.Nombre_Corto,ciudad,Zona, h.Modelo_Corto, C.NoDocumento,
					ROW_NUMBER() over(partition by Vin order by v.fecha_venta desc) OrdenVin,
			v.Fecha_Venta, h.Modelo_Completo,h.Segmento,KMAT,
		case when C.Genero ='M' then 'Masculino' when c.Genero='F' then 'Femenino' else 'No Registra' end Genero,
		 case when	cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) is null then 'No registra'
		 when cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) between 18 And 24 then '18 a 24 años'
when cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) between 25 And 34 then '25 a 34 años'
when cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) between 35 And 44 then '35 a 44 años'
when cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) between 45 And 54 then '45 a 54 años'
when cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) between 55 And 64 then '55 a 64 años'
when cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) >=65 then 'Mayor a 65 años'  end Edad,
		year(Fecha_Venta) AñoVenta,V.uso,V.Forma_Pago,V.Tipo_Venta,V.Valor_Neto,V.valor_total,
		case when forma_pago like '%Contado%' then 'CONTADO'	
		when forma_pago like '%CRED%' then 'CREDITO' 
		when forma_pago like '%ChevyPlan%' then 'CHEVYPLAN' 
		else 'OTRO' end forma_pago2,
			case when V.Tipo_Venta ='Cliente Final' then 'CLIENTE FINAL'
		when V.Tipo_Venta like '%Flota%' then 'FLOTA'
		when V.Tipo_Venta like '%Empresa%' then 'EMPRESA'	else 'OTROS' end Tipo_Venta2,
		--case when segmento in ('TRUCKS','BUS') then 'Pesados' else 'LIVIANOS' end SegmentoVehiculo	,
		case when Uso in ('Comercial','Particular') then Uso else 'OTROS' end uso2
	from gm_COL.dbo.VentasCOL V
	left join gm_COL.dbo.clientesCOL c
		on v.clientesCOL_id = c.clientesCOL_id
	left join gm_COL.dbo.Distribuidores d
		on v.distribuidores_id = d.distribuidores_id
	left join gm_COL.dbo.vehiculos h
		on v.vehiculos_id = h.vehiculos_id
	left join gm_COL.dbo.clientescalc l
		on v.ClientesCOL_Id = l.ClientesCOL_Id
	where v.estado_cupon = 'Activo'	
		and d.Nombre_Distribuidor not like '%gm%direc%'
	--	and segmento in ('TRUCKS')	and Modelo_Corto like '%N%'
	--	and esempresaCalc=1
			) a
where a.OrdenVin = 1
--666651

Select top 10 *,convert(nvarchar(7),Fecha_venta,126)
from #ventasCOL
where NoDocumento='6749690'



--Todas las ventas de clientes de Livianos con los filtros solicitados
drop table if exists #baseClientes
Select *
into #baseClientes
from #ventasCOL
where --NoDocumento in (Select NoDocumento from #ventasCOL where segmento not in ('TRUCKS','BUS')) and
AñoVenta>=2016 and [Tipo Persona]='Natural' and Segmento not in ('SINSEGM','TAXI','TRUCKS','BUS')
and convert(nvarchar(7),Fecha_venta,126)<='2021-10'
--145036

Select distinct segmento,modelo_corto 
from #baseClientes
order by segmento,modelo_corto 
----------------------------------------------------------------------------------------------
--------------------------------Ajuste valores por KMAT ------------------------------------------------

--- Actualizamos el valos total a valores del 2021
--update Inxait.dbo.ipc
--set Ipc_Acumulado=replace(Ipc_Acumulado,',','.')

--alter table #baseClientes add ValorNeto bigint 
alter table #baseClientes add ValorTotal bigint 

update b
set ValorTotal=cast(cast(Valor_Total as bigint)*cast(I.Ipc_Acumulado as float) as bigint)--, 
--ValorNeto=cast(cast(Valor_Neto as bigint)*cast(I.Ipc_Acumulado as float) as bigint)
from #baseClientes b
left join Inxait.dbo.ipc I
on B.añoVenta=I.Año
--145036

update #baseClientes 
set ValorTotal=Valor_Total--,ValorNeto=Valor_Neto
where añoVenta=2021
--10444


/*
Consulta para determinar como estandarizar los precios
*/

drop table if exists #P10
Select KMAT,Modelo_Corto,max(ValorTotal) p10
into #P10
From (
Select *,NTILE(10) over(partition by KMAT order by cast(ValorTotal as bigint)) PerValor_Neto
from #baseClientes) a
where a.PerValor_Neto=1
group by KMAT,Modelo_Corto
--165

drop table if exists #P90
Select KMAT,max(ValorTotal) P90
into #P90
From (
Select *,NTILE(10) over(partition by KMAT order by cast(ValorTotal as bigint) ) PerValor_Neto
from #baseClientes) a
where a.PerValor_Neto=9
group by KMAT
--138

Select Modelo_Corto,P2.*,P7.P90,Prom_Valor_Total,st_VLtotal
from #P10 P2
left join #P90 P7
on P2.KMAT=P7.KMAT
left join (Select KMAT ,avg(ValorTotal) Prom_Valor_Total,stdev(ValorTotal) st_VLtotal
from #baseClientes
group by KMAT) M
on P2.KMAT=M.KMAT

--consulta para ver los precios por modelo PERCENTIL DEL 1 AL 100
Select Modelo_corto,PerValor_Neto,max(ValorTotal) p10
From (
Select *,NTILE(100) over(partition by Modelo_Corto order by cast(ValorTotal as bigint)) PerValor_Neto
from #baseClientes
where Modelo_Corto like '%Camaro%'
--where KMAT='U1ER862VLC5'
) a
group by Modelo_corto,PerValor_Neto

-----------------------------------------------------------------------------------
---Estos son los limites inferior y superior definidos segun las consultas anteriores anteriores ()
-- Para definirlo se tuvieron en cuenta los percentiles 
--Existe un excel donde se evidencian los valores propuestos


Select *
from Inxait.dbo.VECOL_PreciosEstandarizados

--alter table #baseClientes add ValorNeto bigint 
alter table #baseClientes add MontoTotal bigint 

update b
set MontoTotal=case when ValorTotal <P.LI and cast(cast(Valor_Neto as bigint)*cast(I.Ipc_Acumulado as float) as bigint) between LI and LS  then cast(cast(Valor_Neto as bigint)*cast(I.Ipc_Acumulado as float) as bigint) 
when ValorTotal <P.LI  then LI 
when ValorTotal >P.LS then LS else ValorTotal end
 from #baseClientes b
left join Inxait.dbo.VECOL_PreciosEstandarizados P
on B.KMAT=P.KMAT
left join Inxait.dbo.ipc I
on B.añoVenta=I.Año
--145036

Select top 100 *
from #baseClientes
order by MontoTotal  desc


--------------------------------------------------------------------------------------------------------------------
------------------------- Se genera la base de posventa------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

Select max(FechaFacturaCalc)
from GM_COL.dbo.PostVentaOrigenCOL

drop table if exists #BasePostVentaDetalle
SELECT *
into #BasePostVentaDetalle
	FROM GM_COL.dbo.PostVentaOrigenCOL
where MarcaCalc='CHEVROLET' and FechaFacturaCalc>='2016-01-01' and FechaFacturaCalc<='2021-10-31' 
and LEN(Vin)=17 and vin<>'No informa'
--and ( try_cast(MecanicaRapida as int)=1 or Try_cast(MecanicaEspecializada as int)=1) 
--3742766

Select top 10 *
from #BasePostVentaDetalle

drop table if exists #entradaventaposventa
Select P.PostVentaOrigenCOL_Id,V.VIN,P.Kilometraje,V.Segmento,V.Modelo_Corto,V.Fecha_Venta,P.FechaFacturaCalc,V.NoDocumento,P.cedulaCalc,
case when ColisionLeve='1' then 'ColisionLeve'
when ColisionMedia='1' then 'ColisionMedia'
when ColisionFuerte='1' then 'ColisionFuerte'
when MecanicaEspecializada='1' then 'MecanicaEspecializada'
when MecanicaRapida='1' then 'MecanicaRapida'
when Accesorios='1' then 'Accesorios' 
when GarantiaGM='1' then 'GarantiaGM'
when AlistamientoPeritaje='1' then 'AlistamientoPeritaje'
when Retornos='1' then 'Retornos'
when Internos='1' then 'Internos' else 'Otros' end tipo_de_servicio,
case when inxait.dbo.fn_LimpiarCadena(Kilometraje, '^A-Z')<>'' then null
when try_cast(replace(Kilometraje,'.','') as float) is null then cast(replace(replace(STUFF(Kilometraje, 1, PATINDEX('%[^$]%', Kilometraje) - 1, ''),'.','') ,',','.') as float)
else cast(replace(Kilometraje,'.','') as float) end Km
into #entradaventaposventa
from #baseClientes V
inner  join #BasePostVentaDetalle P
on V.VIN=p.vin
where cast(fecha_Venta as date) < cast(FechaFacturaCalc as date)
--886732

Select count(*),count(distinct concat(Vin,kilometraje,FechaFacturaCalc)),count(distinct concat(Vin,kilometraje)),count(distinct concat(Vin,FechaFacturaCalc))
from #entradaventaposventa
--886733	857584	784678	847642

Select Vin,kilometraje,tipo_de_servicio,count(*)
from #entradaventaposventa
group by Vin,kilometraje,tipo_de_servicio having(count(*)>1)

Select *
from #entradaventaposventa
where VIN='1G1F91R71G0180291'
order by FechaFacturaCalc

drop table if exists #mecanicarapida
Select *
into #mecanicarapida
from  (
Select *,ROW_NUMBER() over(partition by Vin,kilometraje,tipo_de_servicio order by FechaFacturaCalc desc ) ORdenKM
from (
Select *,ROW_NUMBER() over(partition by Vin,FechaFacturaCalc,tipo_de_servicio order by kilometraje desc ) OrdenFecha
from #entradaventaposventa) a 
where OrdenFecha=1 ) b
where B.ORdenKM=1
--821009

Select top 10 *
 from #mecanicarapida

drop table if exists #EntradasPV
Select VIN,cedulaCalc,COUNT(*) Entradas,max(FechaFacturaCalc) UltimaEntrada
into #EntradasPV
from #mecanicarapida
where tipo_de_servicio in ('MecanicaEspecializada','MecanicaRapida')
group by VIN,cedulaCalc 
--145064

drop table if exists #EntradasVIN
Select VIN,COUNT(*) Entradas,max(FechaFacturaCalc) UltimaEntrada
into #EntradasVIN
from #mecanicarapida
group by VIN
--133784

Select count(*),count(distinct VIN)
from #EntradasPV
--145066	124600
--------------------------------------------------------------------------------------------------------------------
------------------------- Se genera la base de MEtricas------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


drop table if exists #metricas
Select *
into #metricas
from (
Select inxait.dbo.fn_LimpiarCadena(STUFF(NoDocumento, 1, PATINDEX('%[^0]%', NoDocumento) - 1, ''), '^0-9') NoDocumento,
cast(Envio as int) Envio,cast(Apertura as int) Aperturas,cast(Click as int) +cast(iif(ClicksTotales>0,1,0) as int)  clicks,
ROW_NUMBER() over (partition by inxait.dbo.fn_LimpiarCadena(STUFF(NoDocumento, 1, PATINDEX('%[^0]%', NoDocumento) - 1, ''), '^0-9') order by P.FechaEnvio desc) OrdenEnvio
from Campañas.dbo.basesdeenvio B
left join Campañas..Metricas M
on M.BasesDeEnvio_Id=B.BasesDeEnvio_Id
inner join campañas.dbo.perfiles P
on P.perfiles_id=B.perfiles_id
inner join Campañas..Campañas C
on C.Campañas_id=P.Campañas_id 
inner join Campañas.dbo.Plataformas t
on P.Plataformas_Id=t.Plataformas_id
where Cuentas_Id=190 and Medio='Email'
and P.FechaEnvio is not null and cast(Envio as int)=1 ) a
where OrdenEnvio<=10
--3841273


drop table if exists #metricasEmail
Select NoDocumento,Count(*) Registros,sum(cast(Envio as int)) Envio,
sum(cast(Aperturas as int)) Aperturas,sum(cast(Clicks as int))  clicks
into #metricasEmail
from #metricas
where NoDocumento is not null
group by NoDocumento
--772989



drop table if exists #metricas2
Select *
into #metricas2
from (
Select inxait.dbo.fn_LimpiarCadena(STUFF(NoDocumento, 1, PATINDEX('%[^0]%', NoDocumento) - 1, ''), '^0-9') NoDocumento,
cast(Envio as int) Envio,cast(Apertura as int) Aperturas,cast(Click as int) +cast(iif(ClicksTotales>0,1,0) as int)  clicks,
ROW_NUMBER() over (partition by inxait.dbo.fn_LimpiarCadena(STUFF(NoDocumento, 1, PATINDEX('%[^0]%', NoDocumento) - 1, ''), '^0-9') order by P.FechaEnvio desc) OrdenEnvio
from Campañas.dbo.basesdeenvio B
left join Campañas..Metricas M
on M.BasesDeEnvio_Id=B.BasesDeEnvio_Id
inner join campañas.dbo.perfiles P
on P.perfiles_id=B.perfiles_id
inner join Campañas..Campañas C
on C.Campañas_id=P.Campañas_id 
inner join Campañas.dbo.Plataformas t
on P.Plataformas_Id=t.Plataformas_id
where Cuentas_Id=190 and Medio='SMS'
and P.FechaEnvio is not null and cast(Envio as int)=1 ) a
where OrdenEnvio<=10
--3841273


drop table if exists #metricasSMS
Select NoDocumento,Count(*) Registros,sum(cast(Envio as int)) Envio,
sum(cast(Aperturas as int)) Aperturas,sum(cast(Clicks as int))  clicks
into #metricasSMS
from #metricas2
where NoDocumento is not null
group by NoDocumento
--681786

Select *
from #metricasSMS
where Envio is null


Select *
from #metricasEmail
order by Envio --is null

/*
drop table if exists #metricas
Select inxait.dbo.fn_LimpiarCadena(STUFF(NoDocumento, 1, PATINDEX('%[^0]%', NoDocumento) - 1, ''), '^0-9') NoDocumento,
Medio,Count(*) Registros,sum(cast(Envio as int)) Envio,sum(cast(Apertura as int)) Aperturas,sum(cast(Click as int)) +sum(cast(iif(ClicksTotales>0,1,0) as int))  clicks
into #metricas
from Campañas.dbo.basesdeenvio B
left join Campañas..Metricas M
on M.BasesDeEnvio_Id=B.BasesDeEnvio_Id
inner join campañas.dbo.perfiles P
on P.perfiles_id=B.perfiles_id
inner join Campañas..Campañas C
on C.Campañas_id=P.Campañas_id 
inner join Campañas.dbo.Plataformas t
on P.Plataformas_Id=t.Plataformas_id
where Cuentas_Id=190 --and Medio='Email'
and P.FechaEnvio is not null
and P.FechaEnvio between '2020-11-01' and '2021-10-31'
group by inxait.dbo.fn_LimpiarCadena(STUFF(NoDocumento, 1, PATINDEX('%[^0]%', NoDocumento) - 1, ''), '^0-9') ,Medio
--932613

drop table if exists #metricasEmail
Select *
into #metricasEmail
from #metricas
where Medio='Email' and NoDocumento is not null
--492914

drop table if exists #metricasSMS
Select *
into #metricasSMS
from #metricas
where Medio='SMS' and NoDocumento is not null
--439747

*/
--------------------------------------------------------------------------------------------------------------------
------------------------- Se genera la base de Ventas------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

Select forma_pago,forma_pago2,count(*) 
from #baseClientes 
group by forma_pago,forma_pago2

drop table if exists #Uso
Select NoDocumento,[Particular], [Comercial],[OTROS] OTRO_USO
into #Uso
from (Select NoDocumento,Vin,uso from #baseClientes ) p
pivot (count(Vin) 
for uso  in ([Particular], [Comercial],[OTROs])) AS PVT
order by PVT.NoDocumento 
--138074

drop table if exists #FormaPago
Select NoDocumento,[CONTADO], [CHEVYPLAN],[CREDITO], [OTRO] OTRA_FORMA_PAGO
into #FormaPago
from (Select NoDocumento,Vin,forma_pago2 from  #baseClientes  ) p
pivot (count(Vin) 
for forma_pago2  in ([CONTADO], [CHEVYPLAN],[CREDITO], [OTRO])) AS PVT
order by PVT.NoDocumento 


--------------------------------------------------------------------------------------------------------------------
------------------------- base de clientes------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------
 Select *
 from #EntradasPV 

drop table if exists #Clientes
Select ClientesCOL_Id,C.NoDocumento,[Tipo persona],genero,edad,count(*) Cantidad,sum(MontoTotal) MontoTotal,max(C.Fecha_venta) UltimaFechaVenta,
sum(iif(P.VIN is not null,P.entradas,0)) Entradas,sum(iif(P.VIN is not null,1,0)) VinEntrada,sum(iif(V.VIN is not null,V.entradas,0)) Entradas2
into #Clientes
from #baseClientes C
left join #EntradasPV P
on C.NoDocumento=P.cedulaCalc and P.VIN=C.vin
left join #EntradasvIN V
on C.VIN=V.VIN
group by ClientesCOL_Id,C.NoDocumento,[Tipo persona],genero,edad
--138074


Select count(*),count(distinct ClientesCOL_Id),count(distinct NoDocumento),sum(Entradas),sum(VinEntrada),sum(Entradas2)
from #Clientes
--138074	138074	138074	507607	117487	821010

alter table #Clientes add cliente nvarchar(max)
alter table #Clientes add city nvarchar(max)
--Select top 10 * from GM_col..VentasOrigencol V

update C
set cliente=concat(Nombre,' ',Apellidos),
city=coalesce(CiudadLimpia,ciudad_Cuenta)
from #Clientes C
inner join GM_col..VentasOrigencol V
on V.Clientescol_Id=C.Clientescol_Id
--138073

update C
set cliente=concat(Nombre1,' ',Apellido1)
from #Clientes C
inner join GM_COL.dbo.ClientesCOL V
on V.Clientescol_Id=C.Clientescol_Id
where cliente is null
--1


drop table if exists #Modelo
Select NoDocumento,Modelo_Completo,Modelo_Corto,Ciudad,Dealer
into #Modelo
from (
Select *,ROW_NUMBER() over(partition by NoDocumento order by Fecha_venta desc) orden3
	from #baseClientes
--	and AñoVenta between 2011 and 2018
	) a
where a.Orden3=1
--138074

drop table if exists #Contactabilidad
Select distinct ClientesCOL_Id,V.NoDocumento,case when v.correo is null then 'Sin Correo' when c.EsValido=1 then 'Valido' when c.EsValido=0 then 'No Valido' else 'Sin Validar' end EmailValido,
case when v.tel_celular is null then 'Sin Celular'  else 'ValidoSMS' end CelularValido, 
case when l.ListaNegraGM_Id is null then '' else 'En lista negra' end ListaNegra
into #Contactabilidad
from #baseClientes v
left join inxait.dbo.CorreosValidados c
on v.correo= c.Correo
left join inxait.dbo.ListaNegraGM l
on v.Correo = l.Correo
--138074


drop table if exists #VentasAntiguas
Select NoDocumento,count(*) Ventas
into #VentasAntiguas
from #ventasCOL
where AñoVenta<=2015 and [Tipo Persona]='Natural' and Segmento not in ('SINSEGM','TAXI','TRUCKS','BUS')
group by NoDocumento
--264791

--------------------------------------------------------------------------------------------------------------------
------------------------- Se consolida la base final------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

Select top 10 * from #Clientes
order by cast(NoDocumento as bigint) desc

drop table if exists Temporales.dbo.RFM_VentasCol
Select V.ClientesCOL_Id,V.NoDocumento,V.cliente,V.[Tipo Persona],V.Genero,V.Edad,v.CITY CiudadCliente,
Ciudad CiudadDealer,Dealer,Modelo_Completo,Modelo_Corto,MontoTotal,V.UltimaFechaVenta,
v.Cantidad Ventas,isnull(A.Ventas,0) VentasAntiguas,Year(V.UltimaFechaVenta) AñoVenta,
[Particular], [Comercial],OTRO_USO,[CONTADO], [CHEVYPLAN],[CREDITO], OTRA_FORMA_PAGO,
datediff(mm,V.UltimaFechaVenta,'2021-10-31') RecenciaVenta,Entradas,VinEntrada,Entradas2,
case when datediff(mm,V.UltimaFechaVenta,getdate())>25 then 'Si' else 'No' end [Sin ventas Recientes],
case when Cantidad>1 then 'Si' else 'No' end [Recompro],
		ISNULL(E.ENVIO,0) EnvioEmail,ISNULL(E.Aperturas,0) AperturaEmail,
				ISNULL(m.ENVIO,0) EnvioSms,ISNULL(M.clicks,0) ClickSMS,
				case when E.NoDocumento is null and M.NoDocumento  is null then 'Email/SMS'
				when E.NoDocumento is null then 'Email'
				when  M.NoDocumento  is null then 'SMS' else 'Enviado' end SinEnvio,
					t.EmailValido,t.CelularValido,t.ListaNegra
into Temporales.dbo.RFM_VentasCol
from #Clientes V
inner join #Uso U
on V.NoDocumento=U.NoDocumento
inner join #Modelo D
on V.NoDocumento=D.NoDocumento
inner join #FormaPago F
on V.NoDocumento=f.NoDocumento
left join #metricasEmail E
on V.NoDocumento=E.NoDocumento
left join #metricasSMS M
on V.NoDocumento=M.NoDocumento
left join #VentasAntiguas A
on V.NoDocumento=A.NoDocumento
left join #Contactabilidad t
on V.NoDocumento=t.NoDocumento
--138074

Select  *
from Temporales.dbo.RFM_VentasCol
order by cast(NoDocumento as bigint)

Select count(*),count(distinct NoDocumento),sum(Ventas),sum(Entradas),sum(VinEntrada),sum(entradas2),
min(UltimaFechaVenta),max(UltimaFechaVenta),sum(AperturaEmail),sum(ClickSMS)
from Temporales.dbo.RFM_VentasCol
--138074	138074	145036	507607	117487	821010	2016-01-04	2021-10-30	159959	93575


--Cuantas clientes tienen entradas a la posventa
Select count(*),sum(VinEntrada)
from Temporales.dbo.RFM_VentasCol
where Entradas>0
--113262	117487


--Cuantos clientes tienen ventas antes del 2015
Select count(*),sum(Ventas)
from Temporales.dbo.RFM_VentasCol
where VentasAntiguas>0
--17989	19803

--Cuantos no se les ha enviado comunicacion en el ultimo año
Select SinEnvio,count(*)
from Temporales.dbo.RFM_VentasCol
group by SinEnvio
order by SinEnvio
/*
Email	14390
Email/SMS	41297
Enviado	61976
SMS	20411
*/
-------------------------------------------------------------------------------------------------
/*
Consulta del por que no se le ha enviado en el ultimo año
*/

---como se estan comportando los envios
Select SinEnvio,EmailValido,CelularValido,ListaNegra,count(*)
from Temporales.dbo.RFM_VentasCol
group by SinEnvio,EmailValido,CelularValido,ListaNegra
order by SinEnvio,EmailValido,CelularValido,ListaNegra

Select *
from GM_COL.DBO.VECOL_RFM_202110
where Apertura_score=1
--Validacion en metricas

Select *
from Campañas..Metricas m
inner join Campañas.dbo.basesdeenvio B
on M.BasesDeEnvio_Id=B.BasesDeEnvio_Id
inner join campañas.dbo.perfiles P
on P.perfiles_id=B.perfiles_id
inner join Campañas..Campañas C
on C.Campañas_id=P.Campañas_id 
where NoDocumento='1144152365'
and  Cuentas_Id=190

Select *
from inxait.dbo.ListaNegraGM
where Correo='JAANROFA555@HOTMAIL.COM'

-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
/*
Calculo de las variables que se utilizaran para definir el RFM / Se puede apoyar en R para sacar esos valores
*/

drop table if exists #VariablesRFM
Select ClientesCOL_Id,MontoTotal,Ventas,RecenciaVenta Recencia,Ventas+Entradas+VentasAntiguas FreqAgr,Entradas,VentasAntiguas,
case when EnvioEmail>0 then AperturaEmail*1.0/EnvioEmail else 0 end TasaApertura ,
NTILE(10) over(order by MontoTotal) Monto_score,
NTILE(10) over(order by RecenciaVenta desc) Recencia_score,
NTILE(10) over(order by Ventas) Facturas_score,
NTILE(10) over(order by Entradas) Entradas_score,
NTILE(10) over(order by VentasAntiguas) Antiguas_score,
NTILE(10) over(order by Ventas+Entradas+VentasAntiguas) Fac_score
into #VariablesRFM
from Temporales.dbo.RFM_VentasCol
--138074

Select Facturas_score,count(*),min(Ventas),max(Ventas)
from #VariablesRFM
group by Facturas_score
order by Facturas_score

Select Entradas_score,count(*),min(Entradas),max(Entradas)
from #VariablesRFM
group by Entradas_score
order by Entradas_score

Select Antiguas_score,count(*),min(VentasAntiguas),max(VentasAntiguas)
from #VariablesRFM
group by Antiguas_score
order by Antiguas_score

Select Fac_score,count(*),min(FreqAgr),max(FreqAgr)
from #VariablesRFM
group by Fac_score
order by Fac_score

-- Este es que mejor da visibilidad de como tomar la frecuencia
Select Ventas,Entradas,VentasAntiguas,count(*)
from Temporales.dbo.RFM_VentasCol
group by Ventas,Entradas,VentasAntiguas
order by Ventas,Entradas,VentasAntiguas

Select Recencia_score,count(*),min(Recencia),max(Recencia)
from #VariablesRFM
group by Recencia_score
order by Recencia_score

Select Monto_score,count(*),min(MontoTotal),max(MontoTotal)
from #VariablesRFM
group by Monto_score
order by Monto_score


Select PerValor_Neto,min(AperturaEmail*1.0/EnvioEmail) PMin,max(AperturaEmail*1.0/EnvioEmail) PMax,count(*)
From (
Select *,NTILE(10) over(order by AperturaEmail*1.0/EnvioEmail ) PerValor_Neto
from Temporales.dbo.RFM_VentasCol
where  EnvioEmail>0 ) a
group by PerValor_Neto

Select *
from Temporales.dbo.RFM_VentasCol
where  EnvioEmail =0 and SinEnvio='Enviado'


Select PerValor_Neto,min(ClickSMS*1.0/EnvioSMS ) PMin,max(ClickSMS*1.0/EnvioSMS ) PMax,count(*)
From (
Select *,NTILE(10) over(order by ClickSMS*1.0/EnvioSMS ) PerValor_Neto
from Temporales.dbo.RFM_VentasCol
where EnvioSMS>0 ) a
group by PerValor_Neto



-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
/*
Categorizacion de las variables del RFM segun los resultados anteriores--Se utilizo una discretizacion del 50% y 80%
*/


drop table if exists #VariablesRFM_2
Select  ClientesCOL_Id,nodocumento,Edad,Genero,CiudadCliente,Modelo_Corto,UltimaFechaVenta,MontoTotal,Ventas,RecenciaVenta Recencia,Entradas,VentasAntiguas,
SinEnvio,EnvioEmail,EnvioSms,--EmailValido,CelularValido,
case when EnvioEmail is not null and EnvioEmail>0 then AperturaEmail*1.0/EnvioEmail else 0 end TasaApertura ,
case when EnvioSms is not null and EnvioSms>0 then ClickSMS*1.0/EnvioSms else 0 end TasaClicksSMS ,
case when Ventas+VentasAntiguas>=2   then 3 
when Ventas=1 and entradas>3 then 2
when Ventas=1 and entradas<=3 then 1 
end frecuency_score,
case when RecenciaVenta <=24  then 3 
when RecenciaVenta <=43  then 2 
when RecenciaVenta >=44  then 1 end recency_score,
case when MontoTotal >=64000000 then 3 
when MontoTotal >=43000000  then 2 
when MontoTotal <43000000  then 1 end Monto_score,
case when Entradas >=6  then 3 
when Entradas >= 3  then 2 
when Entradas >=0  then 1 end Entradas_score,
case when EnvioEmail=0 then 0
when EnvioEmail>0 and  AperturaEmail*1.0/EnvioEmail =0  then 1
when EnvioEmail>0 and  AperturaEmail*1.0/EnvioEmail <=0.2  then 2 
when EnvioEmail>0 and  AperturaEmail*1.0/EnvioEmail <=0.4 then 2 
when EnvioEmail>0 and  AperturaEmail*1.0/EnvioEmail <=0.6 then 3 
when EnvioEmail>0 and  AperturaEmail*1.0/EnvioEmail <=1 then 4 end Apertura_score,
case when EnvioSms=0 then 0
when EnvioSms>0 and  ClickSMS*1.0/EnvioSMS =0  then 1
when EnvioSms>0 and  ClickSMS*1.0/EnvioSMS <=0.2  then 2 
when EnvioSms>0 and  ClickSMS*1.0/EnvioSMS <=0.4  then 2 
when EnvioSms>0 and  ClickSMS*1.0/EnvioSMS <=0.6  then 3 
when EnvioSms>0 and  ClickSMS*1.0/EnvioSMS <=1  then 4 end CLICK_score
into #VariablesRFM_2
from Temporales.dbo.RFM_VentasCol
--138074


-------Consultas para la categorizacion de las variables del RFM
Select frecuency_score,count(*),min(Ventas+VentasAntiguas),max(Ventas+VentasAntiguas),min(Entradas),max(Entradas)
from #VariablesRFM_2
group by frecuency_score
order by frecuency_score


Select recency_score,count(*),min(Recencia),max(Recencia)
from #VariablesRFM_2
group by recency_score
order by recency_score

Select Monto_score,count(*),min(MontoTotal),max(MontoTotal)
from #VariablesRFM_2
group by Monto_score
order by Monto_score

Select Apertura_score,count(*),min(TasaApertura),max(TasaApertura)
from #VariablesRFM_2
group by Apertura_score
order by Apertura_score


Select CLICK_score,count(*),min(TasaClicksSMS),max(TasaClicksSMS)
from #VariablesRFM_2
group by CLICK_score
order by CLICK_score


--------Creacion de la tabla para el RFM
drop table if exists GM_COL.DBO.VECOL_RFM_202110
Select *,case when recency_score=3 then '0 a 24'
when recency_score=2 then '25 a 43'
when recency_score=1 then '44 a 69' end Recency,
case when frecuency_score=1 then '1V - 3E'
when frecuency_score=2 then '1V + 4E'
when frecuency_score=3 then '2V +' end frecuency,
case when Apertura_score=0 then 'Sin Envio'
when Apertura_score=1 then ' 0% '
when Apertura_score=2 then '10% - 40%'
when Apertura_score=3 then '41% - 60%'
when Apertura_score=4 then '61% - 100%' end Aperturas,
case when CLICK_score=0 then 'Sin Envio'
when CLICK_score=1 then ' 0% '
when CLICK_score=2 then '10% - 40%'
when CLICK_score=3 then '41% - 60%'
when CLICK_score=4 then '60% - 100%' end Click,
case when recency_score in (2,3) and frecuency_score in (3) then 'TOP'
when recency_score=3 and frecuency_score in (1,2) then 'MID'
when recency_score=2 and frecuency_score in (2) then 'MID'
else 'LOW' end SEGMENTORFM
into GM_COL.DBO.VECOL_RFM_202110
from #VariablesRFM_2
--138074



--Consulta para extraer los datos y llevarlos a R para generar el mapa de calor
Select *
from GM_COL.DBO.VECOL_RFM_202110

------------------------------------------------------------------------------------------------------
------Consulta de la base de ventas para caractezizar el publico del RFM
drop table if exists Temporales.dbo.baseventasRFM
Select R.*,Vin,BAC,Dealer,Nombre_Corto,Ciudad,Zona,b.Modelo_Corto ModeloVenta,Fecha_Venta,Segmento,forma_pago2,Uso
into Temporales.dbo.baseventasRFM
from GM_COL.DBO.VECOL_RFM_202110 r
inner join #baseClientes b
on R.NoDocumento=B.NoDocumento
--145036

Select SEGMENTORFM,count(*)
from GM_COL.DBO.VECOL_RFM_202110
group by SEGMENTORFM


Select Apertura_score,Aperturas,count(*)
from GM_COL.DBO.VECOL_RFM_202110
where SEGMENTORFM='LOW'
group by Apertura_score,Aperturas
order by Apertura_score desc

Select CLICK_score,Click,count(*)
from GM_COL.DBO.VECOL_RFM_202110
where SEGMENTORFM='LOW'
group by CLICK_score,Click
order by CLICK_score desc


Select Entradas_score,count(*),min(Entradas),max(Entradas)
from GM_COL.DBO.VECOL_RFM_202110
where SEGMENTORFM='LOW'
group by Entradas_score
order by Entradas_score 


Select iif(VentasAntiguas=0,0,1),count(*)
from GM_COL.DBO.VECOL_RFM_202110
where SEGMENTORFM='TOP'
group by iif(VentasAntiguas=0,0,1)
order by iif(VentasAntiguas=0,0,1)




Select Zona,[TOP], [MID], [LOW]
from (Select SEGMENTORFM,Zona,ClientesCOL_Id from Temporales.dbo.baseventasRFM) p
pivot(count(ClientesCOL_Id)
for SEGMENTORFM in ([TOP], [MID], [LOW]) ) as pvt
order by PVT.Zona

Select Segmento,[TOP], [MID], [LOW]
from (Select SEGMENTORFM,Segmento,ClientesCOL_Id from Temporales.dbo.baseventasRFM) p
pivot(count(ClientesCOL_Id)
for SEGMENTORFM in ([TOP], [MID], [LOW]) ) as pvt
order by PVT.Segmento

Select ModeloVenta,[TOP], [MID], [LOW]
from (Select SEGMENTORFM,ModeloVenta,ClientesCOL_Id from Temporales.dbo.baseventasRFM) p
pivot(count(ClientesCOL_Id)
for SEGMENTORFM in ([TOP], [MID], [LOW]) ) as pvt
order by PVT.ModeloVenta

Select case when Ventas+VentasAntiguas>=3 then '3' when Ventas+VentasAntiguas=2 then '2' else '1' end,count(*)
from GM_COL.DBO.VECOL_RFM_202110
group by case when Ventas+VentasAntiguas>=3 then '3' when Ventas+VentasAntiguas=2 then '2' else '1' end


Select case when Ventas>=3 then '3' when Ventas=2 then '2' else '1' end,count(*)
from GM_COL.DBO.VECOL_RFM_202110
group by case when Ventas>=3 then '3' when Ventas=2 then '2' else '1' end

Select case when Entradas>=6 then '3' when Entradas>=3 then '2' else '1' end,count(*)
from GM_COL.DBO.VECOL_RFM_202110
group by case when Entradas>=6 then '3' when Entradas>=3 then '2' else '1' end


------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
--- Consulta para llenar la tabla del RFM
Select recency_score,[1], [2], [3]
from (Select frecuency_score,recency_score,ClientesCOL_Id from #VariablesRFM_2) p
pivot(count(ClientesCOL_Id)
for frecuency_score in ([1], [2], [3]) ) as pvt
order by PVT.recency_score

Select recency_score,[1], [2], [3]
from (Select frecuency_score,recency_score,MontoTotal from #VariablesRFM_2) p
pivot(avg(MontoTotal)
for frecuency_score in ([1], [2], [3]) ) as pvt
order by PVT.recency_score


Select recency_score,[1], [2], [3]
from (Select frecuency_score,recency_score,MontoTotal from #VariablesRFM_2) p
pivot(sum(MontoTotal)
for frecuency_score in ([1], [2], [3]) ) as pvt
order by PVT.recency_score















------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
----------------------- Consulta para primer vehiculo -- Opcional--------------------------------------------
------------------------------------------------------------------------------------------------------------
drop table if exists #ClientesCol
Select *,ROW_NUMBER() over(partition by NoDocumento order by Fecha_venta ) ordenDoc
into #ClientesCol
from #baseClientes
--145038

drop table if exists #TiempoPromedio
Select NoDocumento,avg(Diferencia) PromedioMeses
into #TiempoPromedio
from (
Select *,DATEDIFF(mm,FechaVenta_anterior,Fecha_venta) Diferencia
from (
Select *,lag(Fecha_venta) over (partition by NoDocumento order by ordenDoc) FechaVenta_anterior
from #ClientesCol) a) b
group by NoDocumento
--138876

drop table if exists #primervehiculos
Select V.ClientesCOL_Id,V.NoDocumento,V.VIN,Genero,Edad,v.CIUDAD,Fecha_Venta,AñoVenta,Modelo_Corto,Uso,forma_pago2,Valor_Neto,Valor_Total
into #primervehiculos
from #ClientesCol v
where ordenDoc=1 
--138076


drop table if exists Temporales.dbo.PrimerVehiculoCol
Select C.*,CiudadCliente,Cantidad,Recompro,
case when TP.NoDocumento is not null then PromedioMeses else '' end TiempoPromedio,
RecenciaVenta,EnvioEmail,AperturaEmail,EnvioSms, AperturaSMS
,iif(P.VIN is not null,1,0) Entradas,iif(V.VIN is not null,1,0) Entradas2
into Temporales.dbo.PrimerVehiculoCol
from #primervehiculos c
left join Temporales.dbo.RFM_VentasCol T
on c.NoDocumento=T.NoDocumento
left join #EntradasPV P
on C.NoDocumento=P.cedulaCalc and P.VIN=C.vin
left join #Entradasvin V
on C.VIN=V.VIN
left join #TiempoPromedio TP
on c.NoDocumento=TP.NoDocumento
--138076

Select *
from  Temporales.dbo.PrimerVehiculoCol
ORDER BY Cantidad	desc	

Select sum(Entradas),sum(Entradas2)
from  Temporales.dbo.PrimerVehiculoCol

Select Recompro,count(*)
from Temporales.dbo.RFM_VentasCol
group by Recompro

---------------------------------------------------------------------------------------------