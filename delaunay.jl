include("geometry.jl")

using LinearAlgebra

function insert_point!(p::Point, delaunay::Delaunay)
	# 1) Noktanın hangi üçgenin içinde olduğunu bul
	triangle = find_triangle(p, delaunay)

	# 2) O üçgenin köşelerini kaydet
	e1 = triangle.edge
	e2 = e1.next
	e3 = e2.next
	a, b, c = e1.origin, e2.origin, e3.origin

	# 3) Eski üçgeni sil
	delete!(delaunay.triangles, triangle)

	# 4) Yeni 3 üçgen oluştur
	# 1. üçgen: a, b, p
	new_e1ab = Edge(a, nothing, nothing, nothing, nothing)
	new_e2ab = Edge(b, nothing, nothing, nothing, nothing)
	new_e3ab = Edge(p, nothing, nothing, nothing, nothing)
	new_e1ab.next = new_e2ab ; new_e2ab.previous = new_e1ab
	new_e2ab.next = new_e3ab ; new_e3ab.previous = new_e2ab
	new_e3ab.next = new_e1ab ; new_e1ab.previous = new_e3ab
	new_triangle_ab = Triangle(new_e1ab)
	new_e1ab.face = new_triangle_ab ; new_e2ab.face = new_triangle_ab ; new_e3ab.face = new_triangle_ab 
	# 2. üçgen: b, c, p
	new_e1bc = Edge(b, nothing, nothing, nothing, nothing)
	new_e2bc = Edge(c, nothing, nothing, nothing, nothing)
	new_e3bc = Edge(p, nothing, nothing, nothing, nothing)
	new_e1bc.next = new_e2bc ; new_e2bc.previous = new_e1bc
	new_e2bc.next = new_e3bc ; new_e3bc.previous = new_e2bc
	new_e3bc.next = new_e1bc ; new_e1bc.previous = new_e3bc
	new_triangle_bc = Triangle(new_e1bc) ; 
	new_e1bc.face = new_triangle_bc ; new_e2bc.face = new_triangle_bc ; new_e3bc.face = new_triangle_bc
	# 3. üçgen: c, a, p
	new_e1ca = Edge(c, nothing, nothing, nothing, nothing)
	new_e2ca = Edge(a, nothing, nothing, nothing, nothing)
	new_e3ca = Edge(p, nothing, nothing, nothing, nothing)
	new_e1ca.next = new_e2ca ; new_e2ca.previous = new_e1ca
	new_e2ca.next = new_e3ca ; new_e3ca.previous = new_e2ca
	new_e3ca.next = new_e1ca ; new_e1ca.previous = new_e3ca
	new_triangle_ca = Triangle(new_e1ca) ;
	new_e1ca.face = new_triangle_ca ; new_e2ca.face = new_triangle_ca ; new_e3ca.face = new_triangle_ca

	# 5) Yeni üçgeni ekle
	push!(delaunay.triangles, new_triangle_ab, new_triangle_bc, new_triangle_ca)
	
	# 6) Yeni üçgenlerin kenarlarını birbirine bağla
	connect_reflect!(delaunay.triangles)

	recursive_flip!(new_e1ab, delaunay)
	recursive_flip!(new_e1bc, delaunay)
	recursive_flip!(new_e1ca, delaunay)

end

function check_umkreis(e::Edge)
    if e.reflect === nothing
        return false
    end

    triangle = e.face::Triangle  # e kenarı üçgeni tanımlar
    center = circumcenter(triangle)
    radius = distance(center, e.origin)

    d_ref = e.reflect.origin
    return distance(center, d_ref) < radius
end

function flip!(e::Edge, delaunay::Delaunay)
	# Kenarın yansıma kenarını al
	e_reflect = e.reflect
	if e_reflect === nothing
		error("Kenarin yansima kenari yok.")
	end 

	#Karşı köşeleri bulalım.
	a = e.next.next.origin
	d = e_reflect.next.next.origin

	# Eskiyi silelim
	delete!(delaunay.triangles, e.face)
	delete!(delaunay.triangles, e_reflect.face)

	# Yeni kenarları oluşturalım (a-d ortak)
	e1 = Edge(a, nothing, nothing, nothing, nothing)
	e2 = Edge(e.origin, nothing, nothing, nothing, nothing)
	e3 = Edge(d, nothing, nothing, nothing, nothing)

	e4 = Edge(d, nothing, nothing, nothing, nothing)
	e5 = Edge(e.next.origin, nothing, nothing, nothing, nothing)
	e6 = Edge(a, nothing, nothing, nothing, nothing)

	# Yeni bağlantıları oluşturalım
	e1.next = e2 ; e2.previous = e1
	e2.next = e3 ; e3.previous = e2
	e3.next = e1 ; e1.previous = e3	
	new_triangle1 = Triangle(e1)
	e1.face = e2.face = e3.face = new_triangle1

	e4.next = e5 ; e5.previous = e4
	e5.next = e6 ; e6.previous = e5
	e6.next = e4 ; e4.previous = e6
	new_triangle2 = Triangle(e4)
	e4.face = e5.face = e6.face = new_triangle2

	# Yeni üçgenleri ekleyelim
	push!(delaunay.triangles, new_triangle1, new_triangle2)

	# reflect kenarlarını güncelleyelim
	connect_reflect!(delaunay.triangles)

end

function recursive_flip!(e::Edge, delaunay::Delaunay)

	if e.reflect === nothing
		return
	end

	if !check_umkreis(e)
		return
	end

	flip!(e, delaunay)

	#flip sonrası teni kenarı al
	t1 = e.face
	t2 = e.reflect.face

	e1 = t1.edge
	e2 = e1.next
	e3 = e2.next
	
	f1 = t2.edge
	f2 = f1.next
	f3 = f2.next	

	for ed in [e1, e2, e3, f1, f2, f3]
		recursive_flip!(ed, delaunay)
	end

end


"""
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
"""