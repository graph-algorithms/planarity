"""Script to demo the random integer generator used by the random graph generators.
"""

#!/usr/bin/env python

from planarity import (
    gp_GetRandomNumber,
)

if __name__ == "__main__":

    print("Some pseudo-random numbers between 1 and 10:")
    print(gp_GetRandomNumber(1, 10))
    print(gp_GetRandomNumber(1, 10))
    print(gp_GetRandomNumber(1, 10))
    print(gp_GetRandomNumber(1, 10))
