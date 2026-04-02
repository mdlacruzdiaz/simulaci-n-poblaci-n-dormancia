using Plots, DataFrames, CSV, Statistics, Dates
using Plots.Measures

# 1. carga de datos
ruta_archivo_1 = raw"C:\Users\marta\OneDrive\Escritorio\juls\data\evol_alpha_2026-03-18_22-30-48.csv"

df1 = CSV.read(ruta_archivo_1, DataFrame)

println("Datos cargados exitosamente.")
println("Filas totales:   $(nrow(df1))")

# 2. EXTRACCIÓN DE DATOS PARA LA LEYENDA
println("Extrayendo parámetros de la simulación...")

# unique() saca los valores sin repetir. join() los une en texto por si hubieras corrido varios a la vez.
val_sigma = join(unique(df1.sigma), ", ")
val_delta = join(unique(df1.amplitud_mutacion), ", ")
val_tau = 1.5 # Escribe aquí directamente tu valor de tau

# 3. GRAFICAR

println("Generando gráfica")

p = scatter(
    df1.alpha_inicial,     # Datos del eje X
    df1.alpha_final,       # Datos del eje Y
    title = "Distribución de Alphas: Inicial vs Final",
    label = "Individuos",  # Nombre que aparecerá en la leyenda principal
    
    # Configuraciones de los puntos
    markeralpha = 0.05,    # Transparencia: 0.0 (invisible) a 1.0 (sólido). ¡Ajusta este valor!
    markerstrokewidth = 0, # Quitamos el borde negro del punto para que se mezclen mejor
    markersize = 3,        # Tamaño del punto
    color = :blue,         # Color de los puntos
    
    # Si tus alpha_inicial están muy separados (ej. 0.001 y 10.0), descomenta la siguiente línea:
    xaxis = :log10,
    yaxis = :log10,
    
    legend = :outertopright,
    size = (900, 700),
    dpi = 300,
    bottom_margin = 25mm,  # Aumentamos un poco el margen para que quepa la nota de parámetros    
    left_margin = 5mm
)

todos_los_alphas = vcat(df1.alpha_inicial, df1.alpha_final)
min_abs = minimum(todos_los_alphas)
max_abs = maximum(todos_los_alphas)

# B. Añadir línea diagonal (y = x) - Marca "Sin Mutación"
# Usamos plot! con [min, max] para X y [min, max] para Y
plot!(p, [min_abs, max_abs], [min_abs, max_abs],
      label = "Sin mutación (y=x)",
      color = :black,       # Color neutro
      linestyle = :dash,    # Línea discontinua (guiones)
      alpha = 0.3,          # Súper traslúcida como pediste
      lw = 1.5              # Grosor de línea
)

# C. Añadir línea horizontal en Tau
# hline! es específica para líneas horizontales
hline!(p, [val_tau],
       label = "Umbral Tau (τ)",
       color = :gray40,     # Gris un poco más claro que negro
       linestyle = :dot,     # Línea punteada (para diferenciarla)
       alpha = 0.3,          # Súper traslúcida
       lw = 1.5
)


# Creamos el texto de la nota con los parámetros extraídos
nota = "Configuración: Sigma (σ) = $val_sigma | Delta (δ) = $val_delta | Tau (τ) = $val_tau"

# Añadimos las etiquetas de los ejes y colamos la nota en el xlabel como hacías antes
xlabel!(p, "Alpha Inicial\n\n" * nota)
ylabel!(p, "Alpha Final")

# 4. GUARDAR RESULTADO
plots_folder = "C:/Users/marta/OneDrive/Escritorio/juls/dormancia/plots" 
mkpath(plots_folder)

timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
outfile = joinpath(plots_folder, "alphas_scatter_$(timestamp).png")

savefig(p, outfile)
println("Gráfica combinada guardada en: $outfile")