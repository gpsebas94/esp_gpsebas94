
SELECT *
FROM GM_ECU.dbo.VentasECU
where Valor_Total = '2449020'

SELECT top 1000*, [Valor Neto],cast(replace(replace(replace([Valor Neto],right(trim([Valor Neto]),3),''),'S/',''),',','') as bigint)
FROM GM_ECU.dbo.VentasOrigenECU

SELECT *
FROM GM_ECU..ClientesECU

SELECT *
FROM GM_ECU..Distribuidores

SELECT * 
FROM GM_ECU..ClientesCalc

SELECT * 
FROM GM_ECU..Vehiculos
where Vehiculos_id = 594


DROP TABLE IF EXISTS #ventasECU
SELECT *
INTO #ventasECU
FROM(
	SELECT v.VentasECU_Id, v.VIN, v.ClientesECU_Id, c.Nombre1, c.Apellido1,C.Razon_Social, c.Correo, c.Tel_Celular,
		CASE WHEN l.EsEmpresaCalc_Livianos=1 THEN 'Empresa' WHEN  l.EsEmpresaCalc_Livianos=0 THEN 'Natural' END 'Tipo Persona', 
		d.BAC, d.Nombre_Distribuidor Dealer, d.Nombre_Corto,d.Provincia ,h.Modelo_Corto, C.NoDocumento,
			ROW_NUMBER() over(partition by Vin order by v.fecha_venta desc) OrdenVin,
			v.Fecha_Venta, h.Modelo_Completo,h.Segmento,h.KMAT,
		CASE WHEN C.Genero ='M' THEN 'Masculino' WHEN c.Genero='F' THEN 'Femenino' ELSE 'No Registra' end Genero,
		CASE WHEN	cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) is null THEN 'No registra'
		 WHEN cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) between 18 And 24 THEN '18 a 24 años'
		 WHEN cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) between 25 And 34 THEN '25 a 34 años'
		 WHEN cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) between 35 And 44 THEN '35 a 44 años'
		 WHEN cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) between 45 And 54 THEN '45 a 54 años'
		 WHEN cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) between 55 And 64 THEN '55 a 64 años'
		 WHEN cast(DATEDIFF(yy,Fecha_nacimiento,getdate()) as varchar) >=65 THEN 'Mayor a 65 años'  end Edad,
		year(Fecha_Venta) AñoVenta,V.uso,V.Forma_Pago,V.Tipo_Venta,cast(V.Valor_Neto as bigint) Valor_Neto,CAST(V.valor_total AS BIGINT) valor_total,C.ciudad,
		/*cast(replace(replace(replace([Valor Neto],right(trim([Valor Neto]),3),''),'S/',''),',','') as bigint) Valor_Neto_Corregido,cast(replace(replace(replace([Valor Total],right(trim([Valor Total]),3),''),'S/',''),',','') as bigint) Valor_Total_Corregido,*/
		CASE WHEN forma_pago ='Contado' THEN 'CONTADO'	WHEN forma_pago like '%CREDITO%' THEN 'CREDITO' ELSE 'OTRO' end forma_pago2,
			CASE WHEN V.Tipo_Venta ='Cliente Final' THEN 'CLIENTE FINAL'
		WHEN V.Tipo_Venta like '%Flota%' THEN 'FLOTA'
		WHEN V.Tipo_Venta like '%Empresa%' THEN 'EMPRESA'	ELSE 'OTROS' end Tipo_Venta2,
		case WHEN h.segmento in ('TRUCKS','BUS') THEN 'Pesados' ELSE 'LIVIANOS' end SegmentoVehiculo	
	FROM GM_ECU.dbo.VentasECU v		
	LEFT JOIN GM_ECU..ClientesECU C
	 ON C.ClientesECU_Id = v.ClientesECU_Id
	/*LEFT JOIN GM_ECU.dbo.VentasOrigenECU vo
	 ON v.VentasECU_Id = vo.VentasECU_Id*/
	LEFT JOIN GM_ECU..Distribuidores D
	 ON D.Distribuidores_id = V.Distribuidores_id
	LEFT JOIN GM_ECU..Vehiculos H
	 ON H.Vehiculos_id = V.Vehiculos_id
	LEFT JOIN GM_ECU..ClientesCalc l
	 ON l.ClientesECU_Id = C.ClientesECU_Id			
	WHERE v.Estado_Cupon = 'Activo'
	and d.Nombre_Distribuidor not like '%direct%sale%'
	 --AND v.Fecha_Venta <= '2020-12-31'
)A
WHERE OrdenVin = 1
--440006

