# ─────────────────────────────────────────────────────────────
# ON-OFF RENDERER
# ─────────────────────────────────────────────────────────────
function OnOff_Tracer(world::World, ray::Ray; bkg_color = BLACK)
    isnothing(ray_intersection(world, ray)) ? bkg_color : WHITE
end


# ─────────────────────────────────────────────────────────────
# FLAT RENDERER
# ─────────────────────────────────────────────────────────────
function Flat_Tracer(world::World, ray::Ray; bkg_color = BLACK)
    hit_record = ray_intersection(world, ray)
    isnothing(hit_record) ? bkg_color :
    (
        get_color(hit_record.shape.material.brdf.pigm, hit_record.surface_point) +
        get_color(hit_record.shape.material.emitted_radiance, hit_record.surface_point)
    )
end
