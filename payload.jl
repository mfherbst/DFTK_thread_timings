using DFTK
using FFTW
using LinearAlgebra
using JLD2
using TimerOutputs
using Printf

println("Julia version: $VERSION\n")
println("Threading configuration: ")
for id in ("JULIA_NUM_THREADS", "JULIA_FFTW_THREADS", "JULIA_BLAS_THREADS")
    @printf "    %20s: % 3s\n" id ENV[id]
end
FFTW.set_num_threads(parse(Int, ENV["JULIA_FFTW_THREADS"]))
BLAS.set_num_threads(parse(Int, ENV["JULIA_BLAS_THREADS"]))

println("Payload:  $(ENV["DFTK_BENCHMARK_PAYLOAD"])")
scfres = load_scfres(ENV["DFTK_BENCHMARK_PAYLOAD"])
println(); flush(stdout)

println("System facts:")
println("    fft_size:      $(scfres.basis.fft_size)")
println("    kpoints:       $(length(scfres.basis.kpoints))")
println("    n_electrons:   $(scfres.basis.model.n_electrons)")
println("    n_bands:       $(length(scfres.eigenvalues[1]))")
println(); flush(stdout)

println("Compiling code ..."); flush(stdout)
self_consistent_field(scfres.basis; ρ=scfres.ρ, ρspin=scfres.ρspin, ψ=scfres.ψ,
                      tol=1, maxiter=1, callback=info -> ());

println("Timing SCF ...")
println(); flush(stdout)
reset_timer!(DFTK.timer)
start_time = time_ns()
callback = (info -> flush(stdout)) ∘ DFTK.ScfDefaultCallback()
scfres = self_consistent_field(scfres.basis; ρ=scfres.ρ, ρspin=scfres.ρspin, ψ=scfres.ψ,
                               tol=1e-14, mixing=KerkerDosMixing(),
                               maxiter=scfres.maxiter, callback=callback);
println(scfres.energies)
end_time = time_ns()
println(DFTK.timer)

# Time it took in ns
println()
println("Total time in ns: $(Int.(end_time - start_time))")
