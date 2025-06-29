include("geometry.jl") 
include("delaunay.jl")

struct VoronoiCell
    generator::Point
    polygon::Vector{Point}
end

function build_cell(delaunay::Delaunay)::Vector{VoronoiCell}
	cell_map = Dict{Point, Vector{Point}}()

	 # Her üçgenin çevre merkezini hesapla
	 for triangle in delaunay.triangles
        cc = circumcenter(triangle) 

        # Üçgenin 3 noktasına ait Voronoi hücrelerine bu noktayı ekle
        for corner_edge in [triangle.edge, triangle.edge.next, triangle.edge.next.next]
            generator = corner_edge.origin
            if haskey(cell_map, generator)
                push!(cell_map[generator], cc)
            else
                cell_map[generator] = [cc]
            end
        end
    end

    # VoronoiCell objelerine dönüştürüyorum
    voronoi_cells = VoronoiCell[]
    for (generator, polygon_points) in cell_map
        push!(voronoi_cells, VoronoiCell(generator, polygon_points))
    end

    return voronoi_cells
end

"""
# === VORONOI TEST ===
println("\n=== VORONOI TEST ===")

# Super triangle
A = Point(-1000.0, -1000.0)
B = Point(3000.0, -1000.0)
C = Point(0.0, 3000.0)

e1 = Edge(A, nothing, nothing, nothing, nothing)
e2 = Edge(B, nothing, nothing, nothing, nothing)
e3 = Edge(C, nothing, nothing, nothing, nothing)

e1.next = e2; e2.previous = e1
e2.next = e3; e3.previous = e2
e3.next = e1; e1.previous = e3

super_triangle = Triangle(e1)
e1.face = e2.face = e3.face = super_triangle

delaunay = Delaunay(Set([super_triangle]), super_triangle)

# Insert sample points
points = [Point(0.0,0.0), Point(50.0,50.0), Point(100.0,0.0)]
for p in points
    insert_point!(p, delaunay)
end

# Build Voronoi cells
cells = build_cell(delaunay)

# Print cells
for cell in cells
    println("Generator: ", cell.generator)
    println("Polygon:")
    for v in cell.polygon
        println("  ", v)
    end
end

println("=== VORONOI TEST COMPLETED ===")

"""