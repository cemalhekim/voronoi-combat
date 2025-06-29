println("\n=== GEOMETRY FUNCTION TESTS ===")

# Define points
A = Point(0.0, 0.0)
B = Point(1.0, 0.0)
C = Point(0.0, 1.0)
D = Point(0.5, 0.5)

# Operators
sum_point = A + B
println("A + B = ", sum_point)

diff_point = B - A
println("B - A = ", diff_point)

scaled_point = 2.0 * A
println("2.0 * A = ", scaled_point)

# Normal vector
n = calc_normal_vector(A, B)
println("Normal vector from A to B: ", n)

# Scalar product
sp = scalar_product(A, B)
println("Scalar product A•B = ", sp)

# d_to_a_line
d = d_to_a_line(A, B, D)
println("d_to_a_line(A,B,D) = ", d)

# counter_cw
ccw = counter_cw(A, B, C)
println("counter_cw(A,B,C) = ", ccw)

# distance
dist = distance(A, B)
println("distance(A,B) = ", dist)

# Create edges for first triangle
e1 = Edge(A, nothing, nothing, nothing, nothing)
e2 = Edge(B, nothing, nothing, nothing, nothing)
e3 = Edge(C, nothing, nothing, nothing, nothing)
e1.next = e2; e2.previous = e1
e2.next = e3; e3.previous = e2
e3.next = e1; e1.previous = e3
triangle1 = Triangle(e1)
e1.face = e2.face = e3.face = triangle1

# is_in_triangle
inside = in_triangle(D, triangle1)
outside = in_triangle(Point(1.0,1.0), triangle1)
println("D in triangle1? ", inside)
println("(1,1) in triangle1? ", outside)

# is_in_circle: We need a Triangle with A,B,C fields, so for test just reconstruct manually
using LinearAlgebra
function test_is_in_circle(A,B,C,X)
    M = [
        A.x A.y A.x^2+A.y^2 1;
        B.x B.y B.x^2+B.y^2 1;
        C.x C.y C.x^2+C.y^2 1;
        X.x X.y X.x^2+X.y^2 1
    ]
    detM = det(M)
    return detM > 1e-12
end
circ1 = test_is_in_circle(A,B,C,D)
circ2 = test_is_in_circle(A,B,C,Point(1.0,1.0))
println("D in circumcircle of ABC? ", circ1)
println("(1,1) in circumcircle of ABC? ", circ2)

# Build second triangle sharing edge B-C
E = Point(1.0,1.0)
f1 = Edge(B, nothing, nothing, nothing, nothing)
f2 = Edge(C, nothing, nothing, nothing, nothing)
f3 = Edge(E, nothing, nothing, nothing, nothing)
f1.next = f2; f2.previous = f1
f2.next = f3; f3.previous = f2
f3.next = f1; f1.previous = f3
triangle2 = Triangle(f1)
f1.face = f2.face = f3.face = triangle2

# Put triangles into a set
triangles = Set{Triangle}()
push!(triangles, triangle1)
push!(triangles, triangle2)

# Run connect_reflect!
connect_reflect!(triangles)

# Check reflect linkage
reflect_ok = (e2.reflect === f2) || (e2.reflect === f1) || (e2.reflect === f3)
println("Reflect set on shared edge between triangle1 and triangle2? ", reflect_ok)

# circumcenter test
center = circumcenter(triangle1)
println("Circumcenter of triangle1: ", center)

# Distances to all corners should be equal
rA = distance(center, A)
rB = distance(center, B)
rC = distance(center, C)

println("Distance to A: ", rA)
println("Distance to B: ", rB)
println("Distance to C: ", rC)

# Verify approximate equality
equal_radii = abs(rA - rB) < 1e-8 && abs(rA - rC) < 1e-8
println("All distances equal? ", equal_radii)

println("\n=== ALL GEOMETRY TESTS COMPLETED ===")