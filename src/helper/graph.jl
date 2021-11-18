using DataStructures
include("./math.jl")

MULTIPLIER = 1000

# Types
P3 = Tuple{Int,Int,Int}
FloatArray = Array{Float64,1}
IntMatrix = Array{Int,2}
IntArray = Array{Int,1}
BoolArray = Array{Bool,1}

struct Merge
    u_weights::FloatArray
    u::Int
    v::Int
    k_decr::Float64
end

struct ClusterRemove
    indexes::Array{Int64,1}
end

struct AddEdge
    u::Int
    v::Int
    weight::Float64
end

struct SetForbidden
    u::Int
    v::Int
    weight::Float64
end

struct MergeNonForbidden
    u_weights::FloatArray
    u::Int
    v::Int
end

mutable struct TestResult
    recursionDepth::Int
    functionCalls::Int
    fullySolved::Bool
    numberOfSetMerges::Int
    clusterGraphBefore::Bool
    clusterGraphAfter::Bool
end

Change = Union{Merge, MergeNonForbidden, ClusterRemove, SetForbidden, AddEdge}
mutable struct Graph
    n_total::Int
    weights::IntMatrix
    changeStack::Stack{Change}
    indexes::Array{Int64, 1}
    indexes_lookup::Array{Bool, 1}
    foundSolution::Bool
    test::TestResult
end

@enum OpType begin
    mergeOp = 1
    deleteOp = 2
    setForbiddenOp = 3
    addOp = 4
end

struct Operation
    type::OpType
    u::Int
    v::Int
end

function createGraph(matrix)
    n = size(matrix, 1)

    test = TestResult(0, 0, true, 0, false, false)

    g = Graph(n, matrix, Stack{Change}(), [i for i in 1:n], fill(true, n), false, test)
    return g
end

function getWeight(g::Graph, u::Int, v::Int)::Float64
    return @inbounds g.weights[u, v]
end

function setWeight(g::Graph, u::Int, v::Int, value::Float64)
    @inbounds g.weights[u, v] = value
    @inbounds g.weights[v, u] = value
end

function hasEdge(g::Graph, u::Int, v::Int)::Bool
    return @inbounds g.weights[u, v] > 0
end

function merge!(g::Graph, u::Int, v::Int)::Float64
    u_weights = fill(-1.0, g.n_total)
    k_decr = 0.
    filter!(x -> x != v, g.indexes)
    @inbounds g.indexes_lookup[v] = false

    for i = g.indexes
        if i == u || i == v continue end

        u_i = getWeight(g, u, i)
        v_i = getWeight(g, v, i)

        @inbounds u_weights[i] = u_i

        # decrease k and update has_edge
        if hasEdge(g, u, i) != hasEdge(g, v, i)
            k_decr += min(abs(u_i), abs(v_i))
        end

        # update weights
        setWeight(g, u, i, u_i + v_i)
    end

    push!(g.changeStack, Merge(u_weights, u, v, k_decr))
    return k_decr
end

function mergeNonForbidden(g::Graph, u::Int, v::Int)
    u_weights = fill(-1.0, g.n_total)
    filter!(x -> x != v, g.indexes)
    @inbounds g.indexes_lookup[v] = false

    for i = g.indexes
        if i == u || i == v continue end

        u_weights[i] = getWeight(g, u, i)

        u_i = max(0, getWeight(g, u, i))
        v_i = max(0, getWeight(g, v, i))

        setWeight(g, u, i, u_i + v_i)
    end

    push!(g.changeStack, MergeNonForbidden(u_weights, u, v))
end

function undoAll!(g::Graph)
    while !isempty(g.changeStack)
        undo(g, pop!(g.changeStack))
    end
end

function undoK(g::Graph, k::Int)
    for i = 1:k
        if isempty(g.changeStack) break end
        undo(g, pop!(g.changeStack))
    end
end

function undo(g::Graph, addEdge::AddEdge)
    setWeight(g, addEdge.u, addEdge.v, addEdge.weight)
end

function undo(g::Graph, merge::Merge)
    for i = g.indexes
        if i == merge.u || i == merge.v continue end

        if g.foundSolution
            setWeight(g, merge.v, i, getWeight(g, merge.u, i))
        else
            setWeight(g, merge.u, i, @inbounds merge.u_weights[i])
        end
    end

    push!(g.indexes, merge.v)
    @inbounds  g.indexes_lookup[merge.v] = true
end

function undo(g::Graph, merge::MergeNonForbidden)
    for i = g.indexes
        if i == merge.u || i == merge.v continue end

        setWeight(g, merge.u, i, @inbounds merge.u_weights[i])
    end

    push!(g.indexes, merge.v)
    @inbounds  g.indexes_lookup[merge.v] = true
end

