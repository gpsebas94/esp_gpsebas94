# 📊 Análisis RFM y Segmentación de Clientes - Chevrolet Ecuador

Este proyecto fue desarrollado para **Chevrolet Ecuador** con el objetivo de caracterizar a sus clientes mediante análisis de recencia, frecuencia y monto (RFM), optimizando la segmentación para campañas de retención y posventa. A partir de bases de datos transaccionales, se realizaron cruces, transformaciones y visualizaciones que permitieron identificar patrones de comportamiento por zonas, modelos de vehículos y tipo de cliente.

---

## 🎯 Objetivo del Proyecto

Analizar el comportamiento de los clientes de Chevrolet con base en su historial de compras y posventa, mediante un modelo de **segmentación RFM**. Se buscó:

- Identificar grupos de clientes según su valor para la compañía.
- Establecer zonas y modelos con mayor retención.
- Relacionar comportamiento con efectividad de campañas de email y SMS.
- Recomendar estrategias de fidelización por segmento.

---

## 🧠 ¿Qué es el Modelo RFM?

El modelo **RFM (Recency, Frequency, Monetary)** es una técnica de segmentación de clientes que clasifica a los usuarios según:

- **Recency (R)**: Hace cuántos meses realizó la última compra o visita el cliente.
- **Frequency (F)**: Número de veces que ha comprado o ha realizado visitas en un periodo determinado.
- **Monetary (M)**: Cuánto ha gastado el cliente en total o en promedio.

Este enfoque permite identificar distintos tipos de clientes según su comportamiento:

- **TOP**: Clientes frecuentes, con compras recientes y alto valor monetario. Representan el segmento más rentable y con mayor fidelidad.
- **MID**: Clientes intermedios, con frecuencia moderada o valor medio. Pueden ser fidelizados con estrategias adecuadas.
- **LOW**: Clientes inactivos o de bajo valor, que requieren estrategias de reactivación o se consideran de baja prioridad.

El análisis RFM es ampliamente usado en marketing y CRM para personalizar campañas, optimizar recursos y mejorar la rentabilidad de las acciones comerciales.

---

## 🛠 Tecnologías utilizadas

- **SQL Server**: Extracción y transformación de datos transaccionales y demográficos. [`Script sql`](scripts/ConsultaClientes.sql)
- **R**: Desarrollo de mapas de calor, visualizaciones y validaciones estadísticas. [`Script R`](scripts/MapadeCalorRFM_col.R)
---

## 📁 Estructura del repositorio
```
/proyectos/Modelo_RFM_Chevrolet_Ecuador/
│
├── scripts/
│ ├── MapadeCalorRFM_col.R
│ └── ConsultaClientes.sql
│
├── images/
│ ├── 01_RFM_Mapa_de_Calor.png
│ ├── 02_Caracterizacion_RFM_TOP.png
│ ├── 03_Caracterizacion_RFM_MID.png
│ ├── 04_Caracterizacion_RFM_LOW.png
│ └── 05_Caracterizacion_RFM_Concesionarios.png
│
├── README.md
```

---

## 📌 Resultados Destacados

### 1. Mapa de Calor RFM  
  Segmentación en clientes **TOP**, **MID** y **LOW** en función de sus compras y frecuencia.
  ![RFM_Mapa](images/01_RFM_Mapa_de_Calor.jpg)  
  
---

### 2. Caracterización RFM por zona y modelo de vehículo  
  Distribución regional y por modelo según grupos RFM.
  ![Concesionarios](images/05_Caracterizacion_RFM_Concesionarios.jpg)  

---

### 3. Perfilamiento de Clientes

- **Clientes TOP**  
  ![RFM_TOP](images/02_Caracterizacion_RFM_TOP.jpg)

- **Clientes MID**  
  ![RFM_MID](images/03_Caracterizacion_RFM_MID.jpg)

- **Clientes LOW**  
  ![RFM_LOW](images/04_Caracterizacion_RFM_LOW.jpg)

---

## 📝 Conclusiones Estratégicas

### 📈 Hallazgos Clave

- El 65% de los clientes pertenece al grupo LOW, con bajo compromiso.
- El segmento TOP (9%) muestra alta fidelidad y respuesta efectiva a campañas.
- Hay una correlación positiva entre entradas a posventa y engagement en campañas.

### 🎯 Recomendaciones de Segmentación

- **TOP**: Implementar programas de fidelización VIP con recompensas por permanencia.
- **MID**: Aplicar campañas personalizadas y seguimiento post-servicio para fortalecer vínculo.
- **LOW**: Usar estrategias de reactivación gradual (promociones, descuentos, contacto escalonado).

---

## ⚠️ Nota Legal
*Los datos y visualizaciones presentados en este proyecto están destinados únicamente a fines académicos y demostrativos. Toda la información confidencial ha sido procesada para cumplir con estándares de privacidad y ética profesional.*

---

## 👤 Autor
**Sebastián González**  
Data Scientist 

> Proyecto desarrollado como parte del equipo de Data de INXAIT.
