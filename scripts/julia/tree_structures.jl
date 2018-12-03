#################
## Create structures
## We use mutable struct for this to be able to change the entries

## root: contains a vector specifying children
mutable struct Root
    children::Array{Int64}
    values::Array{String}
    aligned_DNA
end

## node: contains an integer specifying the parent, and a vector specifying the children
mutable struct Node
    parent::Int64
    children::Array{Int64}
    values::Array{String}
    aligned_DNA
end

## leaf: contains an integer specifying the parent, and a vector specifygin the value(s) in the leaf
mutable struct Leaf
    parent::Int64
    values::Vector{String}
    aligned_DNA
end

mutable struct tree
    nodes::OrderedDict
    edges::Array{Union{Missing, String}}
end
