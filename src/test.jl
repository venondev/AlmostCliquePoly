include("./data_reduction/polyAlgo.jl")
include("./data_reduction/heuristic.jl")
include("./data_reduction/neighbourhood.jl")

struct GraphInfo
    nodes::Int
    edges::Int
    nonEdges::Int
    components::Int
    mincut::Float64
end

function doUntilNoMerges(g::Graph, mode::Int, path::String)
    total_merges = 0
    k_decr = 0

    merges = 1
    while merges > 0
        # Data reduction rules
        if mode == 0
            merges, d = heuristicRule(g)
        elseif mode == 1
            merges, d = almostCliqueRule(g)
        elseif mode == 2
            merges, d = largeNeighbourhoodRule(g)
        end
    
        if g.test.functionCalls > 500
            println("Merges: $merges D: $d Calls: $(g.test.functionCalls) Size: $(size(g.indexes, 1)) Graph: $path")
        end

        total_merges += merges
        k_decr += d

        if merges > 0
            g.test.numberOfSetMerges += 1
        end
    end

    return total_merges, k_decr
end

function countEdges(g::Graph)
    c = 0
    for u = g.indexes, v = g.indexes
        if u != v && hasEdge(g, u, v)
            c += 1
        end
    end

    return c / 2
end

function getGraphInfos(g::Graph)
    nodes = size(g.indexes, 1)
    edges = countEdges(g)
    nonEdges = bino(nodes, 2) - edges
    components = size(getComponentGraphs(g), 1)

    mincutCost, A, B = calculateMincut(g, Set(g.indexes))

    return GraphInfo(nodes, edges, nonEdges, components, mincutCost)
end

function handleFile(root::String, f::String, mode::Int)
    g::Union{Graph, Nothing} = nothing

    if endswith(f, ".csv")
        g = readMatrixFromCSV(root, f)
    elseif endswith(f, ".cm")
        g = readMatrixFromCM(root, f)
    elseif endswith(f, ".dimacs")
        g = readMatrixFromFile("$root/$f")
    else
        return ""
    end


    components = getComponentGraphs(g)
    s = ""
    for (i, comp) in enumerate(components)
        g_new = createGraph(g.weights)
        g_new.indexes = collect(comp)
        g_new.indexes_lookup = fill(false, g.n_total)
        for u = g_new.indexes 
            g_new.indexes_lookup[u] = true
        end

        g_new.test.clusterGraphBefore = isClusterGraph(g_new, Set(g_new.indexes))
        info = getGraphInfos(g_new)

        println("[$mode]: Checking $root/$f/$i Nodes: $(info.nodes)")

        k_decr = 0.
        time = @elapsed begin
            merges, k_decr = doUntilNoMerges(g_new, mode, "$root/$f")
        end

        g_new.test.clusterGraphAfter = isClusterGraph(g_new, Set(g_new.indexes))

        test = g_new.test
        s_new = "$root/$f/$i,$(info.nodes),$(info.edges),$(info.nonEdges),$(info.components),$(info.mincut),$merges,$k_decr,$time,$(test.recursionDepth),$(test.functionCalls),$(test.fullySolved),$(test.numberOfSetMerges),$(test.clusterGraphBefore),$(test.clusterGraphAfter)\n"
        s = s * s_new
    end

    print(s)
    return s
end

function run(mode::Int, outFile::String, folder::String)
    p = normpath(joinpath(@__DIR__, folder))
    l = ReentrantLock()
    open(outFile, "w") do io
        write(io, "file,nodes,edges,nonEdges,components,mincut,merges,k_decr,time,recursionDepth,functionCalls,fullySolved,numberOfSetMerges,clusterGraphBefore,clusterGraphAfter\n")
        filesAll = []
        for (root, dirs, files) in walkdir(p)
            println("Checking $root")
            for f = files
                push!(filesAll, (root, f))
            end
        end
        println("Loaded files")

        Threads.@threads for (root, f) = filesAll
            s = handleFile(root, f, mode)
            if s != ""
                lock(l) do 
                    write(io, s)
                    flush(io)
                end
            end
        end
    end
end

if size(ARGS, 1) == 0
    println("Missing argument for test folder")
    println("Please call the algorithm with ./runTest path/to/pace/dataset/root/data/weighted")
    exit(1)
end

run(0, "../out_heuristik.csv", ARGS[1])
run(1, "../out_poly_exhaus.csv", ARGS[1])
run(2, "../out_ln_exhaus.csv", ARGS[1])