include("/Users/cemalhekim/Documents/Workspace/voronoi-combat/delaunay.jl")

println("\n=== DELAUNAY FULL FUNCTION TEST ===")

# Basit dört nokta
A = Point(0.0, 0.0)
B = Point(1.0, 0.0)
C = Point(0.0, 1.0)
D = Point(1.0, 1.0)

# İlk üçgen ABC
e1 = Edge(A, nothing, nothing, nothing, nothing)
e2 = Edge(B, nothing, nothing, nothing, nothing)
e3 = Edge(C, nothing, nothing, nothing, nothing)
e1.next = e2; e2.previous = e1
e2.next = e3; e3.previous = e2
e3.next = e1; e1.previous = e3
tri1 = Triangle(e1)
e1.face = e2.face = e3.face = tri1

# İkinci üçgen B-C-D (BC ortak kenar)
f1 = Edge(B, nothing, nothing, nothing, nothing)
f2 = Edge(D, nothing, nothing, nothing, nothing)
f3 = Edge(C, nothing, nothing, nothing, nothing)
f1.next = f2; f2.previous = f1
f2.next = f3; f3.previous = f2
f3.next = f1; f1.previous = f3
tri2 = Triangle(f1)
f1.face = f2.face = f3.face = tri2

# Triangle kümesi ve Delaunay yapısı
triangles = Set{Triangle}()
push!(triangles, tri1)
push!(triangles, tri2)
delaunay = Delaunay(triangles, tri1)

# Reflect bağlantılarını kur
connect_reflect!(delaunay.triangles)
println("Reflect connections set.")

# B noktasının biraz üstüne nokta ekleyelim ki flip kesin olsun
P = Point(0.3, 0.3)
println("Inserting point ", P)

# insert_point! hepsini tetikleyecek
insert_point!(P, delaunay)

println("After insertion, triangle count: ", length(delaunay.triangles))

# Yeni üçgenleri yazdır
for t in delaunay.triangles
    p1 = t.edge.origin
    p2 = t.edge.next.origin
    p3 = t.edge.next.next.origin
    println("Triangle: ", p1, " - ", p2, " - ", p3)
end

println("=== DELAUNAY FULL FUNCTION TEST COMPLETED ===")