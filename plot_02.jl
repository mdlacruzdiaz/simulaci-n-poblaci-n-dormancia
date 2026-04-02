using Plots, DataFrames, CSV, Statistics, Dates
using Plots.Measures

ruta_archivo_1 = raw"C:/Users/marta/OneDrive/Escritorio/juls/dormancia/data\superv_2026-03-13_14-51-28.csv"

df1 = CSV.read(ruta_archivo_1, DataFrame)

println("Datos cargados exitosamente.")
println("Filas totales:   $(nrow(df1))")

# -----------------------------------------------------------------------------
# 3. PROCESAMIENTO (Agrupar y Promediar)
# -----------------------------------------------------------------------------
println("Calculando promedios...")

# -----------------------------------------------------------------------------
# 3. PROCESAMIENTO (Agrupar y Promediar)
# -----------------------------------------------------------------------------
println("Calculando promedios...")

# Agrupamos por 'initial_a' y 'time', y luego calculamos las medias
df_mean = combine(groupby(df1, [:initial_a, :time]), 
    :active_count => mean => :active_mean, 
    :seed_count => mean => :seed_mean
)

# Ahora esto funcionará, porque df_mean conservó las columnas por las que agrupamos
sort!(df_mean, [:initial_a, :time])



max_steps_sim = maximum(df1.time)
sigmas_encontrados = unique(df1.sigma)#lista de los sigmas repetidos solo una vez
# Si solo hay un sigma (lo normal), lo sacamos limpio. Si hay varios, los unimos con comas.
if length(sigmas_encontrados) == 1
    val_sigma = sigmas_encontrados[1]
else
    val_sigma = join(sigmas_encontrados, ", ") # Ej: "90.0, 100.0"
end

# -----------------------------------------------------------------------------
# 4. GRAFICAR (Igual que antes)
# -----------------------------------------------------------------------------
println("Generando gráfica combinada...")

unique_as = sort(unique(df_mean.initial_a))

# Calculamos los máximos para saber dónde colocar la nota
max_x = maximum(df_mean.time)
max_y = maximum(df_mean.active_mean) # Usamos el máx de activos como referencia de altura

p = plot(
    title = "Evolución de la población en el tiempo",
    xlabel = "Tiempo",
    ylabel = "Nº Individuos/Recursos",
    legend = :outertopright,
    size = (900, 700),
    dpi = 300,

    bottom_margin = 20mm,    
    left_margin = 5mm
)
R=1000
for (i, a_val) in enumerate(unique_as)
    sub_df = filter(row -> row.initial_a == a_val, df_mean)
    label_text = "a₀ = $(round(a_val, digits=4))"
    
    # Organismos (Sólida)
    plot!(p, sub_df.time, sub_df.active_mean/R, 
          lw = 1, linestyle = :solid, color = i, alpha=0.5,
          label = "$label_text (Org.)")
end

nota = "Configuración: Sigma = $val_sigma | tau=1 | b=1.0 | Duración = $max_steps_sim \n" * "Promedio de simulaciones sin mutación."

xlabel!(p, "Tiempo\n\n" * nota)
# -----------------------------------------------------------------------------
# 5. GUARDAR RESULTADO
# -----------------------------------------------------------------------------
# Guardamos la imagen en la carpeta plots
plots_folder = joinpath(dirname(ruta_archivo_1), "..", "plots") 

mkpath("C:/Users/marta/OneDrive/Escritorio/juls/plots")

timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
outfile = joinpath(plots_folder, "population_combined_$(timestamp).png")

savefig(p, outfile)
println("Gráfica combinada guardada en: $outfile")

