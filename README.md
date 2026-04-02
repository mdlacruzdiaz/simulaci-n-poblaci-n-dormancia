# simulacion-poblacion-dormancia

## 📖 Sobre el Proyecto
Este repositorio contiene el código desarrollado durante mi colaboración en _____. El objetivo principal es el modelado computacional y análisis estadístico del crecimiento de una población de individuos.

El proyecto explora cómo evoluciona la densidad de población o el tiempo de dormancia desde que se crean hasta que pasan a ser individuos activos afectados por las condiciones variables del sistema.

## 🛠️ Tecnologías y Librerías Utilizadas
* **Lenguajes:** Julia
* **Entornos:** Jupyter Notebooks, Spyder, VSCode
* **Librerías principales:** Random, Distributed, Plots, DataFrames, CSV, Statistics, Dates

## 📂 Estructura del Repositorio
A continuación, se detalla el contenido de los archivos principales:

* `universo_pro.jl`: Script base que contiene la lógica matemática y las funciones del universo y del comportamiento de los individuos.
* `Dormancia.ipynb`: Cuaderno de Jupyter con la ejecución paso a paso del modelo, tratamiento de los datos generados y visualización de resultados.
* `superv_pro.jl`: Script que ejecuta las simulaciones dentro de las reglas definidas por 'universo_pro.jl' y que recolecta datos que permiten visualizar la evolución de la población media durante el tiempo.
* `evol_alpha.jl`: Script que ejecuta las simulaciones dentro de las reglas definidas por 'universo_pro.jl' y que recolecta datos que permiten visualizar la tendencia de los valores de dormancia como resultado de la mutación de este gen por generaciones.
* `plot_02.jl`: Script que grafica los datos generados por 'superv_pro.jl'.
* `plot_evol_alpha_01.jl`: Script que grafica los datos generados por 'evol_alpha.jl'.

## ⚙️ Cómo ejecutar el código
Para probar estas simulaciones en tu equipo local:
1. Clona este repositorio.
2. Asegúrate de tener instaladas las librerías requeridas (puedes instalar todo ejecutando `pip install -r requirements.txt` si tienes este archivo, si no, bórralo).
3. Abre y ejecuta todas las celdas del archivo `Dormancia.ipynb`.
