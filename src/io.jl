
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


"""
    read_ldr_image(filename::String)

Read a ldr Image (.png, .jpg, ...) from a file and returns the corresponding HdrImage.
"""
function read_ldr_image(filename::String)
    img_ldr = Images.load(filename)
    img_float = convert.(ColorTypes.RGB{Float32}, img_ldr)
    img_linear = map(c -> RGB(c.r^(2.2), c.g^(2.2), c.b^(2.2)), img_float) # gamma expansion
    height, width = size(img_ldr)
    img = HdrImage(width, height, img_linear)
    return img
end

"""
    ldr_to_pfm_image(filename::String, output_name::String)

Read a ldr Image (.png, .jpg, ...) from a file and save the corresponding HdrImage (.pfm) file.
"""
function ldr_to_pfm_image(filename::String, output_name::String)
    img = read_ldr_image(filename)
    write(output_name, img)
end