select *
from #ventasECU


--Todas las ventas de clientes de Livianos con los filtros solicitados
drop table if exists #baseClientes
Select *
into #baseClientes
from #ventasECU
where AñoVenta>=2016 and [Tipo Persona]='Natural' and Segmento not in ('SINSEGM','TAXI','TRUCKS','BUS')
and convert(nvarchar(7),Fecha_venta,126)<='2021-10'
--96771

Select *--distinct segmento,modelo_corto 
from #baseClientes
order by segmento,modelo_corto 



----------------------------------------------------------------------------------------------
--------------------------------Ajuste valores por KMAT ------------------------------------------------

SELECT *
FROM Inxait.dbo.IPC_ECU



--alter table #baseClientes add ValorNeto bigint 
alter table #baseClientes add ValorTotal bigint 

update b
set ValorTotal=replace(cast(cast(Valor_Total as bigint)*cast(I.Ipc_Acumulado as float) as bigint),right(cast(cast(Valor_Total as bigint)*cast(I.Ipc_Acumulado as float) as bigint),2),'')--, 
--select ValorTotal,cast(cast(Valor_Total as bigint)*cast(I.Ipc_Acumulado as float) as bigint),replace(cast(cast(Valor_Total as bigint)*cast(I.Ipc_Acumulado as float) as bigint),right(cast(cast(Valor_Total as bigint)*cast(I.Ipc_Acumulado as float) as bigint),2),'')
--ValorNeto=cast(cast(Valor_Neto as bigint)*cast(I.Ipc_Acumulado as float) as bigint)
--select ValorTotal,cast(I.Ipc_Acumulado as float),cast(Valor_Total as bigint),cast(cast(Valor_Total as bigint)*cast(I.Ipc_Acumulado as float) as bigint)
from #baseClientes b
left join Inxait.dbo.IPC_ECU I
on B.añoVenta=I.Año
--96771

update #baseClientes 
set ValorTotal=replace(Valor_Total,right(Valor_Total,2),'')--,ValorNeto=Valor_Neto
--select Valor_Total,replace(Valor_Total,right(Valor_Total,2),'')
--from #baseClientes
where añoVenta=2021
--9610

Select top 10 *
from #baseClientes

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
--135

