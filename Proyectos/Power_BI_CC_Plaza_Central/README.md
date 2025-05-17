# Análisis de Comportamiento del Cliente en Centro Comercial Plaza Central

Este proyecto presenta un dashboard interactivo desarrollado en Power BI para analizar el comportamiento del cliente del Centro Comercial Plaza Central, con base en la integración y análisis de datos provenientes del programa de fidelización "Soy Central", registros de facturación y métricas de campañas de comunicación.

---

## 🧭 Objetivo del Proyecto
Diseñar un Power BI para facilitar la **toma estratégica de decisiones** en el negocio, enfocándose en identificar hallazgos relevantes y evaluar el rendimiento del programa "Soy Central". Las principales preguntas que se buscan resolver son:

- ¿Cuál ha sido el comportamiento de los clientes en términos de compras y redenciones?
- ¿Qué tan efectivas han sido las campañas y canales de comunicación?
- ¿Qué categorías, marcas o segmentos muestran mayor o menor crecimiento?
- ¿Cómo se distribuyen geográficamente los clientes?

---

## 📅 Alcance Temporal y Periodicidad
- **Periodo de análisis:** Desde enero de 2019 hasta febrero de 2022.
- **Actualización esperada:** semanal, una vez finalizado el diseño.

---

## 🛠️ Herramientas y Datos Utilizados
- **Power BI:** herramienta principal para visualización y análisis [`Power BI.pbix`](./scripts/Power_BI.pbix).
- **SQL Server:** extracción, transformación y carga de datos (ETL) [`Script.sql`](./scripts/Ejecucion.sql).
- **Bases fuente:** Clientes "Soy Central", WiFi Plaza Central, métricas de campañas y registros de facturación.

---

## 📊 Estructura del Reporte

[`Imágenes Dashboard`](./images/)

### 1. Resumen General
- Clientes, registros de facturas, grupo etario, género, afinidad, tipo de cliente y comportamiento de compra.

### 2. Funnel de Campañas
- Seguimiento de campañas (envío, apertura, clic, conversión, ventas) con filtros por periodo y canal.

### 3. Funnel por Tipo de Comunicación
- Evaluación del desempeño de emails, SMS y otros tipos, con tasas de conversión por canal.

### 4. Engagement por Categoría
- Participación y conversión de clientes segmentados por categoría de campaña, filtrable por tiempo y canal.

### 5. Clientes y Facturas Registradas
- Comparativos por año de número de clientes, tipo de cliente (nuevo/recurrente), facturación total y ticket promedio.

### 6. Avance de Categorías
- Evolución mensual de categorías comerciales con comparativos interanuales.

### 7. Top y Bottom Marcas
- Análisis de marcas más y menos activas, con crecimiento o decrecimiento en ventas.

### 8. Redenciones y Central Coins
- Seguimiento al uso de premios, tipo de redención (catálogo, beneficio) y dinámica de uso de monedas (CentralCoins).

### 9. Georreferenciación
- Mapa de calor por localidad y segmentación por ubicación geográfica.

---

## 📂 Estructura del Repositorio
```
/proyectos/Power_BI_CC_Plaza_Central/
│ 
├── README.md
│                       
├── images/                           # Capturas de pantalla del dashboard
│ ├── 00_Panel_Principal
│ ├── 01_Resumen
│ ├── 02_Facturas_Registradas
│ ├── 03_Avance_Categorias
│ ├── 04_Top_Bottom_Marcas
│ ├── 05_Funnel_Campañas
│ ├── 06_Funnel_Tipo_Comunicacion
│ ├── 07_Engagement_Categoria
│ ├── 08_Redenciones
│ ├── 09_Georeferenciacion
│ ├── 10_Mix_Marcas
│ 
├── scripts/                          # Script de generación de tablas base y archivo .pbix
│ ├── Ejecucion.sql
│ ├── Power_BI.pbix
```

---

## 📌 Resultados Esperados
- Entregable en Power BI interactivo.
- Instrumento útil para áreas de mercadeo y dirección general del centro comercial.
- Actualización recurrente con base en estructura establecida.

---

## ⚠️ Nota Legal
*Los datos y visualizaciones presentados en este proyecto están destinados únicamente a fines académicos y demostrativos. Toda la información confidencial ha sido procesada para cumplir con estándares de privacidad y ética profesional.*

---

## 👤 Autor
**Sebastián González**  
Data Scientist 

> Proyecto desarrollado como parte del equipo de Data de INXAIT.

