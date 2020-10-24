using DFTK
using JLD2

Ecut  = 15
kgrid = [4, 4, 4]
temperature = 0.01

lattice = 5.13 * [0 1 1; 1 0 1; 1 1 0]
Si = ElementPsp(:Si, psp=load_psp("hgh/pbe/Si-q4"))
atoms = [Si => [ones(3)/8, -ones(3)/8]]

model = model_PBE(lattice, atoms, temperature=temperature)
basis = PlaneWaveBasis(model, Ecut, kgrid=kgrid)
scfres = self_consistent_field(basis; tol=100, maxiter=1, mixing=SimpleMixing(0.0))

# Truncate scfres such that density is guess density
scfres = (ρ=guess_density(basis), ρspin=nothing,
          basis=basis, ψ=scfres.ψ, occupation=scfres.occupation,
          eigenvalues=scfres.eigenvalues, εF=scfres.εF)
save_scfres("Si_scfres_guess.jld2", scfres)
