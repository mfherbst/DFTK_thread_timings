using DFTK
using JLD2

Ecut = 20
supersampling = 1.5

lattice = load_lattice("Aluminium_slab.cif")
atoms   = [ElementPsp(el.symbol, psp=load_psp(el.symbol, functional="pbe")) => position
           for (el, position) in load_atoms("Aluminium_slab.cif")]

model    = model_PBE(lattice, atoms)
fft_size = determine_fft_size(model, Ecut, supersampling=supersampling)
basis    = PlaneWaveBasis(model, Ecut; fft_size=fft_size)
scfres   = self_consistent_field(basis; tol=100, maxiter=1, mixing=SimpleMixing(0.0))

# Truncate scfres such that density is guess density
scfres = (ρ=guess_density(basis), ρspin=nothing, basis=basis, ψ=scfres.ψ,
          occupation=scfres.occupation, eigenvalues=scfres.eigenvalues, εF=scfres.εF)
save_scfres("Aluminium_slab_scfres_guess.jld2", scfres)
