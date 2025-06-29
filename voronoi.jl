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
        sort!(polygon_points, by = p -> atan(p.y - generator.y, p.x - generator.x))
        push!(voronoi_cells, VoronoiCell(generator, polygon_points))
    end

    return voronoi_cells
end