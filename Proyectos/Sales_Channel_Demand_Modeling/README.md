# 📊 Sales Channel Demand Modeling - Colombia
En un entorno de ventas multicanal, comprender y predecir la demanda específica de cada canal es fundamental para optimizar inventarios, asignar recursos y diseñar estrategias de marketing efectivas. Este proyecto realizado para **Virgin Mobile Latinoamérica** reúne los análisis de datos históricos y los modelos predictivos aplicados a los diferentes canales de venta —Telesales, Digital, Direct Sales Force, Distribuidores Tradicionales, Kioskos, Own Stores, Punto Partner y Retail— de **Colombia** para ofrecer una visión consolidada de su comportamiento. Cada canal de venta recorre desde la extracción y limpieza de datos hasta el entrenamiento, evaluación y comparación de múltiples algoritmos de regresión.

---

## 🎯 Objetivo del Proyecto

- **Evaluar** características y comportamiento de la demanda/ventas en cada canal.
- **Comparar** algoritmos de regresión (Lineal, Árbol de Decisión, Random Forest, SVR, Pipelines con polinomios).
- **Identificar** factores más influyentes mediante correlaciones y PCA.
- **Recomendar** el modelo más robusto por canal y sugerir mejoras de feature engineering.

---

## 🔍 Métodos de Modelado
A continuación se presentan las principales técnicas utilizadas:

### Regresión Lineal (Ordinary Least Squares - OLS)

- Modelo lineal que asume una relación lineal entre las variables independientes (features) y la variable dependiente (target).
- Minimiza la suma de los errores al cuadrado (MSE) para ajustar los coeficientes.
- Adecuado cuando la relación entre variables es aproximadamente lineal.

### Árbol de Decisión (Decision Tree Regressor)

- Modelo no paramétrico que segmenta el espacio de features en regiones homogéneas mediante divisiones binarias.
- Construye un árbol donde cada nodo interno corresponde a una condición sobre un feature.
- Fácil de interpretar, pero susceptible a sobreajuste si no se controla la profundidad.

### Random Forest Regressor

- Ensamble de varios árboles de decisión entrenados con muestreo aleatorio (bagging) y selección aleatoria de features.
- Promedia las predicciones de cada árbol, reduciendo varianza y sobreajuste.
- Robusto y con buen rendimiento en datos con relaciones no lineales y ruido.

### Support Vector Regressor (SVR)

- Extensión de SVM para regresión, que busca una función que se ajuste a los datos con un margen de tolerancia (epsilon-insensitive loss).
- Puede usar diferentes kernels (lineal, polinómico, RBF) para capturar relaciones no lineales.
- Eficiente en espacios de alta dimensión, pero puede ser costoso computacionalmente en grandes conjuntos de datos.

### PCA (Análisis de Componentes Principales)

- Técnica de reducción de dimensionalidad que transforma variables correlacionadas en componentes ortogonales no correlacionados.
- Ordena las componentes según la varianza explicada y permite seleccionar las más relevantes.
- Utilizado previo al modelado para reducir ruido y redundancia, mejorando eficiencia.

---

## 🧪 Metodología
El proceso de análisis y modelado en este proyecto sigue una serie de pasos estandarizados para garantizar consistencia y reproducibilidad:

### Extracción de Datos
- Conexión a la base de datos mediante psycopg2 para extraer las tablas relevantes de ventas e indicadores.
- Carga de datos en dataframes de pandas.

### Limpieza y Transformación
- Identificación y tratamiento de valores faltantes (imputación o eliminación según caso).
- Conversión de tipos (fechas, categóricas) y creación de variables de tiempo (mes, trimestre).
- Filtrado de outliers mediante análisis de percentiles y boxplots.

### Análisis Exploratorio (EDA)
- Visualización de distribuciones (histogramas, boxplots).
- Cálculo de correlaciones y prueba de hipótesis (Pearson) para identificar relaciones lineales.
- Aplicación de PCA para entender la estructura de las variables y reducir dimensionalidad.

### Feature Engineering
- Escalado de variables numéricas con StandardScaler.
- Generación de términos polinómicos para capturar no linealidades.
- Codificación de variables categóricas según necesidad.

### Modelado Predictivo
- Definición de un conjunto de algoritmos base (OLS, Árbol de Decisión, Random Forest, SVR, Pipeline polinómico).
- División de datos en entrenamiento y prueba (train/test split).
- Ajuste de hiperparámetros básicos y validación cruzada para evaluar estabilidad.

