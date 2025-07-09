include("geometry.jl")  # Datei einbinden

using GLMakie
using .geometry


#Vergleicht zwei Psunkte
function points_equal(a::Point2f, b::Point2f; atol=1e-5)
	isapprox(a[1], b[1]; atol=atol) && isapprox(a[2], b[2]; atol=atol)
end

#Prüft, ob ein Punkt schon an dieser Stelle vorhanden ist.
function point_exists(points, p; atol=1e-5)
	any(pt -> points_equal(pt, p; atol=atol), points)
end

function get_delaunay_triangulation(V::Vector{T}) where T<:geometry.Face
	dreiecke=Vector{Vector{Point2f}}()
	
	for bill in V
		A=bill.edge.origin
		B=bill.edge.next.origin
		C=bill.edge.next.next.origin
		Punkte=[Point2f(A.x, A.y), Point2f(B.x, B.y), Point2f(C.x, C.y), Point2f(A.x, A.y)]
		
		push!(dreiecke, Punkte)
	end
	
	return dreiecke
end

function clip_by_bisector(poly::Vector{Point2f}, p1::Point2f, p2::Point2f)
    a = p2[1] - p1[1]
    b = p2[2] - p1[2]
    c = (p2[1]^2 - p1[1]^2 + p2[2]^2 - p1[2]^2) / 2.0
    newpoly = Point2f[]
    S = poly[end]
    for E in poly
        val_s = a*S[1] + b*S[2] - c
        val_e = a*E[1] + b*E[2] - c
        s_in = val_s <= 0
        e_in = val_e <= 0
        if s_in != e_in
            t = val_s / (val_s - val_e)
            inter = Point2f(S[1] + t*(E[1]-S[1]), S[2] + t*(E[2]-S[2]))
            push!(newpoly, inter)
        end
        if e_in
            push!(newpoly, E)
        end
        S = E
    end
    return newpoly
end

function calculate_clipped_cell(P::Point2f, all_sites::Vector{Point2f}, bounds)
    xmin, ymin, xmax, ymax = bounds
    cell = [Point2f(xmin, ymin), Point2f(xmax, ymin), Point2f(xmax, ymax), Point2f(xmin, ymax)]
    for Q in all_sites
        if Q != P
            cell = clip_by_bisector(cell, P, Q)
        end
    end
    return cell
	@info "clipping for $(P), other_sites: $(length(all_sites))"
end

function polygon_area(poly::Vector{Point2f})
    n = length(poly)
    if n < 3
        return 0.0
    end
    area = 0.0
    for i in 1:n
        j = i == n ? 1 : i + 1
        area += poly[i][1] * poly[j][2] - poly[j][1] * poly[i][2]
    end
    return abs(area) / 2.0
end

