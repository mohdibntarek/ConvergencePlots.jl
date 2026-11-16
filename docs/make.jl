using DocumenterFragments: build_fragment

# Links to sibling packages (e.g. `../core/...`) only resolve in the assembled
# Nonconvex.jl documentation site, so tolerate broken local cross-references
# in this standalone preview build.
build_fragment(@__DIR__; checkdocs=:public, doctest=false, warnonly=[:cross_references])
