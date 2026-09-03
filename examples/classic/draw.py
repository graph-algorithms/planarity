import planarity


# Example of the complete graph of 5 nodes, K5, which is not planar

# Use text strings as labels
edgelist = [('a', 'b'), ('a', 'c'), ('a', 'd'), ('a', 'e'),
            ('b', 'c'),('b', 'd'),('b', 'e'),
            ('c', 'd'), ('c', 'e'),
            ('d', 'e')]

# Remove an edge so that the graph is now planar
edgelist.remove(('a','b'))

# Create an instance of PGraph from edgelist to embed and render planar drawing
P = planarity.PGraph(edgelist)

# Produce mapping of nodes to their original labels
print(P.mapping())

# Make text drawing
planar_rendition = P.ascii()
print(planar_rendition)

# Output Matplotlib rendering
P.draw(outfileName='K5-minus-edge.png')
