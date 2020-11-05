include("common.jl")
using Plots

function plot_all_cases(df, basetime, x, y=:time; caseminima=Dict(), ideal=identity, kwargs...)
    cases = unique(df[.!ismissing.(df.time), :].case)
    p = plot(;xlabel=string(x), ylabel="relative $y", legend=:topright, kwargs...)

    for (i, case) in enumerate(cases)
        minimum = get(caseminima, case, nothing) ./ basetime[case]
        xvals = getproperty(df[df.case .== case, :], x)
        yvals = getproperty(df[df.case .== case, :], y)
        plot!(p, xvals, yvals ./ basetime[case], label=case, color=i)
        if !isnothing(minimum)
            plot!(p, xvals, minimum * ones(Float64, size(yvals)), color=i, label="", linestyle=:dot)
        end
    end
    xvals = getproperty(df[df.case .== "Fe", :], x)
    plot!(p, xvals, 1 ./ ideal.(xvals), label="perfect scaling", colour=:black, linestyle=:dash)
    p
end

function find_caseminima(df)
    cases = unique(df[.!ismissing.(df.time), :].case)
    Dict(case => minimum(df[(df.case .== case) .& .!ismissing.(df.time), :].time) for case in cases)
end
function find_basetime(df)
    cases = unique(df[.!ismissing.(df.time), :].case)
    Dict(case => only(df[(df.case .== case) .& (df.n_fft .== df.n_julia .== df.n_blas .== 1), :].time)
         for case in cases)
end

df = collect_dataframe()
df = df[(df.case .!= "Si"), :]

Plots.default(titlefontsize=10, guidefontsize=8, legendfontsize=6, tickfontsize=6)
caseminima = find_caseminima(df)
basetime   = find_basetime(df)
p1 = plot_all_cases(df[(df.n_julia .== 1) .& (df.n_fft .== 1),  :], basetime, :n_blas;
                    title="n_blas series", caseminima=caseminima, legend=:bottomleft)
p2 = plot_all_cases(df[(df.n_julia .== 1) .& (df.n_blas .== 1), :], basetime, :n_fft;
                    title="n_fft series", caseminima=caseminima, legend=:none)
p3 = plot_all_cases(df[(df.n_blas .== 1)  .& (df.n_fft .== 1),  :], basetime, :n_julia;
                    title="n_julia series", caseminima=caseminima, legend=:none)
p = plot(p1, p2, p3)
savefig(p, "thread_axes.pdf")

ylims = (0.0, 1.0)
q1 = plot_all_cases(df[(df.n_blas .== df.n_julia)  .& (df.n_fft .== 1),  :], basetime, :n_julia;
                    title="n_julia = n_blas, n_fft = 1", ylims=ylims,
                    caseminima=caseminima, legend=:topright)
q2 = plot_all_cases(df[(df.n_blas .== df.n_julia)  .& (df.n_fft .== 2),  :], basetime, :n_julia;
                    title="n_julia = n_blas, n_fft = 2", ylims=ylims, ideal=x -> 2x,
                    caseminima=caseminima, legend=:none)
q3 = plot_all_cases(df[(df.n_blas .== min.(6, df.n_julia)) .& (df.n_fft .== 1),  :], basetime, :n_julia;
                    title="n_blas = min(6, n_julia), n_fft = 1", ylims=ylims,
                    caseminima=caseminima, legend=:none)
q4 = plot_all_cases(df[(df.n_blas .== min.(6, df.n_julia)) .& (df.n_fft .== 2),  :], basetime, :n_julia;
                    title="n_blas = min(6, n_julia), n_fft = 2", ylims=ylims,
                    caseminima=caseminima, legend=:none, ideal=x-> 2x)
q = plot(q1, q2, q3, q4)
savefig(q, "thread_settings.pdf")
