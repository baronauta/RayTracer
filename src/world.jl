
#_______________________________________________________________________________________
#     LICENSE NOTICE: European Union Public Licence (EUPL) v.1.2
#     __________________________________________________________
#
#   This file is licensed under the European Union Public Licence (EUPL), version 1.2.
#
#   You are free to use, modify, and distribute this software under the conditions
#   of the EUPL v.1.2, as published by the European Commission.
#
#   Obligations include:
#     - Retaining this notice and the licence terms
#     - Providing access to the source code
#     - Distributing derivative works under the same or a compatible licence
#
#   Full licence text: see the LICENSE file or visit https://eupl.eu
#
#   Disclaimer:
#     Unless required by applicable law or agreed to in writing,
#     this software is provided "AS IS", without warranties or conditions
#     of any kind, either express or implied.
#
#_______________________________________________________________________________________

# ─────────────────────────────────────────────────────────────
# World definition and functions
# ─────────────────────────────────────────────────────────────
"""
A collection of shapes forming a 3D world.

This struct has a field that is a vector of shapes (`shapes::Vector{Shape}`). 
    
It is possible to add shapes (`add!`) 
and check for intersections with a ray (`ray_intersection`).
"""
mutable struct World
    shapes::Vector{Shape{<:AbstractFloat}}
end

"""
Construct an empty world with no shapes.

This creates a new `World` with an empty list of shapes, allowing shapes
to be added later using the `add!` function.
"""
function World()
    World(Shape[])
end

"""
Add a shape to the world.

Appends the given `shape` to the `shapes` vector in the `world`.
"""
function add!(world::World, shape::Shape)
    push!(world.shapes, shape)
end

"""
Find the closest intersection between a ray and the shapes in the world.

Iterates over all shapes in the world, checking for intersections 
with the provided `ray` using the `ray_intersection` method.

Returns the closest intersection (`HitRecord`), if any, or `nothing` if no intersection is found.
"""
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
