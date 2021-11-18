include("../helper/graph.jl")
include("../helper/min_cut.jl")

function large_neighbourhood(g::Graph, indexes::Set{Int})
    for u in indexes
        N::IntArray = [u]
        rest::IntArray = []
        def::Float64 = 0
        cut::Float64 = 0

        for i in indexes
            if i == u continue end

            if hasEdge(g, u, i)
                push!(N, i)
            else
                push!(rest, i)
            end
        end
        n_neigh = size(N, 1)

        if n_neigh == 1 continue end

        found_zero_edge = false
        for i = 1:n_neigh
            @inbounds w = N[i]
            for j = i + 1:n_neigh
                @inbounds v = N[j]

                if g.weights[v, w] == 0.
                    found_zero_edge = true
                    break
                end

                if !hasEdge(g, v, w)
                    def += abs(getWeight(g, v, w))
                end
            end

            if found_zero_edge
                break
            end
        end

        if found_zero_edge
            continue
        end

        for i in N, j in rest
            if hasEdge(g, i, j)
                cut += getWeight(g, i, j)
            end
        end

        if 2 * def + cut < size(N, 1)
            return N
        end

        minCut, A, B = calculateMincut(g, Set(N))

        # println("mincut $(def + cut) $minCut $N")
        if def + cut < minCut
            return N
        end
    end

    return Int[]
end

function largeNeighbourhoodRule(g::Graph)
    components = getComponentGraphs(g)

    k_decr = 0.
    merges = 0

    for comp in components
        if isClusterGraph(g, comp)
            continue
        end

        set = collect(large_neighbourhood(g, comp))

        if (!isempty(set))
            u = set[1]

            for v in set
                if v == u continue end

                if !hasEdge(g, u, v)
                    w = getWeight(g, u, v)
                    k_decr += abs(w)
                end

                k_decr += merge!(g, u, v)
                merges += 1
            end
        end
    end

    return merges, k_decr
end