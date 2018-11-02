## Load packages
using DelimitedFiles
using DataStructures
using Missings

## Read in data
cats_dogs_out = readdlm("cats-dogs/cats-dogs-ccdprobs.out")
cats_dogs_out[:,1] = map(x -> strip(x, [';']), cats_dogs_out[:,1])

## Get a single tree
text_tree = cats_dogs_out[1,1]

#################
## Create structures
## We use mutable struct for this to be able to change the entries

## root: contains a vector specifying children
mutable struct root
    children::Array{Int64}
    values::Array{String}
end

## node: contains an integer specifying the parent, and a vector specifying the children
mutable struct node
    parent::Int64
    children::Array{Int64}
    values::Array{String}
end

## leaf: contains an integer specifying the parent, and a vector specifygin the value(s) in the leaf
mutable struct leaf
    parent::Int64
    values::Vector{String}
end

function grow_tree(text_tree)
    """
    This function takes a text string that specifies a tree, and returns a dictionary with one root and an a
    appropriate number of internal nodes and leafs.
    """

    ## Initiate Tree
    Tree = Dict()

    ## Create empty root
    Tree[1] = root([], [])

    ## The next two variables are householding variables: the first keeps track of
    ## where in the tree we are, the next keeps track of the numbering of the next
    ## node to be created.
    cur_node = 1
    next_node = 2

    ## To keep track of where in the text string we are
    i = 0
    while (i < length(text_tree))
        ## Go to next character
        i+=1
        ## Get the current character
        cur_char = text_tree[i]
        ## If the character is left parenthesis...
        if cur_char == '('
            ## ... fill out children
            Tree[cur_node].children = sort(vcat(Tree[cur_node].children, next_node))
            ## ... create new node
            Tree[next_node] = node(cur_node, [], [])
            ## ... move into new node
            cur_node = next_node
            ## ... specify number of next_node
            next_node += 1
            ## If the character is right parenthesis...
        elseif cur_char == ')'
            ## ... save values in current node
            vals = Tree[cur_node].values
            ## ... move to parent node of current node
            cur_node = Tree[cur_node].parent
            ## ... fill out values
            Tree[cur_node].values = sort(vcat(Tree[cur_node].values, vals))
            ## If the character is a digits...
        elseif !(cur_char in [')' '(' ','])
            ## ... current node is actually a leaf, so we want to overwrite it.
            ## To find the value to put in the leaf, we need to check next character
            next_char = text_tree[i+1]
            ## As long as it is not '(', ')', or ',', we keep concatenating
            while !(next_char in [')', '(', ','])
                cur_char = string(cur_char, next_char)
                #cur_char = parse(Int64, cur_char)
                i = i+1
                next_char = text_tree[i+1]
            end
            ## Convert current node to leaf
            Tree[cur_node] = leaf(Tree[cur_node].parent, [string(cur_char)])
            ## If the character is a comma...
        elseif cur_char == ','
            ## ... save values in current node
            vals = Tree[cur_node].values
            ## ... go up
            cur_node = Tree[cur_node].parent
            ## ... create new child
            Tree[cur_node].children = sort(vcat(Tree[cur_node].children, next_node))
            ## ... fill out values
            Tree[cur_node].values = sort(vcat(Tree[cur_node].values, vals))
            ## ... and fill out parent of next_node
            Tree[next_node] = node(cur_node, [], [])
            ## Go to next_node...
            cur_node = next_node
            ## ... and keep track of what next node should be called
            next_node += 1
        end
    end
    return(sort(Tree))
end

## Get all trees
all_trees = map(tree -> grow_tree(tree), cats_dogs_out[:,1])
