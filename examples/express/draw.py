import planarity


# Example of the complete graph of 5 nodes, K5, which is not planar

# Use text strings as labels
edgelist = [
    ('Athens','Beijing'), ('Athens','Chicago'), ('Athens','Delhi'), ('Athens','Esmeraldas'),
    ('Beijing','Chicago'),('Beijing','Delhi'),('Beijing','Esmeraldas'),
    ('Chicago','Delhi'), ('Chicago','Esmeraldas'),
    ('Delhi','Esmeraldas')]

# Once can use a try-except to handle non-planar graphs.
P = planarity.PGraph(edgelist)
try:
    P.draw(outfileName='K5.png')
except Exception:
    print("The graph K5 cannot be drawn because it is non-planar.\n")

# Remove an edge so that the graph is now planar
print("Now removing an edge.\n")
edgelist.remove(('Athens', 'Beijing'))

# How to test graph is planar before attempting to draw: create two PGraph, one
# on which you will perform is_planar() test, and the second on which you invoke
# the draw routine. This avoids an exception for a non-planar graph.
P1 = planarity.PGraph(edgelist)
P2 = planarity.PGraph(edgelist)

# Produce mapping of nodes to their original labels
print("Here's a mapping of labels to indexes:")
print(P2.mapping())
print('\n')

# Make text drawing
if P1.is_planar():
    print("K5 minus an edge is planar. Here's a text drawing of it:\n")
    planar_rendition = P2.draw(output_type='text/plain', label_type='index')
    print(planar_rendition)

    # Output Matplotlib rendering
    print("Rendering image to K5-minus-edge.png")
    P2.draw(outfileName='K5-minus-edge.png',
            vertex_bordercolor='black', figsize=(4, 3))

    print("Rendering with indexes for labels to K5-minus-edge.indexes.png")
    P2 = planarity.PGraph(edgelist)
    P2.draw(outfileName='K5-minus-edge.indexes.png',
            vertex_bordercolor='black', figsize=(4, 3), label_type='index')

    # Verify fig_kwargs (#87): generate 300dpi and 600dpi variants
    print("Rendering 300dpi version to K5-minus-edge.300dpi.png")
    P2 = planarity.PGraph(edgelist)
    P2.draw(outfileName='K5-minus-edge-300dpi.png', dpi=300,
            vertex_bordercolor='black', figsize=(4, 3))

    print("Rendering 600dpi version to K5-minus-edge.600dpi.png")
    P2 = planarity.PGraph(edgelist)
    P2.draw(outfileName='K5-minus-edge-600dpi.png', dpi=600,
            vertex_bordercolor='black', figsize=(4, 3))
else:
    print("The graph cannot be drawn because it is non-planar.")