function start_game()
	GLMakie.activate!(vsync=false, visible=true)
	
	xmin=-1.
	xmax=1.
	ymin=-1.
	ymax=1.
	
	#Erstellen der Figure/des Fensters
	fig=Figure(size=(800, 800))
	ax=fig[1, 1]=Axis(fig;
						title="Gruppe 5",
						limits=((xmin, xmax), (ymin, ymax)),
						#Etwas größer, damit man das äußere Dreieck und den Spielfeldrand sieht
						
						xpanlock = true,
						ypanlock = true,
						xzoomlock = true,
						yzoomlock = true,
						xrectzoom = false,
						yrectzoom = false,
						aspect = DataAspect()
					)
    
	#leere Listen von "Observable" Punkten
	pos_player_1=Vector{Point2f}()	  #für Player 1
	pos_player_2=Vector{Point2f}()	  #für Player 2
	
	#Liste der Dreiecke zum Plotten
	dreiecke=Vector{Vector{Point2f}}()
	
	#Der Spielfeldrand
	Spielfeld=[Point2f(xmin, ymin), Point2f(xmax, ymin), Point2f(xmax, ymax), Point2f(xmin, ymax), Point2f(xmin, ymin) ]
	
	#Das äußere Dreieck bzw. Delaunay-Struktur initialisieren
	delaunay_ = geometry.initialize_delaunay(xmax - xmin, ymax - ymin)
	
	#die dreiecke in delaunay_ werden in die Liste der Dreiecke zum plotten gespeichert
	#Weiß nicht, ob man delaunay_ noch brauch...
	#jedenfalls kann ich delaunay_ nicht plotten
	dreiecke=get_delaunay_triangulation(delaunay_.triangles)
	
	#Eine Liste an Plots
	current_plot = Ref(Vector{Makie.AbstractPlot}())
	
	#Der Spielfeldrand und die Ddreiecke werden zum erstenmal in die Liste der Plots gespeichert
	push!(current_plot[], lines!(ax, Spielfeld; color=:black, linewidth=1))
	push!(current_plot[], lines!(ax, dreiecke[1]; color=:green, linewidth=1))
	
	click_count=0	  #Anzahl an Klicks
	
	#Mausklick-Event
	on(ax.scene.events.mousebutton) do ev
		if ev.button==Mouse.left && ev.action==Mouse.press
			mpos=ax.scene.events.mouseposition[]
			rect=ax.scene.viewport[]
			local_px=Point2f(mpos .- rect.origin)
			data_pt=to_world(ax.scene, local_px)
			
			#Prüft erst, ob der Klick im Spielfeld ist und ob an der Stelle schon ein Punkt ist.
			if xmin<=data_pt[1]<=xmax && ymin<=data_pt[2]<=ymax && !point_exists(pos_player_1, Point2f(data_pt)) && !point_exists(pos_player_2, Point2f(data_pt))
				
				#erzeugt aus den Mausklick-Koordinaten unseren Punkt-Datentyp "Dot" ->siehe geometry.jl
				p = geometry.to_point(data_pt)
				
				#fügt einen Punkt in die Delaunay-Triangulierung ein
				insert_point!(p, delaunay_)
				
				#Speichert die Delaunay-Dreiecke in der Liste an Dreiecken,
				#damit die geplottet werden können
				dreiecke=get_delaunay_triangulation(delaunay_.triangles)
				
				#Anfügen an die Liste der Punkte
				if isodd(click_count+1)
					#... von Player 1
					push!(pos_player_1, Point2f(data_pt))
				else
					#... von Player 2
					push!(pos_player_2, Point2f(data_pt))
				end
				
				#Ein Klick mehr muss mitgezält werden
				click_count+=1
				@info "click_count=$(click_count[])"
				@info "pos=$(data_pt[1]) $(data_pt[2])"
			end
			
			if current_plot[] !== nothing
				len=length(current_plot[])
				
				#löscht alle Plots aus dem Fenster
				for i in 1:len
                    delete!(ax.scene, current_plot[][i])  # scatter
                end
                
                #leert die Liste an Plots
                empty!(current_plot[])
            end
			
			#Fügt die Listen an Punkten der Spieler in die Liste an Plots erneut an
			push!(current_plot[], scatter!(ax, pos_player_1; color=:red, markersize=10))
			push!(current_plot[], scatter!(ax, pos_player_2; color=:blue, markersize=10))
			
			len2=length(dreiecke)
			
			#Plottet jedes Dreieck neu
			for i in 1:len2
				push!(current_plot[], lines!(ax, dreiecke[i]; color=:green, linewidth=1))
			end
			
			#Plottet das Spielfeld neu
			push!(current_plot[], lines!(ax, Spielfeld; color=:black, linewidth=1))

			# Voronoi hücrelerini çiz
			all_sites = vcat(pos_player_1, pos_player_2)
			bounds = (xmin, ymin, xmax, ymax)

			for P in pos_player_1
				clipped = calculate_clipped_cell(P, all_sites, bounds)
				push!(current_plot[], poly!(ax, clipped; color=:red, transparency=true, alpha=0.3))
			end
			for P in pos_player_2
				clipped = calculate_clipped_cell(P, all_sites, bounds)
				push!(current_plot[], poly!(ax, clipped; color=:blue, transparency=true, alpha=0.3))
			end

			# (İsteğe Bağlı) Alanları yazdır
			if length(all_sites) > 1
				area1 = sum(p -> begin
					clipped = calculate_clipped_cell(p, all_sites, bounds)
					isempty(clipped) ? 0.0 : polygon_area(clipped)
				end, pos_player_1)

				area2 = sum(p -> begin
					clipped = calculate_clipped_cell(p, all_sites, bounds)
					isempty(clipped) ? 0.0 : polygon_area(clipped)
				end, pos_player_2)
			else
				area1 = 4.0
				area2 = 0.0
			end
			@info "Alanlar -> Oyuncu 1: $(round(area1, digits=2)), Oyuncu 2: $(round(area2, digits=2))"
		end
	end
	
	#Darstellen des Fensters
	display(fig)
	
	#Wartet bis das Fenster geschlossen wird
	wait(fig.scene)
end

start_game()
