include("common.jl")
using Plots

function plot_all_cases(df, basetime, x, y=:time; caseminima=Dict(), ideal=identity, kwargs...)
    cases = unique(df[.!ismissing.(df.time), :].case)
    p = plot(;xlabel=string(x), ylabel="relative $y", legend=:topright, kwargs...)

    for (i, case) in enumerate(cases)
        minimum = basetime[case] ./ get(caseminima, case, nothing)
        xvals = getproperty(df[df.case .== case, :], x)
        yvals = getproperty(df[df.case .== case, :], y)
        plot!(p, xvals, basetime[case] ./ yvals, label=case, color=i, mark=:x)
        if !isnothing(minimum)
            plot!(p, xvals, minimum * ones(Float64, size(yvals)), color=i, label="", linestyle=:dot)
        end
    end
    xvals = getproperty(df[df.case .== "Fe", :], x)
    plot!(p, xvals, ideal.(xvals), label="perfect scaling", colour=:black, linestyle=:dash)
    p
end

function find_caseminima(df)
    cases = unique(df[.!ismissing.(df.time), :].case)
    Dict(case => minimum(df[(df.case .== case) .& .!ismissing.(df.time), :].time) for case in cases)
end
function find_basetime(df)
    cases = unique(df[.!ismissing.(df.time), :].case)
    Dict(case => only(df[(df.case .== case) .& (df.n_fft .== df.n_julia .== df.n_blas .== df.n_mpi .== 1), :].time)
         for case in cases)
end

df = collect_dataframe()
df = df[(df.case .!= "Si"), :]

ylims = (1, 10)

Plots.default(titlefontsize=10, guidefontsize=8, legendfontsize=6, tickfontsize=6)
caseminima = find_caseminima(df)
basetime   = find_basetime(df)
p1 = plot_all_cases(df[(df.n_julia .== 1) .& (df.n_fft .== 1) .& (df.n_mpi .== 1),  :],
                    basetime, :n_blas; title="n_blas series", caseminima=caseminima, legend=:topleft, ylims=ylims)
p2 = plot_all_cases(df[(df.n_julia .== 1) .& (df.n_blas .== 1) .& (df.n_mpi .== 1), :],
                    basetime, :n_fft; title="n_fft series", caseminima=caseminima, legend=:none, ylims=ylims)
p3 = plot_all_cases(df[(df.n_blas .== 1)  .& (df.n_fft .== 1) .& (df.n_mpi .== 1),  :],
                    basetime, :n_julia; title="n_julia series", caseminima=caseminima, legend=:none, ylims=ylims)
p4 = plot_all_cases(df[(df.n_blas .== 1)  .& (df.n_fft .== 1) .& (df.n_julia .== 1),  :],
                    basetime, :n_mpi; title="n_mpi series", caseminima=caseminima, legend=:none, ylims=ylims)
p = plot(p1, p2, p3, p4)
savefig(p, "thread_axes.pdf")

q1 = plot_all_cases(df[(df.n_blas .== df.n_julia)  .& (df.n_fft .== df.n_mpi .== 1),  :],
                    basetime, :n_julia; title="n_julia = n_blas, n_fft = 1", ylims=ylims,
                    caseminima=caseminima, legend=:topleft)
q2 = plot_all_cases(df[(df.n_blas .== df.n_julia)  .& (df.n_fft .== 2) .& (df.n_mpi .== 1),  :],
                    basetime, :n_julia; title="n_julia = n_blas, n_fft = 2", ylims=ylims,
                    ideal=x -> 2x, caseminima=caseminima, legend=:none)
q3 = plot_all_cases(df[(df.n_blas .== min.(6, df.n_julia)) .& (df.n_fft .== df.n_mpi .== 1),  :],
                    basetime, :n_julia; title="n_blas = min(6, n_julia), n_fft = 1",
                    ylims=ylims, caseminima=caseminima, legend=:none)
q4 = plot_all_cases(df[(df.n_blas .== min.(6, df.n_julia)) .& (df.n_fft .== 2) .& (df.n_mpi .== 1),  :],
                    basetime, :n_julia; title="n_blas = min(6, n_julia), n_fft = 2", ylims=ylims,
                    caseminima=caseminima, legend=:none, ideal=x-> 2x)
q = plot(q1, q2, q3, q4)
savefig(q, "thread_settings.pdf")
