/*
Copyright (c) 1997-2026, John M. Boyer
All rights reserved.
See the LICENSE.TXT file for licensing information.
*/

#ifndef GRAPHUTILS_PRIVATE_H
#define GRAPHUTILS_PRIVATE_H

#include "extensionSystem/graphExtensions.h"
#include "extensionSystem/graphExtensions.private.h"

#include "lowLevelUtils/listcoll.h"
#include "lowLevelUtils/stack.h"

#ifdef __cplusplus
extern "C"
{
#endif

/********************************************************************
 Additional edge link accessors and manipulators
 ********************************************************************/

// Methods that enable getting the next or previous edge as if
// the adjacency list of the containing vertex were circular,
// i.e. that the first and last edge records were linked
#define gp_GetNextEdgeCircular(theGraph, e)           \
    (gp_IsEdge(theGraph, gp_GetNextEdge(theGraph, e)) \
         ? gp_GetNextEdge(theGraph, e)                \
         : gp_GetFirstEdge(theGraph, theGraph->E[gp_GetTwin(theGraph, e)].neighbor))

#define gp_GetPrevEdgeCircular(theGraph, e)           \
    (gp_IsEdge(theGraph, gp_GetPrevEdge(theGraph, e)) \
         ? gp_GetPrevEdge(theGraph, e)                \
         : gp_GetLastEdge(theGraph, theGraph->E[gp_GetTwin(theGraph, e)].neighbor))

// Methods that make the cross-link binding between a vertex and an
// edge record. The old first or last edge record should be bound to
// this new first or last edge record, e, by separate calls,
// e.g. see gp_AttachFirstEdge() and gp_AttachLastEdge()
#define gp_BindFirstEdge(theGraph, v, e)  \
    {                                     \
        gp_SetPrevEdge(theGraph, e, NIL); \
        gp_SetFirstEdge(theGraph, v, e);  \
    }

#define gp_BindLastEdge(theGraph, v, e)   \
    {                                     \
        gp_SetNextEdge(theGraph, e, NIL); \
        gp_SetLastEdge(theGraph, v, e);   \
    }

// Attaches edge e between the current binding between v and its first edge
#define gp_AttachFirstEdge(theGraph, v, e)                             \
    {                                                                  \
        if (gp_IsEdge(theGraph, gp_GetFirstEdge(theGraph, v)))         \
        {                                                              \
            gp_SetNextEdge(theGraph, e, gp_GetFirstEdge(theGraph, v)); \
            gp_SetPrevEdge(theGraph, gp_GetFirstEdge(theGraph, v), e); \
        }                                                              \
        else                                                           \
            gp_BindLastEdge(theGraph, v, e);                           \
        gp_BindFirstEdge(theGraph, v, e);                              \
    }

// Attaches edge e between the current binding between v and its last edge
#define gp_AttachLastEdge(theGraph, v, e)                             \
    {                                                                 \
        if (gp_IsEdge(theGraph, gp_GetLastEdge(theGraph, v)))         \
        {                                                             \
            gp_SetPrevEdge(theGraph, e, gp_GetLastEdge(theGraph, v)); \
            gp_SetNextEdge(theGraph, gp_GetLastEdge(theGraph, v), e); \
        }                                                             \
        else                                                          \
            gp_BindFirstEdge(theGraph, v, e);                         \
        gp_BindLastEdge(theGraph, v, e);                              \
    }

// Moves an edge e that is in the adjacency list of v to the start of the adjacency list
#define gp_MoveEdgeToFirst(theGraph, v, e)                                                      \
    if (e != gp_GetFirstEdge(theGraph, v))                                                      \
    {                                                                                           \
        /* If e is last in the adjacency list of v, then we                                     \
           detach it by adjacency list end management */                                        \
        if (e == gp_GetLastEdge(theGraph, v))                                                   \
        {                                                                                       \
            gp_SetNextEdge(theGraph, gp_GetPrevEdge(theGraph, e), NIL);                         \
            gp_SetLastEdge(theGraph, v, gp_GetPrevEdge(theGraph, e));                           \
        }                                                                                       \
        /* Otherwise, we detach e from the middle of the list */                                \
        else                                                                                    \
        {                                                                                       \
            gp_SetNextEdge(theGraph, gp_GetPrevEdge(theGraph, e), gp_GetNextEdge(theGraph, e)); \
            gp_SetPrevEdge(theGraph, gp_GetNextEdge(theGraph, e), gp_GetPrevEdge(theGraph, e)); \
        }                                                                                       \
                                                                                                \
        /* Now add e as the new first edge of v.                                                \
           Note that the adjacency list is non-empty at this time */                            \
        gp_SetNextEdge(theGraph, e, gp_GetFirstEdge(theGraph, v));                              \
        gp_SetPrevEdge(theGraph, gp_GetFirstEdge(theGraph, v), e);                              \
        gp_BindFirstEdge(theGraph, v, e);                                                       \
    }

// Moves an edge e that is in the adjacency list of v to the end of the adjacency list
#define gp_MoveEdgeToLast(theGraph, v, e)                                                       \
    if (e != gp_GetLastEdge(theGraph, v))                                                       \
    {                                                                                           \
        /* If e is first in the adjacency list of vertex v, then we                             \
           detach it by adjacency list beginning management */                                  \
        if (e == gp_GetFirstEdge(theGraph, v))                                                  \
        {                                                                                       \
            gp_SetPrevEdge(theGraph, gp_GetNextEdge(theGraph, e), NIL);                         \
            gp_SetFirstEdge(theGraph, v, gp_GetNextEdge(theGraph, e));                          \
        }                                                                                       \
        /* Otherwise, we detach e from the middle of the list */                                \
        else                                                                                    \
        {                                                                                       \
            gp_SetNextEdge(theGraph, gp_GetPrevEdge(theGraph, e), gp_GetNextEdge(theGraph, e)); \
            gp_SetPrevEdge(theGraph, gp_GetNextEdge(theGraph, e), gp_GetPrevEdge(theGraph, e)); \
        }                                                                                       \
                                                                                                \
        /* Now we add e as the new last edge of v.                                              \
           Note that the adjacency list is non-empty at this time */                            \
        gp_SetPrevEdge(theGraph, e, gp_GetLastEdge(theGraph, v));                               \
        gp_SetNextEdge(theGraph, gp_GetLastEdge(theGraph, v), e);                               \
        gp_BindLastEdge(theGraph, v, e);                                                        \
    }

#ifdef __cplusplus
}
#endif

#endif /* GRAPHUTILS_PRIVATE_H */
