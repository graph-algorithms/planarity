import planarity


# Example of the complete graph of 5 nodes, K5
# K5 is not planar

# use text strings as labels
edgelist = [('a', 'b'), ('a', 'c'), ('a', 'd'), ('a', 'e'),
            ('b', 'c'),('b', 'd'),('b', 'e'),
            ('c', 'd'), ('c', 'e'),
            ('d', 'e')]

# write adjlist to file in "planarity adjlist" format
planarity.write(edgelist,'k5.adjlist')
# nodes are mapped to integers from 1 to n
# get mapping
print(planarity.mapping(edgelist))
