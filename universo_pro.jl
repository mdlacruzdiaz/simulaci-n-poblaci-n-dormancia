module Universo

using Random

# Parámetros del modelo adaptados a los recursos
struct Parametros
    b::Float64       # Tasa base de reproducción
    d::Float64       # Tasa base de defunción
    R::Float64       # Cantidad total de Recursos en el medio (antes Capacidad M)
    σ::Float64       # Variación del medio (sigma)
    τ::Float64       # Tiempo medio de oscilación del medio (tau)
    δ::Float64       # Variación máxima de la mutación de alpha (delta)
end

mutable struct Estado
    t::Float64                   
    medio_bueno::Bool            
    activos_alphas::Vector{Float64} 
    
    # ¡NUEVO! Como las semillas ya no tienen un tiempo fijo de despertar, 
    # solo necesitamos guardar una lista con sus genes alpha.
    semillas_alphas::Vector{Float64} 
end

function paso_gillespie!(estado::Estado, params::Parametros)
    
    N_activos = length(estado.activos_alphas)
    N_semillas = length(estado.semillas_alphas)
    
    # ---------------------------------------------------------
    # 1. CÁLCULO DE TASAS PARA INDIVIDUOS ACTIVOS Y MEDIO
    # ---------------------------------------------------------
    modificador_medio = estado.medio_bueno ? params.σ : -params.σ
    
    # Recursos per cápita (como en tu código original)
    recursos_per_capita = params.R / (N_activos + 1.0)
    
    # Aplicamos la lógica de Poisson en tiempo continuo ajustando las tasas:
    # La natalidad es proporcional a los recursos, la mortalidad es inversamente proporcional
    b_actual = max(0.0, (params.b + modificador_medio) * recursos_per_capita)
    d_actual = params.d #/ recursos_per_capita
    
    tasa_nacimiento_total = b_actual * N_activos
    tasa_muerte_activos_total = d_actual * N_activos
    tasa_medio_total = 1.0 / params.τ
    
    # ---------------------------------------------------------
    # 2. CÁLCULO DE TASAS PARA LAS SEMILLAS
    # ---------------------------------------------------------
    # Sumamos las tasas individuales de todas las semillas existentes
    suma_tasas_despertar = 0.0
    for alpha in estado.semillas_alphas
        # Tasa de despertar de esta semilla = 1 / alpha
        suma_tasas_despertar += 1.0 / alpha
    end
    
    tasa_despertar_total = suma_tasas_despertar
    # Como la tasa de muerte es 1/(2*alpha), la suma total es exactamente la mitad
    tasa_muerte_semillas_total = suma_tasas_despertar / 2.0 
    
    # ---------------------------------------------------------
    # 3. TIEMPO DEL PRÓXIMO SUCESO
    # ---------------------------------------------------------
    tasa_total = tasa_nacimiento_total + tasa_muerte_activos_total + tasa_medio_total + tasa_despertar_total + tasa_muerte_semillas_total
    
    # Si por algún motivo todas las tasas son 0 (población extinta), detenemos el tiempo
    if tasa_total == 0.0
        estado.t = Inf
        return
    end
    
    # Avanzamos el reloj de simulación
    estado.t += randexp() / tasa_total
    
    # ---------------------------------------------------------
    # 4. DECIDIR QUÉ OCURRE Y A QUIÉN
    # ---------------------------------------------------------
    r = rand() * tasa_total
    
    if r < tasa_nacimiento_total
        # EVENTO 1: Nace una semilla
        padre_idx = rand(1:N_activos)
        alpha_padre = estado.activos_alphas[padre_idx]
        
        mutacion = (rand() * 2.0 * params.δ) - params.δ
        # Evitamos alphas excesivamente cercanos a 0 para que la tasa no sea infinito
        alpha_hijo = max(1e-4, alpha_padre + mutacion) 
        
        push!(estado.semillas_alphas, alpha_hijo)
        
    elseif r < tasa_nacimiento_total + tasa_muerte_activos_total
        # EVENTO 2: Muere un individuo activo
        idx = rand(1:N_activos)
        estado.activos_alphas[idx] = estado.activos_alphas[end]
        pop!(estado.activos_alphas)
        
    elseif r < tasa_nacimiento_total + tasa_muerte_activos_total + tasa_medio_total
        # EVENTO 3: El medio ambiente cambia
        estado.medio_bueno = !estado.medio_bueno
        
    elseif r < tasa_nacimiento_total + tasa_muerte_activos_total + tasa_medio_total + tasa_despertar_total
        # EVENTO 4: Una semilla despierta
        # Tenemos que elegir qué semilla despierta (las de alpha pequeño tienen más probabilidad)
        r_local = r - (tasa_nacimiento_total + tasa_muerte_activos_total + tasa_medio_total)
        acumulado = 0.0
        idx_elegida = N_semillas
        
        for i in 1:N_semillas
            acumulado += 1.0 / estado.semillas_alphas[i]
            if r_local <= acumulado
                idx_elegida = i
                break
            end
        end
        
        # Movemos la semilla a la lista de activos
        alpha_despierta = estado.semillas_alphas[idx_elegida]
        estado.semillas_alphas[idx_elegida] = estado.semillas_alphas[end]
        pop!(estado.semillas_alphas)
        push!(estado.activos_alphas, alpha_despierta)
        
    else
        # EVENTO 5: Una semilla muere sin despertar
        # Misma lógica: elegimos proporcionalmente a su tasa de muerte 1/(2*alpha)
        r_local = r - (tasa_nacimiento_total + tasa_muerte_activos_total + tasa_medio_total + tasa_despertar_total)
        acumulado = 0.0
        idx_elegida = N_semillas
        
        for i in 1:N_semillas
            acumulado += 1.0 / (2.0 * estado.semillas_alphas[i])
            if r_local <= acumulado
                idx_elegida = i
                break
            end
        end
        
        # Simplemente la borramos
        estado.semillas_alphas[idx_elegida] = estado.semillas_alphas[end]
        pop!(estado.semillas_alphas)
    end
end

end # Fin del módulo