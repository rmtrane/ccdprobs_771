## Load packages
using DelimitedFiles
using DataStructures
using Missings
using LinearAlgebra
using Distributions
using StatsBase


## include structures and functions
include("tree_structures.jl")
include("tree_functions.jl")
include("simulation_functions.jl")

#cd("/Users/ralphmoellertran/Documents/UW-Madison/ccdprobs_771/simulation/estimated-trees/passer")

data_name=basename(pwd())

@show data_name

## Get tree to simulate from
text_tree_file = string(data_name, "_tree_for_sim.txt")
text_tree = readdlm(text_tree_file)[1][1:(end-1)] # remove ; at end

## Get corresponding stationary distribution
stat_dist = readdlm("stationary_distribution")

## Get corresponding transition probabilities
tran_prob = readdlm("transition_probabilities")

## Get length of aligned DNA
n_chars = readdlm("n_chars", Int)[1]
n_chars = (n_chars > 1000 ? Int(round(n_chars/2)) : n_chars)
writedlm("n_chars", n_chars)
pwd()

## Simulate first DNA string according to the stationary distribution
first_DNA = join(sample(1:4, Weights(map(x -> Float64(x), stat_dist[:, 2])), n_chars))

## Grow tree
julia_tree = grow_tree(text_tree)

## Transition matrix
Q_orig = hcat(vcat(0, tran_prob[1:3,2]), vcat([0; 0], tran_prob[4:5,2]), [0; 0; 0; tran_prob[6,2]], [0;0;0;0])
Q = Q_orig + Q_orig' - Diagonal(sum(Q_orig+Q_orig', dims = 1)[1,:])

## Simulate data
simulated_data = sim_data(julia_tree, first_DNA, Q, false, true)

## Get aligned DNA
aligned_DNA_raw = extract_aligned_DNA(simulated_data)

## Rearrange, so that it is in correct order.
ordered = map(x -> parse(Int, split(x, "\t")[1]), aligned_DNA_raw)
aligned_DNA = aligned_DNA_raw[sortslices([ordered 1:length(ordered)], dims = 1)[:,2]]

#########
#### Output .nex file

## For output statefreqpr
statefreqpr = string("Fixed(", join(stat_dist[:,2], ","), ")")
revmatpr = string("Fixed(", join(tran_prob[:,2], ","), ")")

## .nex file name
nex_output = string(data_name, "_sim_data.nex")

open(nex_output, "a") do io
    writedlm(io, aligned_DNA)
    write(io, ";\n")
    write(io,"end;\n")
    write(io, "begin mrbayes;\n")
    write(io, "\tset autoclose=yes nowarn=yes;\n")
    write(io, "\tprset brlenspr=unconstrained:exponential(10);\n")
    #write(io, string("\tprset statefreqpr=",statefreqpr, ";\n"))
    #write(io, string("\tprset revmatpr=",revmatpr, ";\n"))
    write(io, "\tmcmc ngen=1100000 printfreq=100 samplefreq=5;\n")
    write(io, "\tSumt burnin=100000 Conformat=Simple;\n")
    write(io, "\tSump burnin=100000;\n")
    write(io, "end;")
end

#########
#### For .fasta output

## Create initial Q for bistro calcs
Q_for_bistro = copy(Q_orig)+copy(Q_orig)'

## Function to convert mb q's to bistro q's
function q_mb_to_bistro(Q_for_bistro, stat_dist, tran_prob)
    mu = 0

    for i in 1:4
        mu += stat_dist[i,2]*sum(Q_for_bistro[:,i].*stat_dist[:,2])
    end

    tran_for_bistro = tran_prob
    for l = 0
        k = 1
        for i in 1:4
            for j in (i+1):4
                tran_for_bistro[k,2] = 2*stat_dist[i,2]*stat_dist[j,2]*Q_for_bistro[i,j]/mu
                j += 1; k += 1
                #@show k
            end
        end
    end
    return(mu, tran_for_bistro)
end

##
mu, tran_for_bistro = q_mb_to_bistro(Q_for_bistro, stat_dist, tran_prob)

fasta_output = string(data_name, "_sim_data.fasta")

open(fasta_output, "w") do io
    for i in 1:length(aligned_DNA)
        tmp = split(aligned_DNA[i], "\t")
        write(io, string(">", tmp[1],"\n", tmp[2], "\n"))
    end
end

open("stat_for_bistro", "w") do io
    write(io, join(stat_dist[:,2], ","))
end

open("tran_for_bistro", "w") do io
    write(io, join(tran_for_bistro[:,2], ","))
end
