## Load packages
using DelimitedFiles
using DataStructures
using Missings

## Read in data
cats_dogs_out = readdlm("cats-dogs/cats-dogs-ccdprobs.out")
cats_dogs_out[:,1] = map(x -> strip(x, [';']), cats_dogs_out[:,1])

## Get a single tree
#text_tree = cats_dogs_out[1,1]
text_tree = "(1:0.0556631,2:0.0693414,((3:0.0739067,((4:0.039114,5:0.0372726):0.0130065,6:0.057055):0.00748735):0.0154953,(((((7:0.00397016,8:0.000611082):0.0220259,9:0.0203416):0.0245329,10:0.0530554):0.0427686,11:0.0850486):0.00315267,12:0.0918821):0.0877109):0.0095466)"
text_tree = "((((((gray_wolf,dog),coyote),dhole),racoon_dog),red_fox),(((tiger,(snow_leopard,leopard)),clouded_leopard),(cheetah,cat)))"
#################
## Create structures
## We use mutable struct for this to be able to change the entries

## root: contains a vector specifying children
mutable struct root
    children::Array{Int64}
    values::Array{String}
    aligned_DNA
end

## node: contains an integer specifying the parent, and a vector specifying the children
mutable struct node
    parent::Int64
    children::Array{Int64}
    values::Array{String}
    aligned_DNA
end

## leaf: contains an integer specifying the parent, and a vector specifygin the value(s) in the leaf
mutable struct leaf
    parent::Int64
    values::Vector{String}
    aligned_DNA
end

mutable struct tree
    nodes::OrderedDict
    edges::Array{Union{Missing, String}}
end

function grow_tree(text_tree)
    """
    This function takes a text string that specifies a tree, and returns a dictionary with one root and an a
    appropriate number of internal nodes and leafs.
    """

    ## Initiate Tree
    Tree = tree(OrderedDict(), Array{Union{Missing, Float64}}(missing, 0, 3))

    ## Create empty root
    Tree.nodes[0] = Root([], [], nothing)

    ## The next two variables are householding variables: the first keeps track of
    ## where in the tree we are, the next keeps track of the numbering of the next
    ## node to be created.
    cur_node = 0
    next_node = 1

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
            Tree.nodes[cur_node].children = sort(vcat(Tree.nodes[cur_node].children, next_node))
            ## ... create new node
            Tree.nodes[next_node] = node(cur_node, [], [], nothing)
            ## ... create entry in array of edges
            #Tree.edges = append!(Tree.edges, [cur_node next_node missing])
            ## ... move into new node
            cur_node = next_node
            ## ... specify number of next_node
            next_node += 1
        ## If the character is right parenthesis...
        elseif cur_char == ')'
            ## ... save values in current node
            vals = Tree.nodes[cur_node].values
            ## ... move to parent node of current node
            cur_node = Tree.nodes[cur_node].parent
            ## ... fill out values
            Tree.nodes[cur_node].values = sort(vcat(Tree.nodes[cur_node].values, vals))
            ## If the character is a digits...
        elseif !(cur_char in [')' '(' ',' ':'])
            ## ... current node is actually a leaf, so we want to overwrite it.
            ## To find the value to put in the leaf, we need to check next character
            next_char = text_tree[i+1]
            ## As long as it is not '(', ')', or ',', we keep concatenating
            while !(next_char in [')', '(', ',', ':'])
                cur_char = string(cur_char, next_char)
                #cur_char = parse(Int64, cur_char)
                i = i+1
                next_char = text_tree[i+1]
            end
            ## Convert current node to leaf
            Tree.nodes[cur_node] = leaf(Tree.nodes[cur_node].parent, [string(cur_char)], nothing)
            ## If the character is a comma...
        elseif cur_char == ','
            ## ... save values in current node
            vals = Tree.nodes[cur_node].values
            ## ... go up
            cur_node = Tree.nodes[cur_node].parent
            ## ... create new child
            Tree.nodes[cur_node].children = sort(vcat(Tree.nodes[cur_node].children, next_node))
            ## ... fill out values
            Tree.nodes[cur_node].values = sort(vcat(Tree.nodes[cur_node].values, vals))
            ## ... and fill out parent of next_node
            Tree.nodes[next_node] = node(cur_node, [], [], nothing)
            ## Go to next_node...
            cur_node = next_node
            ## ... and keep track of what next node should be called
            next_node += 1
        ## If next character is ":", the next thing we'll get is the branch length.
        elseif cur_char == ':'
            ## We have to run through and find the next "(", ")", or ",". We now that the
            ## next character will be a digit, so we skip ahead to this. This way we avoid
            ## including ':' in our result
            cur_char = text_tree[i+1]
            next_char = text_tree[i+2]
            i = i+2
            while !(next_char in [')', '(', ',', ':'])
                cur_char = string(cur_char, next_char)
                #cur_char = parse(Int64, cur_char)
                i = i+1
                next_char = text_tree[i+1]
            end
        end
        ## Collect the result as [parent_node child_node branch_length]:
        res = [string(Tree.nodes[cur_node].parent) string(cur_node) string(cur_char)]

        ## Append the result to Tree.edges
        Tree.edges = vcat(Tree.edges, res)
    end

    ## Sort nodes
    Tree.nodes = sort(Tree.nodes)

    return(Tree)
end

test_tree = grow_tree(text_tree)

## Get all trees
#all_trees = map(tree -> grow_tree(tree), cats_dogs_out[:,1])
