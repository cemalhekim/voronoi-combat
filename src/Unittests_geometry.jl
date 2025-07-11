using Test
include("geometry.jl")

@testset "geometry module tests" begin

        # === Punkt-Arithmetik ===
    @testset "Point arithmetic" begin
        p1 = Point(1.0, 2.0)
        p2 = Point(3.0, 4.0)
        
        @test p1 + p2 == Point(4.0, 6.0)
        @test p2 - p1 == Point(2.0, 2.0)
        @test 2.0 * p1 == Point(2.0, 4.0)
    end

        # === Punkteinfügung ===
    @testset "insert_point!" begin
        D = initialize_delaunay(10.0, 10.0)

        # Normale Einfügung
        insert_point!(Point(0.0, 0.0), D)
        @test length(D.triangles) == 3  # Anfangs 1, nach dem Einfügen sollten es 3 Dreiecke sein

    end

# === Umkreis-Test ===
    @testset "check_circumcircle" begin
        D = initialize_delaunay(10.0, 10.0)
        insert_point!(Point(0.0, 0.0), D)

        for tri in D.triangles
            for e in (tri.edge, tri.edge.next, tri.edge.prev)
                @test check_circumcircle(e, D) == false  # Super vertices should fail circumcircle check
            end
        end
    end

# === Kanten-Flipping ===
    @testset "flip! and recursive_flip!" begin
        D = initialize_delaunay(10.0, 10.0)
        insert_point!(Point(1.0, 1.0), D)
        insert_point!(Point(-1.0, -1.0), D)
        
        original_triangle_count = length(D.triangles)

# Einfügen eines Punktes, der Flips auslöst
        insert_point!(Point(0.0, 0.0), D)

        @test length(D.triangles) > original_triangle_count
    end
# === Konvertierungsfunktionen ===
    @testset "Conversion functions" begin
        v = [3.0, 4.0]
        p = to_point(v)
        @test isa(p, Point)
        @test p == Point(3.0, 4.0)

        p2f = to_point2f(p)
        @test p2f[1] ≈ 3.0
        @test p2f[2] ≈ 4.0
    end


# === Sonderfälle bei Operatorüberladung ===
    @testset "operator == with tolerance" begin
        p1 = Point(1.00000000001, 2.0)
        p2 = Point(1.00000000002, 2.0)
        @test p1 == p2  

        p3 = Point(1.1, 2.0)
        @test p1 != p3  
    end

    @testset "cross product" begin
        a = Point(1.0, 0.0)
        b = Point(0.0, 1.0)
        @test cross(a, b) == 1.0

        a2 = Point(1.0, 2.0)
        b2 = Point(3.0, 4.0)
        @test cross(a2, b2) ≈ -2.0
    end

end
