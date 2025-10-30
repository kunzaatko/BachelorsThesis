# Analysis of Cell Images Acquired by Super-resolution Microscopy

This repository contains the LaTeX source code for my bachelors thesis on [structured illumination
  microscopy](https://en.wikipedia.org/wiki/Super-resolution_microscopy#Structured_illumination_microscopy_(SIM)) and
  the slides used for its defence.
The PDF can be found in [releases](https://github.com/kunzaatko/BachelorsThesis/releases). 
This is the latest version of the [document](https://github.com/kunzaatko/BachelorsThesis/releases/latest/download/BT_MartinKunz.pdf) 
  and the [defence
  slides](https://github.com/kunzaatko/BachelorsThesis/releases/latest/download/BT_MartinKunz_slides.pdf).
Here is the [supervisors opinion](./opinions/opinion-supervisor.pdf) and the [opponents
opinion](./opinions/opinion-opponent.pdf).

## Outline

- Contents
- Introduction
- Theory
  - Nature of Light
    - Historical Context
    - Wave Theory of Light
    - Wave Equation Solutions
  - Super-resolution Microscopy
    - Comparison of SR Methods
    - Principle of SIM
    - SIM
    - Discussion
- Experiment
  - SIM Reconstruction
    - Parameter Estimation
    - Wiener filter Reconstruction
    - Inversion Reconstruction
    - Discussion
  - Measurement of the Transfer Function
    - Image Formation
    - PSF from Beads
    - The Source Model
    - Estimating the PSF from the Model
    - PSF from SIM
    - New Reconstruction
    - Discussion
- Conclusion
- Bibliography

## Compilation Instructions
The document can be compiled using [`tectonic`](https://github.com/tectonic-typesetting/tectonic).
A [`just`](https://github.com/casey/just) build script is included in the repository that builds the figures and compiles the document in one command by
```bash
$ just build-all
```

### Figures
The figures that are necessary are included in the repository built from the data.

> [!IMPORTANT]
> The data used for building the figures is not included in the repository but can be made available upon request.

Figures are built using `Julia` (which must be installed and the figure project instantiated).
This is automated with the build script written in `just` by running
```bash
$ just build-all-figs
```

To build a concrete figure, you can run
```bash
$ just build-fig <name>
```
and to list the available figures run
```bash
$ just list-figs
```

### Document 
You can build the document with the figures available by running
```bash
$ just build # or `tectonic -X build`
```
