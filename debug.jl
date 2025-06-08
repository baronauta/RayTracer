using Revise
using Pkg
Pkg.activate(".")

using RayTracer

stream = IOBuffer(
    """
    camera(identity, rotation_z(30) * translation([-4, 0, 1]), 1.0, 1.0)
    """
)

instream = RayTracer.InputStream(stream, "test")

try
    _ = RayTracer.parse_scene(instream)
catch e
    if isa(e, GrammarError)
        print(e)
    else
        rethrow(e)  # Re-throw unexpected exceptions
    end
end
