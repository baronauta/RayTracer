# ─────────────────────────────────────────────────────────────
# ON-OFF RENDERER
# ─────────────────────────────────────────────────────────────
function OnOff_Tracer(world::World, ray::Ray, pcg::PCG; bkg_color = BLACK)
    isnothing(ray_intersection(world, ray)) ? bkg_color : WHITE
end

# ─────────────────────────────────────────────────────────────
# FLAT RENDERER
# ─────────────────────────────────────────────────────────────
function Flat_Tracer(world::World, ray::Ray, pcg::PCG; bkg_color = BLACK)
    hit_record = ray_intersection(world, ray)
    isnothing(hit_record) ? bkg_color :
    (
        get_color(hit_record.shape.material.brdf.pigm, hit_record.surface_point) +
        get_color(hit_record.shape.material.emitted_radiance, hit_record.surface_point)
    )
end

# ─────────────────────────────────────────────────────────────
# FLAT RENDERER
# ─────────────────────────────────────────────────────────────
function Path_Tracer(world::World, ray::Ray, pcg::PCG; bkg_color = BLACK, n_rays=10, max_depth = 10, russian_roulette_limit = 3)
    # truncate if the ray has propagated enaught
    if ray.depth > max_depth
        return BLACK
    end

    # compute the intersection with a world's object
    hit_record = ray_intersection(world, ray)

    if isnothing(hit_record)
        return bkg_color
    end

    # intersection point' surface coordinates
    surface_uv = hit_record.surface_point

    # the hit object material
    hit_material = hit_record.shape.material
    # the color of the object 
    hit_color = get_color(hit_material.brdf.pigm, surface_uv)
    # the color of the emitted radiance by the object
    emitted_radiance = get_color(hit_material.emitted_radiance, surface_uv)
    
    lumi = max(hit_color.r, hit_color.g, hit_color.b)
    # Russian Roulette
    if ray.depth >= russian_roulette_limit
        # if the obj is very bright is enought to consider few iterations
        # so i want a big probability to return 0
        # if the obj is not so bright i want to go further with the iterations
        # the 0.95 is for give a possibility to procede with the iteration even if is enought bright
        # the probability to iterate is x > q
        q = min(0.95, lumi)
        if random_float!(pcg) > q 
            hit_color = hit_color/(1-q)
        else
            emitted_radiance
        end
    end

    # MonteCarlo Integration
    cum_radiance = BLACK
    if lumi > 0.0
        for i in 1:n_rays
            new_ray = scatter_ray(hit_material.brdf, pcg, hit_record.ray.dir, hit_record.world_point, hit_record.normal, hit_record.ray.depth + 1)
            new_radiance = Path_Tracer(world, new_ray, pcg)
            cum_radiance = hit_color * new_radiance
        end
    end
    # imagine to obtain WHITE 10 times, i.e. cum_radiance = RGB(10,10,10) but it needs to be normalized: RGB(1,1,1)
    return emitted_radiance + cum_radiance/(n_rays)
end