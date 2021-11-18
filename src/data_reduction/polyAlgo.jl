using BenchmarkTools
using Profile

include("../helper/graph.jl")
include("../helper/base.jl")
include("../helper/min_cut.jl")

"""
Calculates if the set of node S has any cut to V setminus S.
"""
function hasOutsideCut(sideFull::Set{Int}, fixedCutCost::Array{Float64, 1})
    # Get cut from fixedcutcost sum
    for u in sideFull
        if fixedCutCost[u] > 0
            return true
        end
    end

    return false
end

"""
Calculates if there is set that satisfies for one side of the chosen minimum cut,
as described in Observation 4.10 .
"""
function checkMincutSide(g::Graph, side::Set{Int}, otherSide::Set{Int}, otherSideCutNodes::Set{Int}, indixes::Set{Int}, fixedCutCost::Array{Float64, 1}, mincutCost::UInt64)
    
    # Side including the cut nodes on the other side
    sideFull = union(side, otherSideCutNodes)

    # If the side has any deficiency,
    # then we know that the side can't be part of a set that satisfies the merge condition.
    if !hasDeficiency(g, sideFull)
        return Int[]
    end

    # If the side has any outside cut cost, 
    # then we know that the side can't be part of a set that satisfies the merge condition.
    if !hasOutsideCut(sideFull, fixedCutCost)
        return Int[]
    end

    # Build up candidate sets, which might increase the mincut or decrease the cut cost
    C = Int[]
    for u in otherSide
        if !(u in otherSideCutNodes) && !hasDeficiencyNode(g, sideFull, u) && fixedCutCost[u] == 0
            push!(C, u)
        end
    end

    if isempty(C)
        # No other candidate sets possible, return side if it satisfies the merge condition
        if checkMincutRule(g, sideFull, indixes)
            return sideFull
        else
            return Int[]
        end
    elseif size(C, 1) == 1
        push!(sideFull, C[1])
        if checkMincutRule(g, sideFull, indixes)
            return sideFull
        else
            return Int[]
        end
    end

    restcut = 0.
    for u in otherSide
        # Every node on the other side is part of the rest cut, if it is not in the cutnodes or in the candidate set C
        if !(u in otherSideCutNodes) || hasDeficiencyNode(g, sideFull, u) || fixedCutCost[u] != 0
            for v in otherSideCutNodes
                if hasEdge(g, u, v)
                    restcut += getWeight(g, u, v)
                end

            end

            # If the rest cut is already bigger than the minimum cut cost of the whole subgraph S,
            # then we know that there is no set that satisfies the merge condition,
            # as described in chapter 4.3
            if restcut > mincutCost
                return Int[]
            end
        end
    end

    # When we reach this line, there still could be a set that satisfies the merge condition
    # and it would be required to calculate all minimum cuts. Fortunately, for the tested graphs,
    # this is never the case.
    g.test.fullySolved = false

    return Int[]
end

"""
Calculates if there exists a set with nodes on both sides of the minimum cut
"""
function checkOverMincut(g::Graph, mincutCost::UInt64, indixes::Set{Int}, A::Set{Int}, B::Set{Int}, cutNodesA::Set{Int}, cutNodesB::Set{Int}, hasZeroEdges::Bool, fixedCutCost::Array{Float64, 1})::Set{Int}
    cutNodes = union(cutNodesA, cutNodesB)

    # If there is deficiency between cutnodes,
    # then there is no set that satisfies the merge condition over the minimum cut
    if hasDeficiency(g, cutNodes)
        return Set{Int}()
    end

    # If there is a outside cut cost between cutnodes,
    # then there is no set that satisfies the merge condition over the minimum cut
    if hasOutsideCut(cutNodes, fixedCutCost)
        return Set{Int}()
    end

    # If there are no zero-edges in the whole graph then every non-edge has cost of at least 1,
    # as the deficiency has to be zero for sets with nodes on both side of the cut, this means
    # that the cutnodes are the only possible set across the mincut that could satisfy the merge condition.
    if !hasZeroEdges
        if checkMincutRule(g, cutNodes, indixes)
            return cutNodes
        else
            return Set{Int}()
        end
    end

    if !checkZeroEdges(g, A, B)
        if checkMincutRule(g, cutNodes, indixes)
            return cutNodes
        else
            return Set{Int}()
        end
    end

    # Otherwise we check each side of the minimum cut individually.
    ASide = checkMincutSide(g, A, B, cutNodesB, indixes, fixedCutCost, mincutCost)
    if !isempty(ASide)
        return ASide
    end

    BSide = checkMincutSide(g, B, A, cutNodesA, indixes, fixedCutCost, mincutCost)
    if !isempty(BSide)
        return BSide
    end

    return Set{Int}()
