#include "jlcxx/jlcxx.hpp"
#include "jlcxx/tuple.hpp"

#include <fstream>
#include <ext/alloc_traits.h>
#include <omp.h>

#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "algorithms/global_mincut/algorithms.h"
#include "algorithms/global_mincut/minimum_cut.h"
#include "common/configuration.h"
#include "common/definitions.h"
#include "data_structure/graph_access.h"
#include "data_structure/mutable_graph.h"
#include "io/graph_io.h"
#include "tools/random_functions.h"
#include "tools/string.h"
#include "tools/timer.h"
#include "costsgraph.h"
#include "almostclique.h"

#include <iostream>

typedef std::shared_ptr<mutable_graph> GraphPtr;

std::tuple<EdgeWeight, std::vector<NodeID>, std::vector<NodeID>> findMinCut(int64_t *starts, int64_t *ends, int64_t *weights, int n, int m) {
    auto cfg = configuration::getConfig();

    GraphPtr G = graph_io::createGraphFromEdgeList<mutable_graph>(starts, ends, weights, n, m);

    random_functions::setSeed(cfg->seed);

    auto mc = selectMincutAlgorithm<GraphPtr>("noi");

    EdgeWeight cut = mc->perform_minimum_cut(G);

    std::vector<NodeID> A;
    std::vector<NodeID> B;

    for (NodeID node : G->nodes()) {
        if (G->getNodeInCut(node)) {
            A.push_back(node);
        } else {
            B.push_back(node);
        }
    }

    return std::make_tuple(cut, A, B);
}

std::tuple<bool, std::vector<unsigned short>>getHeuristicSets(int64_t *starts, int64_t *ends, int64_t *weights, int n, int m) {
    CostsGraph G = CostsGraph(n, m, starts, ends, weights, 10e-20);

    std::vector<CostsGraph::byte_vector_type> cliques = std::vector< CostsGraph::byte_vector_type >(0);

    // apply almost clique rule and get set of cliques
    bool found = AlmostClique::get(G, cliques, 0., false);

    std::vector<unsigned short> set;

    return std::make_tuple(found, found ? cliques[0] : set);
}

JLCXX_MODULE define_julia_module(jlcxx::Module &mod) {
    mod.method("findMinCut", &findMinCut);
    mod.method("getHeuristicSets", &getHeuristicSets);
}