# Defining personalized Exceptions
# PFM exceptions
struct WrongPFMformat <: Exception
    msg::String
end