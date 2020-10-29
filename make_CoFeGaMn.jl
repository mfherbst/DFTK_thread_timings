using DFTK
using JLD2

Ecut  = 45
kgrid = [13, 13, 13]
temperature = 0.01

lattice = 5.49059925751772 * [0 1 1; 1 0 1; 1 1 0]
Mn = ElementPsp(:Mn, psp=load_psp("hgh/pbe/mn-q15"))
Fe = ElementPsp(:Fe, psp=load_psp("hgh/pbe/fe-q16"))
Co = ElementPsp(:Co, psp=load_psp("hgh/pbe/co-q17"))
Ga = ElementPsp(:Ga, psp=load_psp("hgh/pbe/ga-q3"))
atoms = [
    Mn => [[0.5, 0.5, 0.5]],
    Ga => [[0.0, 0.0, 0.0]],
    Fe => [[0.75, 0.75, 0.75]],
    Co => [[0.25, 0.25, 0.25]],
]
magnetic_moments = [
    Mn => [5.0],
    Ga => [0.0],
    Fe => [5.0],
    Co => [5.0],
]

model = model_PBE(lattice, atoms, temperature=temperature,
                  smearing=Smearing.Gaussian(), magnetic_moments=magnetic_moments)
basis = PlaneWaveBasis(model, Ecut, kgrid=kgrid)
ρspin = guess_spin_density(basis, magnetic_moments)
scfres = self_consistent_field(basis; ρspin=ρspin, tol=100,
                               maxiter=1, mixing=SimpleMixing(0.0))

# Truncate scfres such that density is guess density
scfres = (ρ=guess_density(basis), ρspin=ρspin,
          basis=basis, ψ=scfres.ψ, occupation=scfres.occupation,
          eigenvalues=scfres.eigenvalues, εF=scfres.εF,
          maxiter=45)
save_scfres("CoFeGaMn_scfres_guess.jld2", scfres)
