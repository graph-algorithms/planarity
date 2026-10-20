# Planarity

The [`planarity` repository](https://github.com/graph-algorithms/planarity)
provides the source code for the [`planarity` Python
package](https://pypi.org/project/planarity/). The `planarity` package was
originally developed to provide Python and
[NetworkX](https://pypi.org/project/networkx/) developers with a Python API to
access planar graph testing, embedding, drawing, and forbidden subgraph
isolation algorithms from the [Edge Addition Planarity Suite
(EAPS)](https://github.com/graph-algorithms/edge-addition-planarity-suite).

The `planarity` repository has now been transferred to the [Github Graph
Algorithms Organization](https://github.com/graph-algorithms). The `planarity`
repository and Python package have been updated with the full set of
planarity-related algorithms from
[EAPS](https://github.com/graph-algorithms/edge-addition-planarity-suite) as
well as all public methods from its generalized graph library to enable
development of a wide range of high-performance graph algorithms and
applications.

## Example

```python
In [1]: # Example of the complete graph of 5 nodes, K5, which is not planar.

In [2]: import planarity

In [3]: edgelist = [
            ('Athens','Beijing'), ('Athens','Chicago'), ('Athens','Delhi'), ('Athens','Esmeraldas'),
            ('Beijing','Chicago'),('Beijing','Delhi'),('Beijing','Esmeraldas'),
            ('Chicago','Delhi'), ('Chicago','Esmeraldas'),
            ('Delhi','Esmeraldas')]

In [4]: print(planarity.is_planar(edgelist))
False

In [5]: # Remove an edge to make the graph planar

In [6]: edgelist.remove(('Athens', 'Beijing'))

In [7]: print(planarity.is_planar(edgelist))
True

In [8]: # Show the mapping of node indexes to their original labels

In [9]: print(planarity.mapping(edgelist))
{1: 'Athens', 2: 'Beijing', 3: 'Chicago', 4: 'Delhi', 5: 'Esmeraldas'}

In [10]: # Draw the graph as text

In [11]: print(planarity.draw(edgelist, output_type='text/plain', label_type='index'))
```
<pre>
----1----
|  |    |
|  --5--|
|   || ||
--4--| ||
 ||  | ||
 |--2--||
 |    |||
 ---3----
</pre>

```python
In [12]: planarity.draw(edgelist, outfileName='K5-minus-edge.png',
                        figsize=(4,3), dpi=100, vertex_bordercolor='black')
```
![K_5-minus-edge](https://raw.githubusercontent.com/graph-algorithms/planarity/master/examples/express/output/K5-minus-edge.png?updated=20260921
"Matplotlib render of $K_5$-minus-edge")

Note that the removed edge `('Athens', 'Beijing')` corresponds to edge `(1, 2)` using vertex indexes.

See [here](https://github.com/graph-algorithms/planarity/tree/master/examples)
for more examples.

For further details on development setup and installation, please see
[this](https://github.com/graph-algorithms/planarity/wiki/1.-Setup-Instructions)
wiki page on the [`planarity`
repository](https://github.com/graph-algorithms/planarity).

## License

Planarity (the 'planarity' Python package; the software) is released under [this
BSD-3-Clause
license](https://github.com/graph-algorithms/planarity/blob/master/LICENSE.txt).

&nbsp;&nbsp;&nbsp;&nbsp;Copyright (c) 2016-2026, Planarity Developers<br/>
&nbsp;&nbsp;&nbsp;&nbsp;John M. Boyer <john.boyer.phd@gmail.com><br/>
&nbsp;&nbsp;&nbsp;&nbsp;Wanda B. K. Boyer <wbkboyer@gmail.com><br/>
&nbsp;&nbsp;&nbsp;&nbsp;Aric Hagberg <aric.hagberg@gmail.com><br/>
&nbsp;&nbsp;&nbsp;&nbsp;All rights reserved.<br/>

&nbsp;&nbsp;&nbsp;&nbsp;Planarity includes the Edge Addition Planarity Suite, which is<br/>
&nbsp;&nbsp;&nbsp;&nbsp;Copyright (c) 1997-2026, John M. Boyer.<br/>
&nbsp;&nbsp;&nbsp;&nbsp;The BSD-3-Clause license for the Edge Additional Planarity Suite<br/>
&nbsp;&nbsp;&nbsp;&nbsp;included in Planarity appears [here](https://github.com/graph-algorithms/planarity/blob/master/planarity/c/LICENSE.TXT).
