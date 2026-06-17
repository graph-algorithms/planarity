# Planarity

The [`planarity` repository](https://github.com/graph-algorithms/planarity) provides the source code for the [`planarity` Python package](https://pypi.org/project/planarity/). The `planarity` package was originally developed to provide Python and [NetworkX](https://pypi.org/project/networkx/) developers with a Python API to access planar graph testing, embedding, drawing, and forbidden subgraph isolation algorithms from the [Edge Addition Planarity Suite (EAPS)](https://github.com/graph-algorithms/edge-addition-planarity-suite). 

The `planarity` repository has now been transferred to the [Github Graph Algorithms Organization](https://github.com/graph-algorithms). The `planarity` repository and Python package have been updated with the full set of  planarity-related algorithms from [EAPS](https://github.com/graph-algorithms/edge-addition-planarity-suite) as well as all public methods from its generalized graph library to enable development of a wide range of high-performance graph algorithms and applications.

## Example

```python
In [1]: # Example of the complete graph of 5 nodes, K5

In [2]: # K5 is not planar

In [3]: import planarity

In [4]: edgelist = [('a', 'b'), ('a', 'c'), ('a', 'd'), ('a', 'e'),
   ...:             ('b', 'c'),('b', 'd'),('b', 'e'),
   ...:             ('c', 'd'), ('c', 'e'),
   ...:             ('d', 'e')]

In [5]: print(planarity.is_planar(edgelist))
False

In [6]: # remove an edge to make the graph planar

In [7]: edgelist.remove(('a','b'))

In [8]: print(planarity.is_planar(edgelist))
True

In [9]: # make an ascii text drawing

In [10]: print(planarity.ascii(edgelist))
```

<pre>
----1----
| | |   |
| | -3--|
| |  ||||
| -2--|||
|  |  |||
---4---||
 |     ||
 ---5----
</pre>

```python
In [11]: # Shows correspondence between vertex labels and indices

In [12]: print(planarity.mapping(edgelist))
{1: 'd', 2: 'c', 3: 'e', 4: 'a', 5: 'b'}
```

See [here](https://github.com/graph-algorithms/planarity/tree/master/examples) for more examples.

## License

Planarity (the 'planarity' Python package; the software) is released
under [this BSD-3-Clause license](https://github.com/graph-algorithms/planarity/blob/master/LICENSE.txt).

   Copyright (c) 2016-2026, Planarity Developers<br/>
   John M. Boyer <john.boyer.phd@gmail.com><br/>
   Wanda B. K. Boyer <wbkboyer@gmail.com><br/>
   Aric Hagberg <aric.hagberg@gmail.com><br/>
   All rights reserved.<br/>

   Planarity includes the Edge Addition Planarity Suite, which is<br/> 
   Copyright (c) 1997-2026, John M. Boyer.<br/>
   The BSD-3-Clause license for the Edge Additional Planarity Suite
   included in Planarity appears [here](https://github.com/graph-algorithms/planarity/blob/master/planarity/c/LICENSE.TXT).
