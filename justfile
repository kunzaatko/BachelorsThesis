set shell := ["fish"]

# Build the document
build:
    #! /bin/env fish
    tectonic -X build
alias b := build

# TODO: should use the build recipe

# Build all figures
build-all-figs:
    #! /bin/env fish
    for i in src/figures/src/fig_*.jl 
        echo 'Building figure' (basename $i) '…'
        julia --project=src/figures/src --color=yes $i 
    end
alias baf := build-all-figs

# Update all figures (build them skipping the ones for which the source has not changed)
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
alias uaf := update-all-figs

# TODO: should give a pick of the figures

# Build figure `FIG`
build-fig FIG:
    #! /bin/env fish
    echo Building figure {{FIG}} …
    julia --project=src/figures/src --color yes src/figures/src/fig_{{FIG}}.jl
alias bf := build-fig

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
alias uf := update-fig

# List all figures
list-figs:
    #! /bin/env fish
    for i in src/figures/src/fig_*.jl
        echo (basename $i .jl) | cut -c 5-
    end
alias lf := list-figs


# Clean up all figures
clean-figs:
    #! /bin/env fish
    for i in src/figures/src/fig_*.jl
        for j in src/figures/(basename $i .jl | cut -c 5-)*{.png,.pdf,.pdf_tex,.svg,.eps}
            if test -e $j
                echo Removing (basename $j)
                rm $j
            end
        end
    end
alias cf := clean-figs

# TODO: add some checks with `prosecheck` etc.
