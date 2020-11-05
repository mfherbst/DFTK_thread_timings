using DataFrames
using JDF

function generate_input_data(case)
    if !isfile(case * "_scfres_guess.jld2")
        println("Generating input data for $case")
        include("make_$case.jl")
    end
end

function run_julia_payload(;case, n_julia, n_blas, n_fft, n_mpi, run_calculations=true)
    juliaexe = Sys.get_process_title()
    isempty(juliaexe) && (juliaexe = `julia`)
    if n_mpi > 1
        juliaexe = `$(homedir())/.julia/bin/mpiexecjl --project=@. -np $n_mpi $juliaexe`
    end

    ENV["JULIA_NUM_THREADS"]  = string(n_julia)
    ENV["JULIA_FFTW_THREADS"] = string(n_fft)
    ENV["JULIA_BLAS_THREADS"] = string(n_blas)
    ENV["DFTK_BENCHMARK_PAYLOAD"] = case * "_scfres_guess.jld2"

    !isdir(case) && mkdir(case)
    logfile = case * "/$(n_mpi)_$(n_julia)_$(n_blas)_$(n_fft).log"
    if !isfile(logfile)
        run_calculations || return missing
        generate_input_data(case)
        println("Running case=$case, n_mpi=$n_mpi n_julia=$n_julia, n_blas=$n_blas, n_fft=$n_fft")
        open(logfile, "w") do fp
            redirect_stdout(fp) do
                run(`$juliaexe --project=@. $(joinpath(@__DIR__, "payload.jl"))`)
            end
        end
    end

    open(logfile, "r") do fp
        for line in readlines(fp)
            if startswith(line, "Total time in ns:")
                return parse(Int, split(line)[end])
            end
        end
        missing
    end
end


function run_cases(df; checkpoint=nothing)
    for row in eachrow(df)
        ismissing(row.time) || continue

        # Ignore time field to build call arguments for run_julia_payload
        callargs = (k=>v for (k,v) in pairs(row) if k != :time)
        row.time = run_julia_payload(;callargs...)
        if !isnothing(checkpoint)
            savejdf(checkpoint, df)
        end
    end
    df
end


function make_matrix(case::String; n_julia=1:1, n_blas=1:1, n_fft=1:1, n_mpi=1:1)
    data  = (case=String[],
             n_mpi=Int[],
             n_julia=Int[],
             n_blas=Int[],
             n_fft=Int[],
             time=Union{Int,Missing}[])
    for nm in n_mpi, nj in n_julia, nb in n_blas, nf in n_fft
        push!(data.case,    case)
        push!(data.n_mpi,   nm)
        push!(data.n_julia, nj)
        push!(data.n_blas,  nb)
        push!(data.n_fft,   nf)
        push!(data.time,    missing)
    end
    DataFrame(;data...)
end


function generate_initial_dataframe()
    df = DataFrame()
    append!(df, make_matrix("Si", n_julia=1:2, n_blas=1:2, n_fft=1:2))
    for case in ("Fe", "Aluminium_slab", "Caffeine")
        append!(df, make_matrix(case, n_julia=1:4, n_blas=1:4, n_fft=1:2))
        append!(df, make_matrix(case, n_julia=1:1, n_blas=1:1, n_fft=3:4))
        for i in (5, 6, 7, 8)
            append!(df, make_matrix(case, n_julia=i:i, n_blas=4:i, n_fft=1:2))
        end
        case == "Fe"             && append!(df, make_matrix(case, n_mpi=1:16))
        case == "Aluminium_slab" && append!(df, make_matrix(case, n_mpi=1:16))
    end
    for case in ("CoFeGaMn", )
        append!(df, make_matrix(case, n_julia=1:3, n_blas=1:3, n_fft=1:1))
        append!(df, make_matrix(case, n_julia=1:1, n_blas=1:1, n_fft=1:3))
        for i in (4, 5, 6, 7, 8)
            append!(df, make_matrix(case, n_julia=i:i, n_blas=4:i, n_fft=1:1))
        end
        append!(df, make_matrix(case, n_mpi=[1, 2, 4, 8, 16]))
    end
    unique(df)
end


function collect_dataframe()
    df = generate_initial_dataframe()
    for row in eachrow(df)
        # Ignore time field to build call arguments for run_julia_payload
        callargs = (k=>v for (k,v) in pairs(row) if k != :time)
        row.time = run_julia_payload(;callargs..., run_calculations=false)
    end
    df
end
