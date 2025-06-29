module DCEL

export Point, Face, Edge, Triangle, Delaunay

# Basic Point type
struct Point
    x::Float64
    y::Float64
end

# Abstract face type for polymorphism
abstract type Face end

# Edge type: directed half-edge
mutable struct Edge
    origin::Point
    twin::Edge
    next::Edge
    prev::Edge
    face::Face
end

# Triangle face
mutable struct Triangle <: Face
    edge::Edge  # One of the three edges; next/prev traverse the triangle
end

# Delaunay triangulation structure
mutable struct Delaunay
    triangles::Set{Triangle}
    bounding_triangle::Triangle
end

end # module