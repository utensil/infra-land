# Faithful replay of ca-in-julia/index.qmd code blocks — to time the per-run render
# (GLMakie JIT + frame render/encode) with a warm precompiled depot. Mirrors Spindle's
# fresh-process `quarto render` cost (minus quarto's own overhead).
t0 = time()
using Grassmann
using GLMakie
set_theme!(theme_light())
println("[t] load Grassmann+GLMakie: ", round(time()-t0, digits=1), "s")

@basis S"∞+++"

t1 = time()
save("/tmp/sp1.png", streamplot(vectorfield(exp((π/2)*(v12+v∞3)/2), V(1,2,3),V(1,2,3)),
     -1.5..1.5,-1.5..1.5,-1.5..1.5, gridsize=(12,12)))
println("[t] first streamplot (incl JIT): ", round(time()-t1, digits=1), "s")

t2 = time()
speed = Observable{Float64}(0.0)
vf = @lift(vectorfield(exp((π/2)*(v12+$speed*v∞3)/2), V(2,3,4),V(2,3,4)))
fig, ax, pl = streamplot(vf,-1.5..1.5,-1.5..1.5,-1.5..1.5, gridsize=(12,12))
framerate = 24
timestamps = range(0, 2, step=1/framerate)
record(fig, "/tmp/streamplot.mp4", timestamps; framerate=framerate) do t
    speed[] = Float64(t/10.0)
end
println("[t] streamplot.mp4 (", length(timestamps), " frames): ", round(time()-t2, digits=1), "s")

t3 = time()
basis"2"
save("/tmp/sp2.png", streamplot(vectorfield(v1*exp((π/4)*v12/2)),-1.5..1.5,-1.5..1.5))
@basis S"+-"
save("/tmp/sp3.png", streamplot(vectorfield(v1*exp((π/4)*v12/2)),-1.5..1.5,-1.5..1.5))
@basis S"∞+++"
f(t) = (↓(exp(π*t*((3/7)*v12+v∞3))>>>↑(v1+v2+v3)))
save("/tmp/lines1.png", lines(V(2,3,4).(points(f))))
println("[t] 3 static plots: ", round(time()-t3, digits=1), "s")

t4 = time()
Base.@kwdef mutable struct Lorenz
    dt::Float64 = 0.01; σ::Float64 = 10; ρ::Float64 = 28; β::Float64 = 8/3
    x::Float64 = 1; y::Float64 = 1; z::Float64 = 1
end
function step!(l::Lorenz)
    dx = l.σ * (l.y - l.x); dy = l.x * (l.ρ - l.z) - l.y; dz = l.x * l.y - l.β * l.z
    l.x += l.dt * dx; l.y += l.dt * dy; l.z += l.dt * dz
    Point3f(l.x, l.y, l.z)
end
attractor = Lorenz()
lorenz_points = Observable(Point3f[]); colors = Observable(Int[])
set_theme!(theme_black())
fig, ax, l = lines(lorenz_points, color = colors, colormap = :inferno, transparency = true,
    axis = (; type = Axis3, protrusions = (0, 0, 0, 0), viewmode = :fit,
            limits = (-30, 30, -30, 30, 0, 50)))
record(fig, "/tmp/lorenz.mp4", 1:120) do frame
    for i in 1:50
        push!(lorenz_points[], step!(attractor)); push!(colors[], frame)
    end
    ax.azimuth[] = 1.7pi + 0.3 * sin(2pi * frame / 120)
    notify(lorenz_points); notify(colors); l.colorrange = (0, frame)
end
println("[t] lorenz.mp4 (120 frames): ", round(time()-t4, digits=1), "s")
println("[t] TOTAL render: ", round(time()-t0, digits=1), "s")
println("RENDER DONE: sp1=", filesize("/tmp/sp1.png"), " streamplot.mp4=", filesize("/tmp/streamplot.mp4"), " lorenz.mp4=", filesize("/tmp/lorenz.mp4"))
