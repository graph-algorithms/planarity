import planarity


# Example of the complete graph of 5 nodes, K5
# K5 is not planar

# use text strings as labels
edgelist = [('a', 'b'), ('a', 'c'), ('a', 'd'), ('a', 'e'),
            ('b', 'c'),('b', 'd'),('b', 'e'),
            ('c', 'd'), ('c', 'e'),
            ('d', 'e')]
print("\n")
print("Default: ")  
planarity.write(edgelist)
print("-------------------------------------------")

print("Stdout: ")
planarity.write(edgelist, "stdout")
print("-------------------------------------------")

print("Adjacency List: ")
planarity.write(edgelist, "stdout", planarity.WRITE_ADJLIST)
print("-------------------------------------------")

print("Adjacency Matrix: ")
planarity.write(edgelist, "stdout", planarity.WRITE_ADJMATRIX)
print("-------------------------------------------")

print("Graph6: ")
planarity.write(edgelist, "stdout", planarity.WRITE_G6)
print("\n")

print("GraphML: ")
planarity.write(edgelist, "stdout", planarity.WRITE_GRAPHML)
print("\n")