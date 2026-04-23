import planarity


# Example of the complete graph of 5 nodes, K5
# K5 is not planar

# use text strings as labels
edgelist = [('a', 'b'), ('a', 'c'), ('a', 'd'), ('a', 'e'),
            ('b', 'c'),('b', 'd'),('b', 'e'),
            ('c', 'd'), ('c', 'e'),
            ('d', 'e')]

print(planarity.is_planar(edgelist))  # False
# print forbidden Kuratowski subgraph (K5)
print(planarity.kuratowski_edges(edgelist))

# remove an edge
edgelist.remove(('a','b'))
# graph is now planar
print(planarity.is_planar(edgelist))  # True
# no forbidden subgraph, empty list returned
print(planarity.kuratowski_edges(edgelist))
