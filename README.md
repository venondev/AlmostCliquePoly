# Introduction
This code is part of my bachelor thesis "On Efficient Cut-Based Data Reduction for Weighted Cluster Editing". It implements a data reduction rule called "AlmostClique" by Böcker et al. with polynomial running time and several optimizations to speed up the practical running time. 

The details on the data reduction rule can be found [here](https://link.springer.com/article/10.1007/s00453-009-9339-7)

The complete thesis will be available shortly.

# Installation

In this project, we use Julia as the main programming language and a C++ minimum cut implementation and heuristic for AlmostClique which we embed using CxxWrap for Julia.

## Julia
Install the Julia interpreter [here](https://julialang.org/downloads/)

Afterwards, install the following packages by first opening the julia interactive shell, pressing "ALTGR + ]" and entering the following command.

```
add DataStructures CxxWrap BenchmarkTools
```

## Libraries
Please first install the packages for the minimum cut library by Henziger, Noe, Schulz and Strash.
https://github.com/VieCut/VieCut

Navigate to the directory WCELib and change the value of CMAKE_PREFIX_PATH in CmakeLists.txt to the installation
of CXXWrap /home/USER/.julia/artifacts/ARTIFACT_ID.

Then, execute the build script build.sh .

## Test Dataset 
To test our implementation, we used the PACE Challenge 2021 Dataset.
Please follow the install instructions [here](https://github.com/PACE-challenge/Cluster-Editing-PACE-2021-instances)

# Usage

To run the polynomial-time algorithm, the Large Neighbourhood heuristic and AlmostClique heuristic tests run the following command:
```
./runTest.sh path/to/pace/dataset/root/data/weighted
```