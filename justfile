alias b := build
alias bf := build-all-figs
set shell := ["fish"]

# Build the document
build:
    #! /bin/env fish
    tectonic -X build

# TODO: should use the build recipe

# Build all figures
build-all-figs:
    #! /bin/env fish
    for i in src/figures/src/fig_*.jl 
        set -l currentfigs src/figures/(basename $i .jl |cut -c 5-)*
        set -l skip 0
        if test (count $currentfigs) -ne 0
            if test (stat -c '%Y' $i) -lt (stat -c '%Y' $currentfigs[1])
                set skip 1
            end
        end
        if test $skip -eq 1
            echo 'Skipping file' (basename $i)  '… (unmodified source)'
        else
            echo 'Building from file' (basename $i) '…'
            julia --project=src/figures/src --color=yes $i 
        end
    end

# TODO: should give a pick of the figures

# Build figure `FIG`
build-fig FIG:
    #! /bin/env fish
    echo Building from file {{FIG}} …
    julia --project=src/figures/src --color yes src/figures/src/fig_{{FIG}}.jl

# List all figures
list-figs:
    #! /bin/env fish
    for i in src/figures/src/fig_*.jl
        echo (basename $i .jl) | cut -c 5-
    end

# TODO: add some checks with `prosecheck` etc.
