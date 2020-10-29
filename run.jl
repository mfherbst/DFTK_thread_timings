include("common.jl")

function main()
    resultfile = "results.jdf"
    if isdir(resultfile)
        df = loadjdf(resultfile)
        for row in eachrow(generate_initial_dataframe())
            exists_in_df = any(eachrow(df)) do dfr
                all(dfr[1:4] == row[1:4])
            end
            !exists_in_df && push!(df, row)
        end
    else
        df = generate_initial_dataframe()
    end
    run_cases(df, checkpoint=resultfile)
end


(abspath(PROGRAM_FILE) == @__FILE__) && main()
nothing
