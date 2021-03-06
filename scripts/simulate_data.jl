## Load packages
using DelimitedFiles
using DataStructures
using Missings
using LinearAlgebra
using Distributions
using StatsBase

include("import_tree.jl")

function simulate_next_gen(Q, aligned_DNA, branch_length)
    """
    Given a transition matrix (Q), a sequence of numbers 1:4 (representing sequenced DNA ACGT), and a
    branch length, this function simulates a new sequence.
    """

    ## New aligned_DNA
    new_aligned_DNA = ""

    ## Loop over the characters in the sequence
    for cur_c in aligned_DNA

        ## Get transition probabilities given branch length: P(t) = exp(Q*t).
        trans_probs = map(x -> max(0, x), exp(Q.*parse(Float64, branch_length)))[parse(Int64, cur_c),:]

        ## Get new character
        new_char = sample(1:4, Weights(trans_probs))

        new_aligned_DNA = string(new_aligned_DNA, new_char)
    end

    return(new_aligned_DNA)
end


## Function that takes a node, loops over each child, gets that generations DNA sequence,
## calls itself on that child
function next_generation(cur_node, Tree, Q)
    for i in 1:length(cur_node.children)
        ## Get child
        child_number = cur_node.children[i]
        child_node = Tree.nodes[child_number]
        ## Get branch length. Find row of "edges" matrix that corresponds to edge into child
        from_parent = findall(map(x -> x == string(child_number), Tree.edges[:,2]))
        ## Get branch length
        branch_length = Tree.edges[from_parent, 3][1]
        ## Get next generation sequence
        Tree.nodes[child_number].aligned_DNA = simulate_next_gen(Q, Tree.nodes[child_node.parent].aligned_DNA, branch_length)
        ##
        if typeof(child_node) != leaf
            next_generation(child_node, Tree, Q)
        end
    end

    return Tree
end

function convert_DNA_to_numeric(aligned_DNA)
    numeric_DNA = ""
    for i in aligned_DNA
        numeric_DNA = string(numeric_DNA, findfirst(string(i), "ACGT")[1])
    end
    return(numeric_DNA)
end

function convert_numeric_to_DNA(numeric_DNA)
    aligned_DNA = ""
    for i in numeric_DNA
        aligned_DNA = string(aligned_DNA, "ACGT"[parse(Int, i)])
    end
    return(aligned_DNA)
end

## String of aligned DNA
first_DNA_string = "ATGTTCATAAACCGGTGACTATTTTCAACTAATCACAAAGATATTGGTACTCTTTACCTTTTATTCGGTGCCTGAGCTGGCATGGTGGGGACTGCTCTTAGTCTTCTAATCCGGGCCGAACTGGGCCAACCTGGTACACTACTAGGAGATGATCAGATTTACAATGTAATCGTCACTGCCCATGCTTTTGTAATGATCTTTTTTATGGTGATGCCTATTATAATTGGAGGGTTCGGAAACTGATTGGTCCCATTAATAATTGGAGCTCCTGACATAGCATTTCCCCGAATAAACAACATGAGCTTCTGACTCCTCCCTCCATCCTTTCTACTCTTACTCGCCTCATCTATGGTAGAAGCCGGAGCAGGAACTGGGTGAACAGTATACCCACCCCTAGCCGGCAACCTGGCTCATGCAGGAGCATCCGTAGACCTAACTATTTTTTCACTACACCTGGCAGGTGTCTCCTCAATCTTGGGTGCTATTAATTTCATTACTACTATTATTAATATAAAACCTCCTGCCATGTCCCAATATCAAACACCTCTATTTGTCTGATCAGTCTTAATCACTGCTGTCTTACTACTTCTATCACTTCCAGTCTTAGCAGCGGGAATCACTATATTATTAACAGATCGAAACCTAAACACCACATTCTTTGACCCCGCTGGGGGAGGAGATCCTATCTTATACCAACACTTATTCTGATTCTTTGGCCATCCAGAAGTTTACATTTTAATCCTACCCGGTTTTGGGATAATCTCACATATTGTTACCTATTATTCAGGTAAAAAAGAACCCTTTGGCTACATGGGAATAGTTTGAGCCATGATATCAATCGGCTTCCTGGGCTTTATCGTATGAGCCCATCACATGTTTACTGTAGGAATGGATGTAGACACACGAGCATACTTTACATCAGCCACTATAATTATTGCCATTCCTACCGGGGTGAAAGTATTTAGTTGACTGGCTACTCTTCATGGAGGTAATATTAAATGGTCCCCTGCTATATTATGAGCCTTAGGCTTTATTTTCCTATTTACCGTAGGAGGCCTAACGGGAATTGTACTAGCAAACTCTTCATTAGACATTGTTCTTCACGACACATATTACGTAGTGGCCCACTTTCACTATGTCTTGTCAATAGGAGCAGTATTCGCTATCATAGGAGGCTTCGTCCATTGATTCCCCCTATTCTCAGGATATACCCTTGACAACACTTGAGCAAAGATTCACTTTACGATTATGTTTGTAGGAGTCAATATAACGTTCTTCCCTCAGCACTTCCTAGGCCTGTCCGGAATGCCACGACGTTATTCTGACTATCCAGATGCATATACAACTTGAAATACGATTTCCTCAATGGGCTCTTTCATCTCATTAACAGCAGTCATGTTAATAGTTTTCATAGTGTGAGAAGCTTTCGCATCCAAGCGAGAAGTGGCCATAGTAGAACTAACCACAACTAATCTTGAATGATTGCATGGATGTCCTCCTCCGTACCACACATTTGAAGAGCCAACTTACGTACTATTAAAATAA"

## Transition matrix
Q = [[-1.2 0.4 0.2 0.4]; [0.2 -1.2 0.4 0.4]; [0.4 0.4 -1.2 0.2]; [0.4 0.4 0.2 -1.2]]

## Given a tree, simulate data in leafs

## First, attach initial string of aligned_DNA to root. Need to find root.
## Should be entry 0, so start by checking that. If not, run through the rest to find it.
function sim_data(Tree, first_DNA, Q, ACGT, return_ACGT)
    if(ACGT)
        first_DNA = convert_DNA_to_numeric(first_DNA)
    end

    if(typeof(Tree.nodes[0]) == root)
        Tree.nodes[0].aligned_DNA = first_DNA
        root_node = 0
    else
        i = 1
        while(typeof(Tree.nodes[i]) != root)
            i+=1
        end

        Tree.nodes[i].aligned_DNA = first_DNA
        root_node = i
    end

    new_tree = next_generation(Tree.nodes[root_node], Tree, Q)

    if(return_ACGT)
        for cur_node in 0:length(Tree.nodes)-1
            new_tree.nodes[cur_node].aligned_DNA = convert_numeric_to_DNA(new_tree.nodes[cur_node].aligned_DNA)
        end
    end

    return(new_tree)
end

simulated_data = sim_data(test_tree, first_DNA_string, Q, true, true)
Tree = simulated_data

function extract_aligned_DNA(Tree)

    output = ["#Nexus"]

    for cur_node in 0:length(Tree.nodes)-1

        if(typeof(Tree.nodes[cur_node]) == leaf)
            cur_leaf = Tree.nodes[cur_node]

            output = append!(output, [string(cur_leaf.values[1], '\t', cur_leaf.aligned_DNA)])
            #string(cur_leaf.values[1], "\t", cur_leaf.aligned_DNA, "\n", output)
        end
    end
    return(output)
end

extract_aligned_DNA(simulated_data)

open("test_output.nex", "w") do io
    writedlm(io, extract_aligned_DNA(simulated_data))
end

writedlm
