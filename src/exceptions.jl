# Defining personalized Exceptions
# PFM
struct WrongPFMformat <: Exception
    msg::String
end
# Tone Mapping
struct ToneMappingError <: Exception
    msg::String
end
# Run time error
struct RuntimeError <: Exception
    msg::String
end