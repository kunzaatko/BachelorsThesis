alias b := build
alias baf := build-all-figs
alias bf := build-fig
alias uaf := update-all-figs
alias uf := update-fig
alias lf := list-figs
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
        echo 'Building figure' (basename $i) '…'
        julia --project=src/figures/src --color=yes $i 
    end

# Update all figures
update-all-figs:
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
            echo 'Skipping figure' (basename $i)  '… (unmodified source)'
        else
            echo 'Building figure' (basename $i) '…'
            julia --project=src/figures/src --color=yes $i 
        end
    end

# TODO: should give a pick of the figures

# Build figure `FIG`
build-fig FIG:
    #! /bin/env fish
    echo Building figure {{FIG}} …
    julia --project=src/figures/src --color yes src/figures/src/fig_{{FIG}}.jl

update-fig FIG:
    #! /bin/env fish
    set -l currentfigs src/figures/{{FIG}}*
    set -l skip 0
    if test (count $currentfigs) -ne 0
        if test (stat -c '%Y' src/figures/src/fig_{{FIG}}.jl) -lt (stat -c '%Y' $currentfigs[1])
            set skip 1
        end
    end
    if test $skip -eq 1
        echo 'Skipping figure' {{FIG}} '… (unmodified source)'
    else
        echo Building figure {{FIG}} …
        julia --project=src/figures/src --color yes src/figures/src/fig_{{FIG}}.jl
    end

# List all figures
list-figs:
    #! /bin/env fish
    for i in src/figures/src/fig_*.jl
        echo (basename $i .jl) | cut -c 5-
    end

# TODO: add some checks with `prosecheck` etc.
