randcolor(rng) = (rand(rng), rand(rng), rand(rng)) .* 0.7

function getoptions(names, old_options)
    rng = Random.MersenneTwister()
    Random.seed!(rng, 12344321)

    options = Dict()
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

    # Fix the same color problem when using 2 y-axes
    for i in 1:(length(names) ÷ 2)
        n1, n2 = names[2i - 1], names[2i]
        if !(haskey(options[n2], :color))
            options[n2] = merge(options[n2], (color = randcolor(rng),))
        end
        if !(haskey(options[n1], :color))
            options[n1] = merge(options[n1], (color = randcolor(rng),))
        end
    end
    if mod(length(names), 2) == 1
        n = names[end]
        if !(haskey(options[n], :color))
            options[n] = merge(options[n], (color = randcolor(rng),))
        end
    end
    return options
end