function isClusterGraph(g::Graph, indexes::Set{Int})::Bool
    visited = fill(false, g.n_total)
    q = Queue{Int}()

    degree = fill(0, g.n_total)
    ccsize = fill(0, g.n_total)
    rootNode = fill(0, g.n_total)
    for cur = indexes
        @inbounds if visited[cur] continue end

        @inbounds visited[cur] = true
        enqueue!(q, cur)

        compSize = 0
        while !isempty(q)
            compSize += 1
            u = dequeue!(q)

            rootNode[u] = cur

            degreeU = 0
            for v in indexes
                if hasEdge(g, u, v)
                    if !visited[v]
                        @inbounds visited[v] = true
                        enqueue!(q, v)
                    end
                    degreeU += 1
                end
            end
            degree[u] = degreeU
        end
        ccsize[cur] = compSize
    end

    for cur = indexes
        if degree[cur] < ccsize[rootNode[cur]] - 1
            return false
        end
    end

    return true
end

function getComponentGraphs(g::Graph)::Array{Set{Int}, 1}
    visited = fill(false, g.n_total)
    q = Queue{Int}()

    graphs::Array{Set{Int}, 1} = []
    for cur = g.indexes
        @inbounds if visited[cur] continue end

        @inbounds visited[cur] = true
        enqueue!(q, cur)

        indices = Set{Int}()
        while !isempty(q)
            u = dequeue!(q)

            push!(indices, u)

            for v in g.indexes
                if hasEdge(g, u, v)
                    if !visited[v]
                        @inbounds visited[v] = true
                        enqueue!(q, v)
                    end
                end
            end
        end

        push!(graphs, indices)
    end

    return graphs
end

function readMatrixFromFile(path)::Graph
    open(path, "r") do io
        f = read(io, String)

        lines = split(f, "\n")
        pop!(lines)
        n = parse(Int, popat!(lines, 1))

        matrix = fill(-1., (n, n))

        for line = lines
            pieces = split(line, ' ', keepempty=false)
            pieces = map(x -> parse(Int, x), pieces)

            s, e, weight = pieces
            matrix[s, e] = weight
            matrix[e, s] = weight
        end
        return createGraph(matrix)
    end
end

function printEdges(g::Graph)
    println("========================")
    n = size(g.indexes, 1)

    for i = g.indexes
        println("$i")
    end

    #println("$n")


    for i = 1:size(g.indexes, 1)
        u = g.indexes[i]
        for j = i + 1:size(g.indexes, 1)
            v = g.indexes[j]
            if g.weights[u, v] >= 0
                println("$u $v $(g.weights[u, v])")
            end
        end
    end
    println("========================")
end

function readMatrixFromCSV(root::String, path::String)
    inputPath = "$root/$path"

    matrix = nothing
    open(inputPath, "r") do inputFile
        i = 1
        n = -1
        while !eof(inputFile)
            line = readline(inputFile)
            if line == ""
                continue
            end

            if !startswith(line, "#")
                similarities = split(line, ",")

                if n == -1
                    n = size(similarities, 1)

                    matrix = fill(-1., (n, n))
                end

                for j = i+1:n
                    weight = round(Int, (parse(Float64, similarities[j]) * 2. - 1.) * MULTIPLIER)
                    matrix[i, j] = weight
                    matrix[j, i] = weight
                end

                i += 1
            end
        end
    end

    return createGraph(matrix)
end

function readMatrixFromCM(root::String, path::String)
    inputPath = "$root/$path"

    matrix = nothing
    open(inputPath, "r") do inputFile
        n = parse(Int, readline(inputFile))
        matrix = fill(-1, (n, n))
    
        for i = 1:n
            readline(inputFile)
        end

        for i = 1:n-1
            line = readline(inputFile)

            splits = split(line, "\t")
            for (j, value) = enumerate(splits)
                weight = round(Int, parse(Float64, value) * 1000)
                j_index = i + j

                matrix[i, j_index] = weight
                matrix[j_index, i] = weight
            end
        end
    end

    return createGraph(matrix)
end

function copy(m::Merge)
    return Merge(copy(m.u_weights), m.u, m.v, m.k_decr)
end

function copy(s::SetForbidden)
    return SetForbidden(s.u, s.v, s.weight)
end

function copy(c::ClusterRemove)
    return ClusterRemove(copy(c.indexes))
end

function copy(m::FloatArray)
    ret = fill(-1., size(m, 1))

    for i = 1:size(ret, 1)
        ret[i] = m[i]
    end

    return ret
end

function copy(m::IntArray)
    ret = fill(5, size(m, 1))

    for i = 1:size(ret, 1)
        ret[i] = m[i]
    end

    return ret
end

function copy(m::BoolArray)
    ret = fill(false, size(m, 1))

    for i = 1:size(ret, 1)
        ret[i] = m[i]
    end

    return ret
end

function copy(m::IntMatrix)
    ret = fill(-1.0, size(m))

    for i in 1:size(ret, 1), j in 1:size(ret, 2)
        ret[i, j] = m[i, j]
    end

    return ret
end

function copy(s::Stack{Change})
    ret = Stack{Change}()
    ret2 = Stack{Change}()
    for m in s
        push!(ret, copy(m))
    end

    for m in ret
        push!(ret2, m)
    end

    return ret2
end

function copy(g::Graph)
    return Graph(g.n_total, copy(g.weights), copy(g.changeStack), copy(g.indexes), copy(g.indexes_lookup), g.foundSolution, g.test)
end
