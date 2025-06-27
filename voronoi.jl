"""
Purpose:
Conversion of the Delaunay triangulation to Voronoi cells and area calculations.
Contents:

circumcenter(triangle::Dreieck)::Point

voronoi(D::Delaunay)::Dict{Point, Vector{Point}}

compute_voronoi_areas(voronoi_cells::Dict)
"""

"""
Compute the circumcentre of a triangle.
Returns a Point.
"""
function circumcenter(tri::Dreieck)::Point
    # Extract triangle corners
    A = tri.edge.origin
    B = tri.edge.next.origin
    C = tri.edge.prev.origin

    # Midpoints of edges AB and BC
    midAB = Point((A.x + B.x)/2, (A.y + B.y)/2)
    midBC = Point((B.x + C.x)/2, (B.y + C.y)/2)

    # Slopes of edges AB and BC
    dxAB = B.x - A.x
    dyAB = B.y - A.y
    dxBC = C.x - B.x
    dyBC = C.y - B.y

    # Perpendicular slopes
    if dxAB == 0
        slopeAB = 0
    else
        slopeAB = -dxAB / dyAB
    end

    if dxBC == 0
        slopeBC = 0
    else
        slopeBC = -dxBC / dyBC
    end

    # Solve for intersection (circumcentre)
    # y = slope * (x - mid.x) + mid.y
    # Solve line equations
    A1 = -slopeAB
    B1 = 1.0
    C1 = slopeAB * midAB.x - midAB.y

    A2 = -slopeBC
    B2 = 1.0
    C2 = slopeBC * midBC.x - midBC.y

    det = A1*B2 - A2*B1

    if abs(det) < 1e-10
        # Degenerate case: points are colinear
        return Point(NaN, NaN)
    end

    x = (B1*C2 - B2*C1) / det
    y = (A2*C1 - A1*C2) / det

    return Point(x, y)
end


"""
Build Voronoi cells from the Delaunay triangulation.
Returns Dict{Point, Vector{Point}} mapping each site to its cell vertices.
"""
function voronoi(D::Delaunay)::Dict{Point, Vector{Point}}
    cell_dict = Dict{Point, Vector{Point}}()

    # For each triangle, compute its circumcentre
    circumcentres = Dict{Dreieck, Point}()
    for tri in D.triangles
        c = circumcenter(tri)
        circumcentres[tri] = c
    end

    # For each site (triangle corner), collect adjacent circumcentres
    for tri in D.triangles
        e = tri.edge
        for v in [e.origin, e.next.origin, e.prev.origin]
            if !haskey(cell_dict, v)
                cell_dict[v] = Point[]
            end
            push!(cell_dict[v], circumcentres[tri])
        end
    end

    return cell_dict
end


"""
Compute polygon area for a Voronoi cell.
"""
function polygon_area(pts::Vector{Point})::Float64
    n = length(pts)
    area = 0.0
    for i in 1:n
        j = mod1(i, n) + 1
        area += pts[i].x * pts[j].y - pts[j].x * pts[i].y
    end
    return abs(area) / 2
end
