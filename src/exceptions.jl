# Defining personalized Exceptions
struct WrongPFMformat <: Exception
    msg::String
end
# Endianness Exceptions

# Wrong Types of value
struct EndiannessWrongValueError <: Exception
    message::String
end
EndiannessWrongValueError(message) = new(message)

# Can't be zero
struct EndiannessZeroValueError <: Exception
    message::String
end
EndiannessZeroValueError(message) = new(message)

# functions
function check_endianness(value)
    try
        try
            0 > value
        catch
            throw(EndiannessWrongValueError("endianness must be an Integer or Float"))
        end
        if value == 0
            throw(
                EndiannessZeroValueError(
                    "endianness can't be 0, choose a number >0 for big endian or <0 for little endian",
                ),
            )
        end
    catch e
        println("ERROR: $(typeof(e)): $(e.message)")
        exit(1)
    end
end

struct WrongFileExtension <: Exception
    message::String
end
WrongFileExtension(message) = new(message)

function check_extension(s::String)
    try
        if !endswith(s, ".PFM")
            throw(
                WrongFileExtension(
                    "the file must be a PFM file. Please insert a valid file name",
                ),
            )
        end
    catch e
        println("ERROR: $(typeof(e)): $(e.message)")
        exit(1)
    end
end
