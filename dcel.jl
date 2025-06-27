"""
Purpose:
Core Doubly Connected Edge List and Delaunay triangulation data structures.
Contents:

abstract type Face end

mutable struct Kante

origin::Point

twin::Kante

next::Kante

prev::Kante

face::Face

mutable struct Dreieck <: Face

edge::Kante

mutable struct Delaunay

triangles::Set{Dreieck}

bounding_triangle::Dreieck
"""

struct Point
    x::Float64
    y::Float64
end

# Abstract Face type
abstract type Face end

# Forward declaration to allow mutual references
mutable struct Kante
    origin::Point
    twin::Kante
    next::Kante
    prev::Kante
    face::Face
end

# Triangle inheriting from Face
mutable struct Dreieck <: Face
    edge::Kante   # One of its 3 edges; others accessible via .next
end

# Container for the triangulation
mutable struct Delaunay
    triangles::Set{Dreieck}
    bounding_triangle::Dreieck
end
