abstract type Shape{T<:AbstractFloat} end

struct HitRecord{T<:AbstractFloat}
    world_point::Point{T}
    normal::Normal{T}
    surface_point::Vec2D{T}
    t::T
    ray::Ray{T}
end