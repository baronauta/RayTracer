# ─────────────────────────────────────────────────────────────
# World definition and functions
# ─────────────────────────────────────────────────────────────
mutable struct World
    shapes::Vector{Shape{<:AbstractFloat}}
end

function World()
    World(Shape[])
end

function add!(world::World, shape::Shape)
    push!(world.shapes, shape)
end

function ray_intersection(world::World, ray::Ray)
    closest = nothing
    for shape in world.shapes
        intersection = ray_intersection(shape, ray)
        if !isnothing(intersection) && (isnothing(closest) || intersection.t < closest.t)
            closest = intersection
        end
    end
    return closest
end