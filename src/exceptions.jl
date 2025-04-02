"""
    struct WrongPFMformat <: Exception
Custom exception for handling incorrect PFM file format errors.

# Fields
- `msg::String`: Error message describing the issue.
"""
struct WrongPFMformat <: Exception
    msg::String
end

"""
    struct ToneMappingError <: Exception
Custom exception for errors encountered during tone mapping operations.

# Fields
- `msg::String`: Error message describing the issue.
"""
struct ToneMappingError <: Exception
    msg::String
end

"""
    struct RuntimeError <: Exception
Custom exception for errors encountered while running RayTracer, after being precompiled.

# Fields
- `msg::String`: Error message describing the issue.
"""
struct RuntimeError <: Exception
    msg::String
end

"""
    struct GeometryError <: Exception
Custom exception for errors encountered during geometry operations (ex: comparing Vector and Point).

# Fields
- `msg::String`: Error message describing the issue.
"""
struct GeometryError <: Exception
    msg::String
end
