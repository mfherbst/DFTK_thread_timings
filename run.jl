include("common.jl")

function main()
    df = generate_initial_dataframe()
    run_cases(df, checkpoint="results.jdf")
end

(abspath(PROGRAM_FILE) == @__FILE__) && main()
nothing
