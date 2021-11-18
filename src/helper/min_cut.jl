using DataStructures
include("./graph.jl")

function calculateMincut(g::Graph, indexes::Set{Int})
    starts = Int[]
    ends = Int[]
    weights = Int[]

    indexes_arr = collect(indexes)
    n = size(indexes_arr, 1)

    for i = 1:n
        u = indexes_arr[i]
        for j = i+1:n
            v = indexes_arr[j]
            weight = getWeight(g, u, v)
            if weight > 0
                push!(starts, i - 1)
                push!(ends, j - 1)
                push!(weights, weight)
            end
        end
    end
    m = size(starts, 1)

    cutWeight, A_vec, B_vec = CppWCE.findMinCut(starts, ends, weights, n, m)
    A = convertUInt32ToSet(A_vec, indexes_arr)
    B = convertUInt32ToSet(B_vec, indexes_arr)

    return cutWeight, A, B
end