import planarity


# Example of the complete graph of 5 nodes, K5
# K5 is not planar

# use text strings as labels
edgelist = [('a', 'b'), ('a', 'c'), ('a', 'd'), ('a', 'e'),
            ('b', 'c'),('b', 'd'),('b', 'e'),
            ('c', 'd'), ('c', 'e'),
            ('d', 'e')]

# remove an edge
edgelist.remove(('a','b'))
# graph is now planar
# make text drawing
print(planarity.ascii(edgelist))
