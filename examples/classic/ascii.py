import planarity


# Example of the complete graph of 5 nodes, K5, which is not planar

# Use text strings as labels
edgelist = [('a', 'b'), ('a', 'c'), ('a', 'd'), ('a', 'e'),
            ('b', 'c'),('b', 'd'),('b', 'e'),
            ('c', 'd'), ('c', 'e'),
            ('d', 'e')]

# Once can use a try-except-else to handle non-planar graphs.
P = planarity.PGraph(edgelist)
try:
    planar_rendition = P.ascii()
except Exception:
    print("The graph cannot be drawn because it is non-planar.\n")
else:
    print(planar_rendition)

# Remove an edge so that the graph is now planar
edgelist.remove(('a','b'))

# The basic workflow for text drawing of a planar graph.
P = planarity.PGraph(edgelist)
print(P.mapping())
planar_rendition = P.ascii()
print(planar_rendition)

# How to test graph is planar before attempting to draw: create two PGraph, one
# on which you will perform is_planar() test, and the second on which you invoke
# the draw routine. This avoids an exception for a non-planar graph.
P1 = planarity.PGraph(edgelist)
P2 = planarity.PGraph(edgelist)

# Produce mapping of nodes to their original labels
print(P2.mapping())

# Make text drawing
if P1.is_planar():
    planar_rendition = P2.ascii()
    print(planar_rendition)
else:
    print("The graph cannot be drawn because it is non-planar.")