drop table if exists #P90
Select KMAT,max(ValorTotal) P90
into #P90
From (
Select *,NTILE(10) over(partition by KMAT order by cast(ValorTotal as bigint) ) PerValor_Neto
from #baseClientes) a
where a.PerValor_Neto=9
group by KMAT
--114



Select Modelo_Corto,P2.*,P7.P90,Prom_Valor_Total,st_VLtotal
from #P10 P2
left join #P90 P7
on P2.KMAT=P7.KMAT
left join (Select KMAT ,avg(ValorTotal) Prom_Valor_Total,stdev(ValorTotal) st_VLtotal
from #baseClientes
group by KMAT) M
on P2.KMAT=M.KMAT
order by 1
--114


--consulta para ver los precios por modelo PERCENTIL DEL 1 AL 100
Select Modelo_corto,PerValor_Neto,max(ValorTotal) p10
From (
Select *,NTILE(100) over(partition by Modelo_Corto order by cast(ValorTotal as bigint)) PerValor_Neto
from #baseClientes
where Modelo_Corto like '%ORLANDO%'
) a
group by Modelo_corto,PerValor_Neto


-----------------------------------------------------------------------------------
---Estos son los limites inferior y superior definidos segun las consultas anteriores anteriores ()
-- Para definirlo se tuvieron en cuenta los percentiles 
--Existe un excel donde se evidencian los valores propuestos



Select *
from Inxait.dbo.VEECU_PreciosEstandarizados
--133

/*
UPDATE Inxait.dbo.VEECU_PreciosEstandarizados
SET LI = replace(LI,right(LI,2),''),
LS = replace(LS,right(LS,2),'')
*/

--alter table #baseClientes add ValorNeto bigint 
alter table #baseClientes add MontoTotal bigint 


update b
set MontoTotal=case when ValorTotal <P.LI and cast(cast(Valor_Neto as bigint)*cast(I.Ipc_Acumulado as float) as bigint) between LI and LS  then cast(cast(Valor_Neto as bigint)*cast(I.Ipc_Acumulado as float) as bigint) 
when ValorTotal <P.LI  then LI 
when ValorTotal >P.LS then LS else ValorTotal end
 from #baseClientes b
left join Inxait.dbo.VEECU_PreciosEstandarizados P
on B.KMAT=P.KMAT
left join Inxait.dbo.ipc I
on B.añoVenta=I.Año
--96771

Select top 100 *
from #baseClientes
order by MontoTotal  desc



Select *
from #baseClientes




--------------------------------------------------------------------------------------------------------------------
------------------------- Se genera la base de posventa------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

Select *--max(FechaSalidaCalc)
from GM_ECU.dbo.PostVentaOrigenECU

drop table if exists #BasePostVentaDetalle
SELECT *
into #BasePostVentaDetalle
	FROM GM_ECU.dbo.PostVentaOrigenECU
where FechaSalidaCalc>='2016-01-01' and FechaSalidaCalc<='2021-10-31' 
and LEN(Vin)=17 and vin<>'No informa'
--and ( try_cast(MecanicaRapida as int)=1 or Try_cast(MecanicaEspecializada as int)=1) 
--2032403

Select top 10 *
from #BasePostVentaDetalle

drop table if exists #entradaventaposventa
Select P.PostVentaOrigenECU_Id,V.VIN,P.odometro,V.Segmento,V.Modelo_Corto,V.Fecha_Venta,P.FechaSalidaCalc,V.NoDocumento,P.cedulaLimpia,
UPPER(tipo_servicio) Tipo_Servicio,
case when inxait.dbo.fn_LimpiarCadena(odometro, '^A-Z')<>'' then null
when try_cast(odometro as float) is null then cast(replace(replace(STUFF(odometro, 1, PATINDEX('%[^$]%', odometro) - 1, ''),'.','') ,',','.') as float)
else odometro end Km
into #entradaventaposventa
from #baseClientes V
inner  join #BasePostVentaDetalle P
on V.VIN=p.vin
where cast(fecha_Venta as date) < cast(FechaSalidaCalc as date)
--408906

Select count(*),count(distinct concat(Vin,odometro,FechaSalidaCalc)),count(distinct concat(Vin,odometro)),count(distinct concat(Vin,FechaSalidaCalc))
from #entradaventaposventa


Select Vin,odometro,Tipo_Servicio,count(*)
from #entradaventaposventa
group by Vin,odometro,Tipo_Servicio having(count(*)>1)

Select *
from #entradaventaposventa
where VIN='1G1F91R71G0180291'
order by FechaSalidaCalc

drop table if exists #mecanicarapida
Select *
into #mecanicarapida
from  (
Select *,ROW_NUMBER() over(partition by Vin,odometro,Tipo_Servicio order by FechaSalidaCalc desc ) OrdenKM
from (
Select *,ROW_NUMBER() over(partition by Vin,FechaSalidaCalc,Tipo_Servicio order by odometro desc ) ORdenFecha
from #entradaventaposventa) a 
where ORdenFecha=1 
) b
where B.OrdenKM=1
--380781

Select top 10 *
 from #mecanicarapida

 Select Tipo_Servicio,count(*)
 from #mecanicarapida
 group by Tipo_Servicio

drop table if exists #EntradasPV
Select VIN,cedulaLimpia,COUNT(*) Entradas,max(FechaSalidaCalc) UltimaEntrada
into #EntradasPV
from #mecanicarapida
where Tipo_Servicio in ('MECANICA','MANTENIMIENTO')
group by VIN,cedulaLimpia 
--114843

drop table if exists #EntradasVIN
Select VIN,COUNT(*) Entradas,max(FechaSalidaCalc) UltimaEntrada
into #EntradasVIN
from #mecanicarapida
group by VIN
--79250

Select count(*),count(distinct VIN)
from #EntradasPV
-- 43149	33480

--------------------------------------------------------------------------------------------------------------------
------------------------- Se genera la base de MEtricas------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


drop table if exists #metricas
SELECT *
into #metricas
FROM(
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
where Cuentas_Id=200 and Medio='Email'
and P.FechaEnvio is not null and cast(Envio as int)=1 ) a
where OrdenEnvio<=10
--3.096.964


drop table if exists #metricasEmail
Select NoDocumento,Count(*) Registros,sum(cast(Envio as int)) Envio,
sum(cast(Aperturas as int)) Aperturas,sum(cast(Clicks as int))  clicks
into #metricasEmail
from #metricas
where NoDocumento is not null
group by NoDocumento
--548.983


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
where Cuentas_Id=200 and Medio='SMS'
and P.FechaEnvio is not null and cast(Envio as int)=1 ) a
where OrdenEnvio<=10
--637.200


drop table if exists #metricasSMS
Select NoDocumento,Count(*) Registros,sum(cast(Envio as int)) Envio,
sum(cast(Aperturas as int)) Aperturas,sum(cast(Clicks as int))  clicks
into #metricasSMS
from #metricas2
where NoDocumento is not null
group by NoDocumento
--275.600



--------------------------------------------------------------------------------------------------------------------
------------------------- Se genera la base de Ventas------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


Select forma_pago,forma_pago2,count(*) 
from #baseClientes 
group by forma_pago,forma_pago2

drop table if exists #Uso
Select NoDocumento,[Particular], [Comercial],[OTRO]
into #Uso
from (Select NoDocumento,Vin,uso from #baseClientes ) p
pivot (count(Vin) 
for uso  in ([Particular], [Comercial],[OTRO])) AS PVT
order by PVT.NoDocumento 
--91431

drop table if exists #FormaPago
Select NoDocumento,[CONTADO],[CREDITO], [OTRO]
into #FormaPago
from (Select NoDocumento,Vin,forma_pago2 from  #baseClientes  ) p
pivot (count(Vin) 
for forma_pago2  in ([CONTADO], [LEASING],[CREDITO], [OTRO])) AS PVT
order by PVT.NoDocumento 
--91431


--------------------------------------------------------------------------------------------------------------------
------------------------- base de clientes------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------


drop table if exists #Clientes
Select ClientesECU_Id,C.NoDocumento,[Tipo persona],genero,edad,count(*) Cantidad,sum(MontoTotal) MontoTotal,max(C.Fecha_venta) UltimaFechaVenta,
sum(iif(P.VIN is not null,P.entradas,0)) Entradas,sum(iif(V.VIN is not null,V.entradas,0)) Entradas2,sum(iif(P.VIN is not null,1,0)) VinEntrada
into #Clientes
from #baseClientes C
left join #EntradasPV P
on C.NoDocumento=P.cedulaLimpia and P.VIN=C.vin
left join #EntradasvIN V
on C.VIN=V.VIN
group by ClientesECU_Id,C.NoDocumento,[Tipo persona],genero,edad
--91421

Select count(*),count(distinct ClientesECU_Id),count(distinct NoDocumento),sum(Entradas),sum(Entradas2)
from #Clientes


alter table #Clientes add cliente nvarchar(max)
alter table #Clientes add city nvarchar(max)
alter table #Clientes add Region nvarchar(max)
--Select top 10 * from GM_ECU..VentasOrigenECU V

update C
set cliente=Contacto,
city=Ciudad,
Region = Región
from #Clientes C
inner join GM_ECU..VentasOrigenECU V
on V.ClientesECU_Id=C.ClientesECU_Id
--91421

select *
from #Clientes

select *
from GM_ECU..VentasOrigenECU 


select *
from  GM_ECU.dbo.ClientesECU

update C
set cliente=CONCAT(Nombre1,' ',Apellido1)
from #Clientes C
inner join GM_ECU.dbo.ClientesECU V
on V.ClientesECU_Id=C.ClientesECU_Id
where cliente is null
--11


drop table if exists #Modelo
Select NoDocumento,Modelo_Completo,Modelo_Corto,Ciudad,Dealer
into #Modelo
from (
Select *,ROW_NUMBER() over(partition by NoDocumento order by Fecha_venta desc) orden3
	from #baseClientes
--	and AñoVenta between 2011 and 2018
	) a
where a.Orden3=1
--91421


drop table if exists #Contactabilidad
Select distinct ClientesECU_Id,V.NoDocumento,case when v.correo is null then 'Sin Correo' when c.EsValido=1 then 'Valido' when c.EsValido=0 then 'No Valido' else 'Sin Validar' end EmailValido,
case when v.tel_celular is null then 'Sin Celular'  else 'ValidoSMS' end CelularValido, 
case when l.ListaNegraGM_Id is null then '' else 'En lista negra' end ListaNegra
into #Contactabilidad
from #baseClientes v
left join inxait.dbo.CorreosValidados c
on v.correo= c.Correo
left join inxait.dbo.ListaNegraGM l
on v.Correo = l.Correo
--91421


drop table if exists #VentasAntiguas
Select NoDocumento,count(*) Ventas
into #VentasAntiguas
from #ventasECU
where AñoVenta<=2015 and [Tipo Persona]='Natural' and Segmento not in ('SINSEGM','TAXI','TRUCKS','BUS')
group by NoDocumento
--137782

--------------------------------------------------------------------------------------------------------------------
------------------------- Se consolida la base final------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

Select top 10 * from #Clientes
order by cast(NoDocumento as bigint) desc

drop table if exists Temporales.dbo.RFM_VentasECU
Select V.ClientesECU_Id,V.NoDocumento,V.cliente,V.[Tipo Persona],V.Genero,V.Edad,v.CITY CiudadCliente,Ciudad CiudadDealer,Region,Dealer,Modelo_Completo,Modelo_Corto,MontoTotal,V.UltimaFechaVenta,
v.Cantidad Ventas,isnull(A.Ventas,0) VentasAntiguas,Year(V.UltimaFechaVenta) AñoVenta,
[Particular], [Comercial],[CONTADO], [CREDITO],datediff(mm,V.UltimaFechaVenta,'2021-10-31') RecenciaVenta,Entradas,VinEntrada,Entradas2,
case when datediff(mm,V.UltimaFechaVenta,getdate())>25 then 'Si' else 'No' end [Sin ventas Recientes],
case when Cantidad>1 then 'Si' else 'No' end [Recompro],
		ISNULL(E.ENVIO,0) EnvioEmail,ISNULL(E.Aperturas,0) AperturaEmail,
				ISNULL(m.ENVIO,0) EnvioSms,ISNULL(M.clicks,0) ClickSMS,
				case when E.NoDocumento is null and M.NoDocumento  is null then 'Email/SMS'
				when E.NoDocumento is null then 'Email'
				when  M.NoDocumento  is null then 'SMS' else 'Enviado' end SinEnvio,
				t.EmailValido,t.CelularValido,t.ListaNegra
into Temporales.dbo.RFM_VentasECU
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
--91421

--Cuantos clientes tienen ventas antes del 2015
Select count(*),sum(Ventas)
from Temporales.dbo.RFM_VentasECU
where VentasAntiguas>0
-- 10539	11819

--Cuantas clientes tienen entradas a la posventa
Select count(*),sum(VinEntrada)
from Temporales.dbo.RFM_VentasECU
where Entradas>0
-- 50273	51765

--Cuantos no se les ha enviado comunicacion en el ultimo año
Select SinEnvio,count(*)
from Temporales.dbo.RFM_VentasECU
group by SinEnvio
order by SinEnvio


Select count(*),count(distinct NoDocumento),sum(Ventas),sum(Entradas),sum(entradas2),
min(UltimaFechaVenta),max(UltimaFechaVenta),sum(AperturaEmail),sum(ClickSMS)
from Temporales.dbo.RFM_VentasECU

Select SinEnvio,EmailValido,CelularValido,ListaNegra,count(*)
from Temporales.dbo.RFM_VentasECU
group by SinEnvio,EmailValido,CelularValido,ListaNegra
order by SinEnvio,EmailValido,CelularValido,ListaNegra



-------------------------------------------------------------------------------------------------
/*
Consulta del por que no se le ha enviado en el ultimo año
*/
Select *
from Temporales.dbo.RFM_VentasECU
where SinEnvio='Enviado' and EmailValido='Sin Correo'


Select *
from #baseClientes
where ClientesECU_Id=409509

Select *
from Campañas..Metricas m
inner join Campañas.dbo.basesdeenvio B
on M.BasesDeEnvio_Id=B.BasesDeEnvio_Id
inner join campañas.dbo.perfiles P
on P.perfiles_id=B.perfiles_id
inner join Campañas..Campañas C
on C.Campañas_id=P.Campañas_id 
where NoDocumento='1105667842'
and  Cuentas_Id=200


Select *--top 10 *
from GM_ECU.dbo.ClientesECU
where ClientesECU_Id=176225

Select *--top 10 *
from inxait.dbo.ListaNegraGM
where Correo='JONATHANBYO92@HOTMAIL.COM'

Select top 10 *
from Campañas.dbo.Metricas
where Email='JONATHANBYO92@HOTMAIL.COM'

-------------------------------------------------------------------------------------------------
/*
Calculo de las variables que se utilizaran para definir el RFM / Se puede apoyar en R para sacar esos valores
*/


drop table if exists #VariablesRFM
Select ClientesECU_Id,MontoTotal,Ventas,RecenciaVenta Recencia,Ventas+Entradas+VentasAntiguas FreqAgr,Entradas,VentasAntiguas,
case when EnvioEmail is not null and EnvioEmail>0 then AperturaEmail*1.0/EnvioEmail else 0 end TasaApertura ,
NTILE(10) over(order by MontoTotal) Monto_score,
NTILE(10) over(order by RecenciaVenta desc) Recencia_score,
NTILE(10) over(order by Ventas) Facturas_score,
NTILE(10) over(order by Entradas) Entradas_score,
NTILE(10) over(order by VentasAntiguas) Antiguas_score,
NTILE(10) over(order by Ventas+Entradas+VentasAntiguas) Fac_score
into #VariablesRFM
from Temporales.dbo.RFM_VentasECU
--91421

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

Select Ventas,Entradas,VentasAntiguas,count(*)
from Temporales.dbo.RFM_VentasECU
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


Select PerValor_Neto,max(AperturaEmail*1.0/EnvioEmail) P90
From (
Select *,NTILE(10) over(order by AperturaEmail*1.0/EnvioEmail ) PerValor_Neto
from Temporales.dbo.RFM_VentasECU
where EnvioEmail is not null and EnvioEmail>0 ) a
group by PerValor_Neto

Select SinEnvio,count(*)
from Temporales.dbo.RFM_VentasECU
group by SinEnvio
order by SinEnvio


Select min(MontoTotal),max(MontoTotal)
from Temporales.dbo.RFM_VentasECU

Select min(MontoTotal),max(MontoTotal)
from Temporales.dbo.RFM_VentasCol


-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
/*
Categorizacion de las variables del RFM segun los resultados anteriores--Se utilizo una discretizacion del 50% y 80%
*/


drop table if exists #VariablesRFM_2
Select  ClientesECU_Id,nodocumento,Edad,Genero,CiudadCliente,Region,Modelo_Corto,UltimaFechaVenta,MontoTotal,Ventas,RecenciaVenta Recencia,Entradas,VentasAntiguas,
SinEnvio,EnvioEmail,EnvioSms,--EmailValido,CelularValido,
case when EnvioEmail is not null and EnvioEmail>0 then AperturaEmail*1.0/EnvioEmail else 0 end TasaApertura ,
case when EnvioSms is not null and EnvioSms>0 then ClickSMS*1.0/EnvioSms else 0 end TasaClicksSMS ,
case when Ventas+VentasAntiguas>=2   then 3 
	 when Ventas=1 and entradas>=2 then 2
	 when Ventas=1 and entradas<2 then 1 
	end frecuency_score,
case when RecenciaVenta <=27  then 3 
	 when RecenciaVenta <43  then 2 
	 when RecenciaVenta >=43  then 1 
	end recency_score,
case when MontoTotal >= 2850000 then 3 
	 when MontoTotal >= 1740000 then 2 
	 when MontoTotal < 1740000  then 1 end Monto_score,
case when Entradas >3  then 3 
	 when Entradas >= 1  then 2 
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
from Temporales.dbo.RFM_VentasECU
--91421


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
drop table if exists GM_ECU.DBO.VEECU_RFM_202110
Select *,
case when recency_score=3 then '0 a 27'
	 when recency_score=2 then '28 a 42'
	 when recency_score=1 then '43 a 69' 
	end Recency,
case when frecuency_score=1 then '1V - 1E'
	 when frecuency_score=2 then '1V + 2E'
	 when frecuency_score=3 then '2V +' 
	end frecuency,
case when Apertura_score=0 then 'Sin Envio'
	 when Apertura_score=1 then ' 0% '
	 when Apertura_score=2 then '10% - 40%'
	 when Apertura_score=3 then '41% - 60%'
	 when Apertura_score=4 then '61% - 100%' 
	end Aperturas,
case when CLICK_score=0 then 'Sin Envio'
	 when CLICK_score=1 then ' 0% '
	 when CLICK_score=2 then '10% - 40%'
	 when CLICK_score=3 then '41% - 60%'
	 when CLICK_score=4 then '60% - 100%' 
	end Click,
case when recency_score in (2,3) and frecuency_score in (3) then 'TOP'
	 when recency_score=3 and frecuency_score in (1,2) then 'MID'
	 when recency_score=2 and frecuency_score in (2) then 'MID' else 'LOW' 
	end SEGMENTORFM
into GM_ECU.DBO.VEECU_RFM_202110
from #VariablesRFM_2
--91421



--Consulta para extraer los datos y llevarlos a R para generar el mapa de calor
Select *
from GM_ECU.DBO.VEECU_RFM_202110

------------------------------------------------------------------------------------------------------
------Consulta de la base de ventas para caractezizar el publico del RFM
drop table if exists Temporales.dbo.baseventasRFM_ECU
Select R.*,Vin,BAC,Dealer,Nombre_Corto,Ciudad,b.Modelo_Corto ModeloVenta,Fecha_Venta,Segmento,forma_pago2,Uso
into Temporales.dbo.baseventasRFM_ECU
from GM_ECU.DBO.VEECU_RFM_202110 r
inner join #baseClientes b
on R.NoDocumento=B.NoDocumento
--96771

Select SEGMENTORFM,count(*)
from GM_ECU.DBO.VEECU_RFM_202110
group by SEGMENTORFM


Select Apertura_score,Aperturas,count(*)
from GM_ECU.DBO.VEECU_RFM_202110
where SEGMENTORFM='LOW'
group by Apertura_score,Aperturas
order by Apertura_score desc

Select CLICK_score,Click,count(*)
from GM_ECU.DBO.VEECU_RFM_202110
where SEGMENTORFM='LOW'
group by CLICK_score,Click
order by CLICK_score desc


Select Entradas_score,count(*),min(Entradas),max(Entradas)
from GM_ECU.DBO.VEECU_RFM_202110
where SEGMENTORFM='LOW'
group by Entradas_score
order by Entradas_score 


Select iif(VentasAntiguas=0,0,1),count(*)
from GM_ECU.DBO.VEECU_RFM_202110
where SEGMENTORFM='MID'
group by iif(VentasAntiguas=0,0,1)
order by iif(VentasAntiguas=0,0,1)



Select Region,[TOP], [MID], [LOW]
from (Select SEGMENTORFM,Region,ClientesECU_Id from Temporales.dbo.baseventasRFM_ECU) p
pivot(count(ClientesECU_Id)
for SEGMENTORFM in ([TOP], [MID], [LOW]) ) as pvt
order by PVT.Region

Select Segmento,[TOP], [MID], [LOW]
from (Select SEGMENTORFM,Segmento,ClientesECU_Id from Temporales.dbo.baseventasRFM_ECU) p
pivot(count(ClientesECU_Id)
for SEGMENTORFM in ([TOP], [MID], [LOW]) ) as pvt
order by PVT.Segmento

Select ModeloVenta,[TOP], [MID], [LOW]
from (Select SEGMENTORFM,ModeloVenta,ClientesECU_Id from Temporales.dbo.baseventasRFM_ECU) p
pivot(count(ClientesECU_Id)
for SEGMENTORFM in ([TOP], [MID], [LOW]) ) as pvt
order by PVT.ModeloVenta

Select case when Ventas+VentasAntiguas>=3 then '3' when Ventas+VentasAntiguas=2 then '2' else '1' end,count(*)
from GM_ECU.DBO.VEECU_RFM_202110
group by case when Ventas+VentasAntiguas>=3 then '3' when Ventas+VentasAntiguas=2 then '2' else '1' end


Select case when Ventas>=3 then '3' when Ventas=2 then '2' else '1' end,count(*)
from GM_ECU.DBO.VEECU_RFM_202110
group by case when Ventas>=3 then '3' when Ventas=2 then '2' else '1' end

Select case when Entradas>=6 then '3' when Entradas>=3 then '2' else '1' end,count(*)
from GM_ECU.DBO.VEECU_RFM_202110
group by case when Entradas>=6 then '3' when Entradas>=3 then '2' else '1' end


------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
--- Consulta para llenar la tabla del RFM
Select recency_score,[1], [2], [3]
from (Select frecuency_score,recency_score,ClientesECU_Id from #VariablesRFM_2) p
pivot(count(ClientesECU_Id)
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



