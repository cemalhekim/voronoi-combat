"""
Purpose:
The graphical interface to:

Show the diagram,

Handle clicks,

Run the game,

Display scores.
Contents:

using GLMakie or Gtk.jl (your choice)

Figure, Axis setup

Event handling: clicking to add points via insert_point!

Drawing Voronoi cells with Poly() or lines!

Highlighting the current player

Endgame detection and winner announcement
"""
function start_game()
    
    using GLMakie

    include("geometry.jl")
    include("dcel.jl")
    include("delaunay.jl")
    include("voronoi.jl")
    
    GLMakie.activate!(vsync = false, visible = true)
    
    # Create the figure
    fig = Figure(size = (800, 600))
    ax = fig[1, 1] = Axis(fig;
        title = "Voronoi Game - Gruppe 5",
        limits = ((0, 5), (-1, 1)),
        xpanlock = true,
        ypanlock = true,
        xzoomlock = true,
        yzoomlock = true
    )
    
    # Observables for player points
    pos_player_1 = Observable(Point2f[])
    pos_player_2 = Observable(Point2f[])
    
    # Scatter plots for player points
    scatter!(ax, pos_player_1; color = :blue, markersize = 10)
    scatter!(ax, pos_player_2; color = :red, markersize = 10)
    
    # Create initial bounding triangle (big enough to enclose all clicks)
    A = Point(-100, -100)
    B = Point(200, -100)
    C = Point(50, 200)
    
    # Create edges of the bounding triangle
    e1 = Kante(A, nothing, nothing, nothing, nothing)
    e2 = Kante(B, nothing, nothing, nothing, nothing)
    e3 = Kante(C, nothing, nothing, nothing, nothing)
    
    # Link next/prev
    e1.next = e2
    e2.next = e3
    e3.next = e1
    e1.prev = e3
    e2.prev = e1
    e3.prev = e2
    
    # Twins to be assigned later as needed
    # Create triangle
    bounding_triangle = Dreieck(e1)
    
    # Assign face references
    for e in [e1, e2, e3]
        e.face = bounding_triangle
    end
    
    # Initialize Delaunay triangulation
    D = Delaunay(Set([bounding_triangle]), bounding_triangle)
    
    # State tracking
    click_count = Ref(0)
    k = 3  # Number of points per player to end the game
    
    # Store site ownership
    site_owners = Dict{Point, Symbol}()
    
    # Plot handles
    voronoi_polygons = Observable(Vector{Poly}())
    
    # Main click handler
    on(ax.scene.events.mousebutton) do ev
        if ev.button == Mouse.left && ev.action == Mouse.press
            mpos = ax.scene.events.mouseposition[]
            rect = ax.scene.viewport[]
            local_px = Point2f(mpos .- rect.origin)
            data_pt = to_world(ax.scene, local_px)
            p = Point(data_pt[1], data_pt[2])
    
            # Alternate players
            current_player = isodd(click_count[]) ? :player1 : :player2
    
            # Insert into Delaunay triangulation
            insert_point!(p, D)
    
            # Update player point lists
            if current_player == :player1
                push!(pos_player_1[], Point2f(p.x, p.y))
                pos_player_1[] = pos_player_1[]
            else
                push!(pos_player_2[], Point2f(p.x, p.y))
                pos_player_2[] = pos_player_2[]
            end
    
            # Record ownership
            site_owners[p] = current_player
    
            # Increment click count
            click_count[] += 1
    
            # Recompute Voronoi diagram
            cells = voronoi(D)
    
            # Clear old polygons
            for poly in voronoi_polygons[]
                delete!(poly)
            end
            voronoi_polygons[] = Poly[]
    
            # Draw new Voronoi cells
            for (site, vertices) in cells
                # Skip circumcentres with NaN (from degenerate triangles)
                if any(v -> isnan(v.x) || isnan(v.y), vertices)
                    continue
                end
    
                # Sort vertices around site
                sorted_vertices = sort(vertices, by = v -> atan(v.y - site.y, v.x - site.x))
    
                # Convert to Point2f
                pts = [Point2f(v.x, v.y) for v in sorted_vertices]
    
                # Determine color
                color = site_owners[site] == :player1 ? RGBAf0(0,0,1,0.3) : RGBAf0(1,0,0,0.3)
    
                # Draw
                poly = poly!(ax, pts, color = color)
                push!(voronoi_polygons[], poly)
            end
    
            # Check if game ends
            if length(pos_player_1[]) >= k && length(pos_player_2[]) >= k
                area_p1 = 0.0
                area_p2 = 0.0
                for (site, vertices) in cells
                    if any(v -> isnan(v.x) || isnan(v.y), vertices)
                        continue
                    end
                    area = polygon_area(vertices)
                    if site_owners[site] == :player1
                        area_p1 += area
                    else
                        area_p2 += area
                    end
                end
    
                winner = if area_p1 > area_p2
                    "Player 1 (Blue)"
                elseif area_p2 > area_p1
                    "Player 2 (Red)"
                else
                    "Tie"
                end
    
                @info "Game Over!"
                @info "Player 1 Area = $area_p1"
                @info "Player 2 Area = $area_p2"
                @info "Winner: $winner"
            end
        end
    end
    
    display(fig)
    
end