### Evaluación de Modelos
- Cálculo de métricas: RMSE, MAE, R² y varianza explicada.
- Comparación de resultados en tablas y gráficos de dispersión predicción vs. real.

### Documentación de Resultados
- Registro de métricas y rankings de modelos en un dataframe consolidado.
- Visualización de importancias de features y componentes principales.

---

## 📁 Estructura del repositorio
```
Sales_Channel_Demand_Modeling/
├── notebooks/               # Carpeta con los nueve análisis por canal
│   ├── 01_general.ipynb     # Análisis combinado y preprocesamiento global
│   ├── 02_telesales.ipynb   # Canal Telesales
│   ├── 03_digital.ipynb     # Canal Digital
│   ├── 04_direct_sales_force.ipynb  # Canal Direct Sales Force
│   ├── 05_distribuidores_tradicionales.ipynb  # Canal Distribuidores Tradicionales
│   ├── 06_kioskos.ipynb     # Canal Kioskos
│   ├── 07_own_stores.ipynb  # Canal Own Stores
│   ├── 08_punto_partner.ipynb  # Canal Punto Partner
│   └── 09_retail.ipynb      # Canal Retail
├── .gitignore               # Ignora checkpoints y archivos temporales
└── README.md                # Documentación (este archivo)
```
### Descripción de los Notebooks
| Notebook                             | Descripción                                                                                          |
|--------------------------------------|------------------------------------------------------------------------------------------------------|
| [`01_general.ipynb`](notebooks/01_general.ipynb)                   | Extracción y limpieza global de datos, análisis exploratorio conjunto, pipeline de preprocesamiento común. |
| [`02_telesales.ipynb`](notebooks/02_telesales.ipynb)                 | EDA específico, comparativa de modelos, métricas (RMSE, MAE, R²).                                     |
| [`03_digital.ipynb`](notebooks/03_digital.ipynb)                   | Análisis de comportamientos online, transformaciones polinómicas, PCA en features digitales.         |
| [`04_direct_sales_force.ipynb`](notebooks/04_direct_sales_force.ipynb)        | Datos de fuerza de ventas directa, tuning de hiperparámetros, validación cruzada.                    |
| [`05_distribuidores_tradicionales.ipynb`](notebooks/05_distribuidores_tradicionales.ipynb) | Segmentación por tipo de distribuidor, correlaciones, boxplots, rendimiento de modelos estándar.     |
| [`06_kioskos.ipynb`](notebooks/06_kioskos.ipynb)                   | Variables geográficas y de punto, selección de features relevantes, comparación de Random Forest vs OLS. |
| [`07_own_stores.ipynb`](notebooks/07_own_stores.ipynb)                | Datos de tiendas propias, análisis estacional, modelos de regresión lineal avanzados.                |
| [`08_punto_partner.ipynb`](notebooks/08_punto_partner.ipynb)             | Comportamiento de partners, evaluación con SVR y árboles, análisis de errores.                       |
| [`09_retail.ipynb`](notebooks/09_retail.ipynb)                    | Visión general de retail, pipeline completo (EDA, PCA, modelado), matriz de comparación de desempeño. |

---

## 📌 Resultados Destacados

### Rendimiento de Modelos
- Random Forest obtuvo los mejores valores de RMSE y R² en la mayoría de canales.
- Canales lineales como Telesales muestran R² > 0.75 con OLS.
- Para Digital y Kioskos, pipelines polinómicos y SVR redujeron el error en 10–15%.

### Importance de Features
- Volumen histórico y variables de estacionalidad (mes, trimestre) son consistently top-features.
- Indicadores geográficos destacan en Own Stores y Kioskos.

### Reducción de Dimensionalidad
- PCA condensó variables correlacionadas manteniendo >95% de varianza explicada.
- Se redujo un 30% de features, agilizando entrenamientos.

### Recomendaciones
- Automatizar búsqueda de hiperparámetros con GridSearchCV o RandomizedSearchCV.
- Explorar ensamblados como XGBoost o LightGBM para canales complejos.
- Modificar notebooks a scripts modulares (src/) para facilitar despliegue.

---

## ⚠️ Nota Legal
*Los datos y visualizaciones presentados en este proyecto están destinados únicamente a fines académicos y demostrativos. Toda la información confidencial ha sido procesada para cumplir con estándares de privacidad y ética profesional.*

---

## 👤 Autor
**Sebastián González**  
Data Scientist 

> Proyecto desarrollado como parte del equipo de Data de Virgin Mobile Latinoamérica.
















