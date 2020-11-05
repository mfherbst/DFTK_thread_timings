using DFTK
using JLD2

Ecut = 35

lattice = load_lattice("Caffeine.abi")
atoms   = [ElementPsp(el.symbol, psp=load_psp(el.symbol, functional="pbe")) => position
           for (el, position) in load_atoms("Caffeine.abi")]

xc = Xc(:gga_x_pbe, :gga_c_pbe, density_threshold=1e-16)
model = model_DFT(lattice, atoms, xc)
basis = PlaneWaveBasis(model, Ecut, kgrid=[1, 1, 1])
scfres = self_consistent_field(basis; tol=100, maxiter=1, mixing=SimpleMixing(0.0))

# Truncate scfres such that density is guess density
scfres = (ρ=guess_density(basis), ρspin=nothing, basis=basis, ψ=scfres.ψ,
          occupation=scfres.occupation, eigenvalues=scfres.eigenvalues, εF=scfres.εF,
          maxiter=19)
save_scfres("Caffeine_scfres_guess.jld2", scfres)
