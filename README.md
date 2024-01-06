# Analysis of Cell Images Acquired by Super-resolution Microscopy

This repository contains the LaTeX source code for my bachelors thesis on [structured illumination microscopy](https://en.wikipedia.org/wiki/Super-resolution_microscopy#Structured_illumination_microscopy_(SIM)). The PDF can be found in [releases](https://github.com/kunzaatko/BachelorsThesis/releases). This is the latest version of the [document](https://github.com/kunzaatko/BachelorsThesis/releases/latest/download/BT_MartinKunz.pdf).

## Outline

1. **Introduction**
    - [ ] Motivation to the development of super-resolution methods
    - [ ] Brief overview of optical sensing technology

---
(part I - Theory)

2. **Light in a Microscope**
    - [ ] Historical context
    - [ ] Wave theory of light introduction
        - Maxwell’s equations (+ planar wave solution)
        - Linearity of the Maxwell’s equations
        - Light mediation through a medium (For purposes of defocus aberration)
    - [ ] Total Internal Reflection
        - Light passing through a interface with a different refractive index
        - total internal reflection solution
        - solution of the critical angle of incidence
        - use of TIR in fluorescence microscopy
    - [ ] Scalar diffraction
        - Conditions for the scalar approximation
        - Theory behind scalar diffraction
        - Fresnel and Fraunhofer diffraction integrals
        - Paraxial approximation
        - Solution to scalar diffraction with a spherical aperture
        - Abbe resolution limit

3. **Transfer Functions**
    - [ ] Consequences of a linear system
        - Additivity of illumination
        - Decomposition of the system transfer
    - [ ] OTF and its properties
        - Spatial frequency concept
        - Fourier transform
        - Pupil function
        - OTF from the pupil function
        - Aberrations and Zernike polynomials
    - [ ] PSF and its properties
        - PSF as a result diffraction
        - PSF as Greens function
    - [ ] Models of transfer functions
        - Ideal spherical aperture model OTF
        - Airy disc model PSF and its implications
        - Gibson-Lani model of the PSF
    - [ ] Deconvolution
        - Methods of deconvolution 
        - Wiener deconvolution (+ deconvolution of our image comparison)

4. **Super Resolution**
    - [ ] Introduction and methods of super-resolution
        - Principles and working mechanisms
        - Comparison to SIM and advantages of SIM in applications
    - [ ] SIM theory
        - Principle of SIM (one dimensional to two dimensional, moire patterns)
        - Image formation in a microscope in SIM
        - Outline of reconstruction of classical SIM with 9 harmonics
    - [ ] SIM variants
        - non-linear SIM (indefinite resolution)
        - blind-SIM (speckle patterned SIM)
        - general SIM
        - 3D SIM

--- 
(part II - Experiment)

5. **SIM reconstruction**
6. **Measuring the Transfer Functions**

---
(Appendix)
