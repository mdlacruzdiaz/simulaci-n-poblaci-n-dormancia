using Distributed

# -----------------------------------------------------------------------------
# 1. CONFIGURACIÓN DE PROCESOS (Igual que en tu código anterior)
# -----------------------------------------------------------------------------
if nprocs() == 1
    # Añade procesos según los núcleos de tu CPU (deja uno libre para el sistema)
    addprocs(length(Sys.cpu_info()) - 2; exeflags="--project=.") 
end

@everywhere begin
    using Pkg
    Pkg.activate(".") 
    
    using DataFrames, CSV, Dates, Statistics, Distributed
    
    # Cargar tu simulación existente (NO modificamos este archivo)
    include(joinpath("universo_pro.jl"))

    # Rutas para guardar datos
    datadir(args...) = joinpath(dirname(@__DIR__), "data", args...)
end

# -----------------------------------------------------------------------------
# 2. DEFINICIÓN DE FUNCIONES DE RECOLECCIÓN (En todos los workers)
# -----------------------------------------------------------------------------
@everywhere begin
    
    function run_end_state_simulation(sigma, delta, initial_a, replicate_id, t_max)
        try
            println("Worker $(myid()): Running simulation with sigma=$sigma, initial_a=$initial_a, replicate=$replicate_id")
            #Iniciación de parámetros
            params = Universo.Parametros(
                1.001,      # b: tasa base reproducción (bajamos un poco b y d base porque ahora se multiplican por los recursos)
                1.0,      # d: death_rate base
                1000.0,   # R: Recursos totales (antes M)
                sigma,    # σ: res_σ (Variación del medio)
                1.5,      # τ: tau (Tiempo de oscilación)
                delta     # δ: Magnitud de mutación anulada
            )
            
            N_inicial = 1000
            alphas_iniciales = fill(initial_a, N_inicial)

            estado = Universo.Estado(0.0, true, alphas_iniciales, Float64[])
            
            while estado.t <= t_max && (!isempty(estado.activos_alphas) || !isempty(estado.semillas_alphas))
                Universo.paso_gillespie!(estado, params)
            end

            #comprobamos la extinción
            extinta=isempty(estado.activos_alphas) && isempty(estado.semillas_alphas)

            #Escribimos lo que queremos que nos devuelva (un NamedTuple)
            return (
                initial_a = initial_a,
                delta = delta,
                sigma = sigma,
                alphas_finales = estado.activos_alphas,
                extinta = extinta
            )
        
        catch e
            println("Error en worker $(myid()): $e")
            return (initial_a =initial_a, delta = delta, sigma = sigma, alphas_finales = Float64[], extinta = false)
        end
    end
end

# -----------------------------------------------------------------------------
# 3. EJECUCIÓN PRINCIPAL (Master Process)
# -----------------------------------------------------------------------------

# Parámetros del experimento
t_max_simulacion = 1000.0 # Duración de la simulación
sigma_fijo = 1.0  # valor de sigma
delta_fijo = 0.1        # Valor fijo de delta

# Rango de initial_a (escala logarítmica como en tu código anterior)
initial_a_values = 10.0 .^ LinRange(-1, 1.5, 10) # He puesto 5 para probar, sube este número
#initial_a_values=[0.001, 1.0, 5.0, 10.0]
n_replicates = 8 # Número de repeticiones por configuración

# Crear combinaciones de parámetros
param_combinations = [(sigma_fijo, delta_fijo, init_a, rep) 
                      for init_a in initial_a_values 
                      for rep in 1:n_replicates]

println("Iniciando simulaciones...")
println("Total simulaciones: $(length(param_combinations))")

# Ejecución en paralelo con pmap
# pmap asigna tareas a los workers disponibles dinámicamente
resultados_crudos = pmap(param_combinations) do (sigma, delta, init_a, rep)
    Base.invokelatest(run_end_state_simulation, sigma, delta, init_a, rep, t_max_simulacion)
end

# -----------------------------------------------------------------------------
# 4. REPORTE DE EXTINCIONES
# -----------------------------------------------------------------------------

println("\n--- REPORTE DE EXTINCIONES")
conteo_extinciones = Dict{Float64, Int}()
for a in initial_a_values
    conteo_extinciones[a] = 0
end

# Vectores pre-asignados para construir el DataFrame final de forma ultra rápida
col_alpha_inicial = Float64[]
col_amplitud_mutacion = Float64[]
col_alpha_final = Float64[]
col_sigma = Float64[]

# Recorremos los resultados de todas las simulaciones
for res in resultados_crudos
    # Si se extinguió, sumamos 1 al contador de ese alpha específico
    if res.extinta
        conteo_extinciones[res.initial_a] += 1
    end
    
    # Para cada alpha final del individuo sobreviviente, añadimos una fila a nuestros vectores
    # Si res.alphas_finales está vacío, este bucle no se ejecuta (0 filas añadidas, como querías)
    for alpha_indiv in res.alphas_finales
        push!(col_alpha_inicial, res.initial_a)
        push!(col_amplitud_mutacion, res.delta)
        push!(col_alpha_final, alpha_indiv)
        push!(col_sigma, res.sigma)
    end
end

# Imprimimos el reporte
for a in initial_a_values
    total_sims_a = n_replicates
    extintas_a = conteo_extinciones[a]
    println("Alpha inicial $a: Se extinguieron $extintas_a de $total_sims_a simulaciones.")
end
println("------------------------------\n")

# -----------------------------------------------------------------------------
# 4. GUARDADO DE DATOS
# -----------------------------------------------------------------------------

println("Construyendo tabla de datos final...")
df_final = DataFrame(
    alpha_inicial = col_alpha_inicial,
    amplitud_mutacion = col_amplitud_mutacion,
    alpha_final = col_alpha_final,
    sigma = col_sigma
)

# Generar nombre de archivo con fecha
timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
filename = datadir("evol_alpha_$(timestamp).csv")

println("Guardando CSV en: $filename")
mkpath(dirname(filename)) # Crea la carpeta si no existe

# Escribir a CSV
CSV.write(filename, df_final)

println("¡Proceso terminado con éxito!. Se han registrado $(nrow(df_final)) individuos sobrevivientes en total.")