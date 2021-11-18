# Introduction
TODO

# Installation

## Julia
Install the Julia interpreter from https://julialang.org/downloads/

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
Please follow the install instructions here: https://github.com/PACE-challenge/Cluster-Editing-PACE-2021-instances

# Usage

To run polynomial time algorithm, the neighbourhood heuristic and almost clique heuristic tests run the following command:
```
./runTest.sh path/to/pace/dataset/root/data/weighted
```