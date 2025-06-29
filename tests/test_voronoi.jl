include("/Users/cemalhekim/Documents/Workspace/voronoi-combat/voronoi.jl")

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

# Filter out bounding triangle cells
real_points = Set(points)
filtered_cells = [cell for cell in cells if cell.generator in real_points]

# Print filtered cells
for cell in filtered_cells
    println("Generator: ", cell.generator)
    println("Polygon:")
    for v in cell.polygon
        println("  ", v)
    end
end

println("=== VORONOI TEST COMPLETED ===")