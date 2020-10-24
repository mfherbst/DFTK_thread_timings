using DataFrames
using JDF

function run_julia_payload(;case, n_julia, n_blas, n_fft)
    payload = case * "_scfres_guess.jld2"
    if !isfile(payload)
        println("Generating input data for $case")
        let
            include("make_$case.jl")
        end
    end

    juliaexe = Sys.get_process_title()
    isempty(juliaexe) && (juliaexe = "julia")

    ENV["JULIA_NUM_THREADS"]  = string(n_julia)
    ENV["JULIA_FFTW_THREADS"] = string(n_fft)
    ENV["JULIA_BLAS_THREADS"] = string(n_blas)
    ENV["DFTK_BENCHMARK_PAYLOAD"] = payload

    println("Running case=$case, n_julia=$n_julia, n_fft=$n_fft, n_blas=$n_blas")
    !isdir(case) && mkdir(case)
    logfile = case * "/$(n_julia)_$(n_fft)_$(n_blas).log"
    open(logfile, "w") do fp
        redirect_stdout(fp) do
            run(`$juliaexe --project=@. $(joinpath(@__DIR__, "payload.jl"))`)
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


function make_matrix(case::AbstractVector; n_julia=1:1, n_blas=1:1, n_fft=1:1)
    data  = (case=String[],
             n_julia=Int[],
             n_blas=Int[],
             n_fft=Int[],
             time=Union{Int,Missing}[])
    for pl in case, nj in n_julia, nb in n_blas, nf in n_fft
        push!(data.case, pl)
        push!(data.n_julia, nj)
        push!(data.n_blas,  nb)
        push!(data.n_fft,   nf)
        push!(data.time,    missing)
    end
    DataFrame(;data...)
end


function generate_initial_dataframe()
    df = DataFrame()
    append!(df, make_matrix(["Si"], n_julia=1:2, n_blas=1:2, n_fft=1:2))
    append!(df, make_matrix(["Fe"], n_julia=1:4, n_blas=1:4, n_fft=1:4))
    append!(df, make_matrix(["CoFeGaMn"], n_julia=1:4, n_blas=1:4, n_fft=1:4))
    df
end


function main()
    if isdir("results.jdf")
        df = loadjdf("results.jdf")
        for row in eachrow(generate_initial_dataframe())
            exists_in_df = any(eachrow(df)) do dfr
                all(dfr[1:4] == row[1:4])
            end
            !exists_in_df && push!(df, row)
        end
    else
        df = generate_initial_dataframe()
    end
    run_cases(df, checkpoint="results.jdf")
end


(abspath(PROGRAM_FILE) == @__FILE__) && main()
nothing
