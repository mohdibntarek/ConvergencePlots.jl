const GOLDEN_ANGLE_DEG = 180 * (3 - sqrt(5))

"""
    defaultcolor(i::Integer)

Return the default color of curve `i` as a `Colors.RGB{Float64}` colorant.
The colors are generated deterministically using the golden angle hue
sequence so that consecutive curves get visually distinct colors.
"""
defaultcolor(i::Integer) = convert(
    RGB{Float64},
    HSV(mod((i - 1) * GOLDEN_ANGLE_DEG, 360), 0.65, 0.72),
)

function getoptions(names, old_options)
    options = Dict{String,NamedTuple}()
    if old_options === nothing
        for n in names
            options[n] = (label = n,)
        end
    elseif old_options isa Dict
        for n in names
            if haskey(old_options, n)
                if haskey(old_options[n], :label)
                    options[n] = old_options[n]
                else
                    options[n] = merge(old_options[n], (label = n,))
                end
            else
                options[n] = (label = n,)
            end
        end
    else # Same options for all names
        for n in names
            options[n] = merge(old_options, (label = n,))
        end
    end
    # Deterministic default colors for all the curves so that curves sharing
    # or twinning axes never get the same color.
    for (i, n) in enumerate(names)
        if !haskey(options[n], :color)
            options[n] = merge(options[n], (color = defaultcolor(i),))
        end
    end
    return options
end
