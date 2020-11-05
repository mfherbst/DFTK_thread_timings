using DFTK
using FFTW
using LinearAlgebra
using JLD2
using TimerOutputs
using Printf
using MPI

mprintln(args...) = mpi_master() ? println(args...) : nothing

mprintln("Julia version: $VERSION\n")
mprintln("Threading configuration: ")
if mpi_master()
    for id in ("JULIA_NUM_THREADS", "JULIA_FFTW_THREADS", "JULIA_BLAS_THREADS")
        @printf "    %20s: % 3s\n" id ENV[id]
    end
    @printf "    %20s: % 3s\n" "MPI Processes" mpi_nprocs()
end
FFTW.set_num_threads(parse(Int, ENV["JULIA_FFTW_THREADS"]))
BLAS.set_num_threads(parse(Int, ENV["JULIA_BLAS_THREADS"]))

mprintln("Payload:  $(ENV["DFTK_BENCHMARK_PAYLOAD"])")
scfres = load_scfres(ENV["DFTK_BENCHMARK_PAYLOAD"])
mprintln(); flush(stdout)

mprintln("System facts:")
mprintln("    fft_size:      $(scfres.basis.fft_size)")
mprintln("    kpoints:       $(length(scfres.basis.kpoints))")
mprintln("    n_electrons:   $(scfres.basis.model.n_electrons)")
mprintln("    n_bands:       $(length(scfres.eigenvalues[1]))")
#  println("    krange $(MPI.Comm_rank(scfres.basis.comm_kpts)):  $(scfres.basis.krange_thisproc)")
mprintln(); flush(stdout)
flush(stdout)

mprintln("Compiling code ..."); flush(stdout)
self_consistent_field(scfres.basis; ρ=scfres.ρ, ρspin=scfres.ρspin, ψ=scfres.ψ,
                      tol=1, maxiter=1, callback=info -> ());

mprintln("Timing SCF ...")
mprintln(); flush(stdout)
reset_timer!(DFTK.timer)
start_time = time_ns()
callback = (info -> flush(stdout)) ∘ DFTK.ScfDefaultCallback()
scfres = self_consistent_field(scfres.basis; ρ=scfres.ρ, ρspin=scfres.ρspin, ψ=scfres.ψ,
                               tol=1e-14, mixing=KerkerDosMixing(),
                               maxiter=scfres.maxiter, callback=callback);
mprintln(scfres.energies)
end_time = time_ns()
mprintln(DFTK.timer)

# Time it took in ns
mprintln()
mprintln("Total time in ns: $(Int.(end_time - start_time))")
