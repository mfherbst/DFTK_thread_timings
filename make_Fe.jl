using DFTK
using JLD2

Ecut  = 40
kgrid = [13, 13, 13]
temperature = 0.01

a = 5.42352  # Bohr
lattice = a / 2 * [[-1  1  1]; [ 1 -1  1]; [ 1  1 -1]]
Fe = ElementPsp(:Fe, psp=load_psp("hgh/pbe/fe-q16"))
atoms = [Fe => [zeros(3)]]
magnetic_moments = [Fe => [4, ]]

model = model_PBE(lattice, atoms, temperature=temperature,
                  smearing=Smearing.Gaussian(), magnetic_moments=magnetic_moments)
basis = PlaneWaveBasis(model, Ecut, kgrid=kgrid)
ρspin = guess_spin_density(basis, magnetic_moments)
scfres = self_consistent_field(basis; ρspin=ρspin, tol=100,
                               maxiter=1, mixing=SimpleMixing(0.0))

# Truncate scfres such that density is guess density
scfres = (ρ=guess_density(basis), ρspin=ρspin,
          basis=basis, ψ=scfres.ψ, occupation=scfres.occupation,
          eigenvalues=scfres.eigenvalues, εF=scfres.εF)
save_scfres("Fe_scfres_guess.jld2", scfres)
