using Distributed

# -----------------------------------------------------------------------------
# 1. CONFIGURACIÓN DE PROCESOS
# -----------------------------------------------------------------------------
if nprocs() == 1
    addprocs(length(Sys.cpu_info()) - 1; exeflags="--project=.") 
end

@everywhere begin
    using Pkg
    Pkg.activate(".") 
    
    using DataFrames, CSV, Dates, Statistics, Distributed
    
    include("universo_pro.jl")
end

# -----------------------------------------------------------------------------
# 2. DEFINICIÓN DE FUNCIONES DE RECOLECCIÓN
# -----------------------------------------------------------------------------
@everywhere begin
    
    function run_time_series_simulation(sigma, initial_a, replicate_id; t_max=300.0, save_interval=1.0)
        try
            println("Worker $(myid()): Running simulation with sigma=$sigma, initial_a=$initial_a, replicate=$replicate_id")
            
            # --- MODIFICADO: Ajustamos los parámetros ---
            params = Universo.Parametros(
                1.0,      # b: tasa base reproducción (bajamos un poco b y d base porque ahora se multiplican por los recursos)
                1.0,      # d: death_rate base
                1000.0,   # R: Recursos totales (antes M)
                sigma,    # σ: res_σ (Variación del medio)
                1.0,      # τ: tau (Tiempo de oscilación)
                0.0       # δ: Magnitud de mutación anulada
            )
            
            N_inicial = 1000
            alphas_iniciales = fill(initial_a, N_inicial)
            
            # --- MODIFICADO: Las semillas ahora son solo Vector{Float64} vacío ---
            estado = Universo.Estado(0.0, true, alphas_iniciales, Float64[])
            
            data_model = DataFrame(
                time = Float64[], 
                active_count = Int[], 
                seed_count = Int[]
            )
            
            next_save_time = 0.0
            
            while estado.t <= t_max && (!isempty(estado.activos_alphas) || !isempty(estado.semillas_alphas))
                
                while estado.t >= next_save_time && next_save_time <= t_max
                    push!(data_model, (next_save_time, length(estado.activos_alphas), length(estado.semillas_alphas)))
                    next_save_time += save_interval
                end
                
                Universo.paso_gillespie!(estado, params)
            end
            
            while next_save_time <= estado.t && next_save_time <= t_max
                push!(data_model, (next_save_time, length(estado.activos_alphas), length(estado.semillas_alphas)))
                next_save_time += save_interval
            end
            
            insertcols!(data_model, 
                :sigma => sigma, 
                :initial_a => initial_a, 
                :replicate => replicate_id
            )
            
            return data_model
            
        catch e
            println("Error en worker $(myid()): $e")
            return DataFrame() 
        end
    end
end

# -----------------------------------------------------------------------------
# 3. EJECUCIÓN PRINCIPAL
# -----------------------------------------------------------------------------

steps_total = 100.0     
intervalo_guardado = 1.0 
sigma_fijo = 0.0        

initial_a_values = LinRange(0.001, 10, 7)
n_replicates = 10 

param_combinations = [(sigma_fijo, init_a, rep) 
                      for init_a in initial_a_values 
                      for rep in 1:n_replicates]

println("Iniciando simulaciones...")
println("Total simulaciones: $(length(param_combinations))")
println("Guardando datos cada $intervalo_guardado unidades de tiempo.")

time_series_results = pmap(param_combinations) do params
    p_sigma = params[1]
    p_init_a = params[2]
    p_rep = params[3]
    
    run_time_series_simulation(p_sigma, p_init_a, p_rep; 
                               t_max=steps_total, 
                               save_interval=intervalo_guardado)
end

# -----------------------------------------------------------------------------
# 4. GUARDADO DE DATOS
# -----------------------------------------------------------------------------

println("Uniendo datos...")
all_data = reduce(vcat, time_series_results)

timestamp = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")

# MODIFICA AQUÍ LA RUTA DONDE QUIERES GUARDARLO
mi_ruta = "C:/Users/marta/OneDrive/Escritorio/juls/dormancia/data"

filename = joinpath(mi_ruta, "superv_$(timestamp).csv")

println("Guardando CSV en: $filename")
mkpath(mi_ruta) 

CSV.write(filename, all_data)

println("¡Proceso terminado con éxito!")