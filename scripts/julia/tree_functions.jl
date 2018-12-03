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
            Tree.nodes[next_node] = Node(cur_node, [], [], nothing)
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
            Tree.nodes[cur_node] = Leaf(Tree.nodes[cur_node].parent, [string(cur_char)], nothing)
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
            Tree.nodes[next_node] = Node(cur_node, [], [], nothing)
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

            ## Collect the result as [parent_node child_node branch_length]:
            res = [string(Tree.nodes[cur_node].parent) string(cur_node) string(cur_char)]

            ## Append the result to Tree.edges
            Tree.edges = vcat(Tree.edges, res)
        end
    end

    ## Sort nodes
    Tree.nodes = sort(Tree.nodes)

    return(Tree)
end

## Print text tree
function tree_to_text(Tree)
    ## First, find the root
    root = 0
    while (typeof(Tree.nodes[root]) != Root)
        root+=1
    end

    ## Run child_to_text from root; append a final ")" to the result
    output = string(child_to_text(Tree, "", root), ")")

    return(output)
end

##
function child_to_text(Tree, output, cur_node)
    ## Start by adding "(" to the output, since we start a new child
    output = string(output, "(")
    for child in 1:length(Tree.nodes[cur_node].children)
        ##
        cur_child = Tree.nodes[cur_node].children[child]
        if typeof(Tree.nodes[cur_child]) == Leaf
            output = string(output, Tree.nodes[cur_child].values[1])
            if child < length(Tree.nodes[cur_node].children)
                output = string(output, ",")
            end
        elseif typeof(Tree.nodes[cur_child]) == Node
            output = child_to_text(Tree, output, cur_child)
            output = string(output, ")")
            if child < length(Tree.nodes[cur_node].children)
                output = string(output, ",")
            end
        end
    end
    return(output)
end
