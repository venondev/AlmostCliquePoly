include("../helper/graph.jl")
include("../helper/cpp_embedding.jl")

"""
Tries to find a set of nodes that satisfies AlmostClique,
by using the heuristic approach present by Böcker et al. 
in "Exact Algorithms for Cluster Editing: Evaluation and Experiments".

Calls their implementation in C++.
"""
function getHeuristicSets(g::Graph, indexes::Set{Int})::Set{Int64}
    starts = Int[]
    ends = Int[]
    weights = Int[]

    indexes_arr = collect(indexes)
    n = size(indexes_arr, 1)

    # Convert graph to node pair list to be able to pass it to C++ wrapper
    for i = 1:n
        u = indexes_arr[i]
        for j = i+1:n
            v = indexes_arr[j]
            push!(starts, i - 1)
            push!(ends, j - 1)
            push!(weights, getWeight(g, u, v))
        end
    end

    m = size(starts, 1)

    # Call AlmostClique heuristic implementation in C++
    found, sets_r = CppWCE.getHeuristicSets(starts, ends, weights, n, m)

    if Bool(found)
        return convertUInt32ToSet(sets_r, indexes_arr)
    else
        return Set{Int64}()
    end
end

"""
Applies the AlmostClique heuristic to every component in G once.
"""
function heuristicRule(g::Graph)
    components = getComponentGraphs(g)

    k_decr = 0.
    merges = 0

    for comp in components
        if isClusterGraph(g, comp)
            continue
        end

        set = collect(getHeuristicSets(g, comp))

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