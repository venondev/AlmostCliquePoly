function cut(g::Graph, S::Set{Int}, indixes::Set{Int})
    c = 0.
    R = setdiff(indixes, S)
    for v in S, w in R
        if hasEdge(g, v, w)
            c += getWeight(g, v, w)
        end
    end
    return c
end

function def(g::Graph, S::Set{Int})
    d = 0.
    l = length(S)
    for u = S, v = S
        if u != v && !hasEdge(g, u, v)
            d += abs(getWeight(g, u, v))
        end
    end

    return d / 2
end

function hasDeficiencyNode(g::Graph, A::Set{Int}, v::Int)::Bool
    for u in A
        if u != v && getWeight(g, u, v) < 0
            return true
        end
    end
    return false
end

function hasDeficiency(g::Graph, S::Set{Int})::Bool
    for u in S, v in S
        if u != v && getWeight(g, u, v) < 0
            return true
        end
    end
    return false
end

function checkMincutRule(g::Graph, S::Set{Int}, indixes::Set{Int})
    mc, A, B, = calculateMincut(g, Set(g.indexes))
    c = cut(g, S, indixes)
    d = def(g, S)
    return mc >= c + d
end

function convertUInt32ToSet(nodes, indexes_arr::Array{Int, 1})
    n = size(nodes, 1)
    ret = fill(0, n)
    for i in 1:n
        ret[i] = indexes_arr[nodes[i] + 1]
    end

    return Set(ret)
end