end

"""
Calculates a list of node sets that satisfies the merge condition
"""
function calcAlmostClique(g::Graph, S::Set{Int}, indixes::Set{Int}, fixedCutCost::Array{Float64, 1}, hasZeroEdge::Bool, depth::Int)::Array{Set{Int}, 1}
    depth += 1
    g.test.recursionDepth = max(g.test.recursionDepth, depth)
    g.test.functionCalls += 1

    if g.test.functionCalls % 500 == 0
        println(g.test.functionCalls)
    end

    if length(S) <= 1
        return Set{Int}[]
    end

    # Get cut from fixedcutcost sum
    cutCost = 0
    for u in S
        cutCost += fixedCutCost[u]
    end

    mincutCost, A, B, = calculateMincut(g, S)

    if mincutCost < cutCost || mincutCost < cutCost + def(g, S)
        if (length(S) == 2)
            return Int[]
        end

        cutNodesA = Set{Int}()
        cutNodesB = Set{Int}()

        for u in A, v in B
            if u != v && hasEdge(g, u, v)
                push!(cutNodesA, u)
                push!(cutNodesB, v)
            end
        end

        c = checkOverMincut(g, mincutCost, indixes, A, B, cutNodesA, cutNodesB, hasZeroEdge, fixedCutCost)
        if !isempty(c)
            return [c]
        end

        # Update the outside cut cost of the cut nodes
        for u in cutNodesA, v in cutNodesB
            if u != v && hasEdge(g, u, v)
                w = getWeight(g, u, v)
                fixedCutCost[u] += w
                fixedCutCost[v] += w
            end
        end

        ret = Set{Int}[]
        a = calcAlmostClique(g, A, indixes, fixedCutCost, hasZeroEdge ? checkZeroEdges(g, A, A) : false, depth)
        if !isempty(a)
            ret = vcat(ret, a)
        end

        b = calcAlmostClique(g, B, indixes, fixedCutCost, hasZeroEdge ? checkZeroEdges(g, B, B) : false, depth)
        if !isempty(b)
            ret = vcat(ret, b)
        end

        return ret
    else
        return [S]
    end
end

"""
Checks if there are any zero-edges between A and B
"""
function checkZeroEdges(g::Graph, A::Set{Int}, B::Set{Int})
    hasZeroEdge = false
    for u in A
        for v in B
            if (getWeight(g, u, v) == 0)
                hasZeroEdge = true
                break
            end
        end

        if hasZeroEdge
            break
        end
    end

    return hasZeroEdge
end

"""
Inits the recursion
"""
function solve(g::Graph, fixedCutCost::Array{Float64, 1}, indexes::Set{Int})
    hasZeroEdge = checkZeroEdges(g, indexes, indexes)

    return calcAlmostClique(g, indexes, indexes, fixedCutCost, hasZeroEdge, 0)
end

"""
Applies almost clique once for each component
"""
function almostCliqueRule(g::Graph)
    fixedCutCost = fill(0., g.n_total)
    components = getComponentGraphs(g)

    k_decr = 0.
    merges = 0

    for comp in components
        if isClusterGraph(g, comp)
            continue
        end

        sets = solve(g, fixedCutCost, comp)

        for setss in sets
            set = collect(setss)
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
    end

    return merges, k_decr
end
