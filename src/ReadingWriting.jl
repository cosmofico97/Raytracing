# -*- encoding: utf-8 -*-
#
# The MIT License (MIT)
#
# Copyright © 2021 Matteo Foglieni and Riccardo Gervasoni
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of
# the Software. THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT
# SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

##########################################################################################92

"""
    valid_coordinates(hdr::HDRimage, x::Int, y::Int) -> Bool

Return `True` if ``(x, y)`` are coordinates within the 2D matrix (in [`HDRimage`](@ref))
"""
valid_coordinates(hdr::HDRimage, x::Int, y::Int) = x>=0 && y>=0 && x<hdr.width && y<hdr.height

##########################################################################################92

"""
    pixel_offset(hdr::HDRimage, x::Int, y::Int) -> Int64

Return the position in the 1D array of the specified pixel
"""
pixel_offset(hdr::HDRimage, x::Int, y::Int) = (@assert valid_coordinates(hdr, x, y); y*hdr.width + (x+1) )

##########################################################################################92

"""
    get_pixel(hdr::HDRimage, x::Int, y::Int) -> RBG{Float32}

Return the `Color` value for a pixel in the image
The pixel at the top-left corner has coordinates (0, 0).
"""
get_pixel(hdr::HDRimage, x::Int, y::Int) = hdr.rgb_m[pixel_offset(hdr, x, y)]

##########################################################################################92

"""
    set_pixel(hdr::HDRimage, x::Int, y::Int, c::RGB{T})

Set the new color for a pixel in the image
The pixel at the top-left corner has coordinates (0, 0).
"""
set_pixel(hdr::HDRimage, x::Int, y::Int, c::RGB{T}) where {T} = (hdr.rgb_m[pixel_offset(hdr, x,y)] = c; nothing)

##########################################################################################92

struct InvalidPfmFileFormat <: Exception
    var::String
end #InvalidPfmFileFormat

##########################################################################################92

"""
    write(io::IO, img::HDRimage)

Write the image in a PFM file
The `stream` parameter must be a I/O stream. The parameter `endianness` specifies the
byte endianness to be used in the file.
"""
function write(io::IO, img::HDRimage)
    endianness=-1.0
    w = img.width
    h = img.height
    # The PFM header, as a Julia string (UTF-8)
    header = "PF\n$w $h\n$endianness\n"

    # Convert the header into a sequence of bytes
    bytebuf = transcode(UInt8, header) # transcode writes a "raw" sequence of bytes (8bit)

    # Write on io the header in binary code
    write(io, reinterpret(UInt8, bytebuf))  # reinterpret  writes a "raw" sequence of bytes (8bit)

    # Write the image (bottom-to-up, left-to-right)
    for y in h-1:-1:0, x in 0:w-1                   # !!! Julia conta sempre partendo da 1; prende gli estremi
        color = get_pixel(img, x, y)
        write(io, reinterpret(UInt8,  [color.r]))   #!!! reinterpret(UInt8, [...]) bisogna specificare il tipo
        write(io, reinterpret(UInt8,  [color.g]))   # e passargli il vettore [] da cambiare, anche se contiene
        write(io, reinterpret(UInt8,  [color.b]))   # un solo elemento
    end

end # write(::IO, ::HDRimage)

##########################################################################################92

"""
    parse_img_size(line::String) -> (Int64, Int64)

Can interpret the size of an image from a PFM file. Needs a `String`,
obtained from [`read_line`](@ref)(::IO)
"""
function parse_img_size(line::String)
    elements = split(line, " ")
    length(elements) == 2 || throw(InvalidPfmFileFormat("invalid image size specification
                                                        : $(length(elements)) instead of 2"))

    try
        width, height = convert.(Int, parse.(Float64, elements))
        (width > 0 && height > 0) || throw(ErrorException)
        return width, height
    catch e
        isa(e, InexactError) || throw(InvalidPfmFileFormat("cannot convert width/height
                                                            $(elements) to Tuple{Int, Int}")
        )
        isa(e, ErrorException) || throw(InvalidPfmFileFormat("width/height cannot be negative,
                                                              but in $(elements) at least one
                                                              of them is <0.")
        )
    end

end # parse_img_size

##########################################################################################92

"""
    parse_endianness(ess::String) -> Float64

Can understand the endianness of a file; needs a `String`, obtained from [`read_line`](@ref)(`::IO`).
Returns error if the number is different from ±1.0.
"""
function parse_endianness(ess::String)
    try
        val = parse(Float64, ess)
        (val == 1.0 || val == -1.0) || throw(InvalidPfmFileFormat("invalid endianness in PFM
                                                                   file: $(parse(Float64, ess))
                                                                   instead of +1.0 or -1.0.\n")
        )
        return val
    catch e
        throw(InvalidPfmFileFormat("missing endianness in PFM file: $ess instead of ±1.0"))
    end
end # parse_endianness

##########################################################################################92

"""
    read_float(io::IO, ess::Float64) -> Float32

Can interpret numbers from a string; needs as input a `IO` and the endianness (as ±1.0).
Reads numbers as `Float32`; controls if there are enough bits in order to form a `Float32`,
otherwise returns an error.
"""
function read_float(io::IO, ess::Float64)
    # controllo che in ingresso abbia una stringa che sia cnovertibile in Float32
    ess == 1.0 || ess == -1.0 || throw(InvalidPfmFileFormat("endianness $ess not acceptable."))
    try
        value = read(io, Float32)   # con Float32 leggo già i 4 byte del colore
        ess == 1.0 ? value = ntoh(value) : value = ltoh(value) # convert machine's endianness
        return value
    catch e
        throw(InvalidPfmFileFormat("color is not Float32, it's a $(typeof(io))"))  # ess → io
    end
end # read_float

##########################################################################################92

"""
    read_line(io::IO) -> String

Reads aline from a file, given as a `IO`. Can understand when the file is ended and when
a new line begins.
"""
function read_line(io::IO)
    result = b""
    while eof(io) == false
        cur_byte = read(io, UInt8)
        if [cur_byte] in [b"", b"\n"]
            return String(result)
        end
        result = vcat(result, cur_byte)  
    end
    return String(result)
end # read_line

##########################################################################################92

"""
    read(io::IO, ::Type{HDRimage}) -> HDRimage

Read a PFM image from a stream
Return a [`HDRimage`](@ref) object containing the image. If an error occurs, raise a
``InvalidPfmFileFormat`` exception.

See also: [`read_line`](@ref)(`::IO`), [`parse_image_size`](@ref)(`::String`),
[`parse_endianness`](@ref)(`::String`), [`read_float`](@ref)(`::IO, `::Float64`)
"""
function read(io::IO, ::Type{HDRimage})
    magic = read_line(io)
    # lettura numero magico
    magic == "PF" || throw(InvalidPfmFileFormat("invalid magic number in PFM file: 
                                                 $(magic) instead of 'PF'.\n")
    )
    
    # lettura dimensioni immagine
    img_size = read_line(io)
    typeof(parse_img_size(img_size)) == Tuple{Int,Int} || throw(InvalidPfmFileFormat("invalid img size in PFM file: $(parse_img_size(img_size)) is $( typeof(parse_img_size(img_size)) ) instead of 'Tuple{UInt,UInt}'.\n"))
    (width, height) = parse_img_size(img_size)
    
    #lettura endianness
    ess_line = read_line(io)
    parse_endianness(ess_line) == 1.0 || parse_endianness(ess_line)== -1.0 || throw(InvalidPfmFileFormat("invalid endianness in PFM file: $(parse_endianness(ess_line)) instead of +1.0 or -1.0.\n"))
    endianness = parse_endianness(ess_line)

    # lettura e assegnazione matrice coloti
    result = HDRimage(width, height)
    for y in height-1:-1:0, x in 0:width-1

        (r,g,b) = [read_float(io, endianness) for i in 0:2]
        set_pixel(result, x, y, RGB(r,g,b) )
    end

    return result
end # read_pfm_image(::IO)

##########################################################################################92

"""
    parse_command_line(ARGS) -> (String, String, Float64, Float64)

Can interpret the command line when the main is executed.

# Arguments
- input file name, must be a PFM format
- outfile format name, can be a PNG or TIFF image format
- [`a`] factor for luminosity correction (default 0.18, used in [`normalize_image!`](@ref))(`::HDRimage`, `::Number`, `::Union`{`Number`, `nothing`}, `::Number`)
- [`γ`] factor for screen correction (default 1.0, used in [`γ_correction!`](`::HDR`, `::Float64`, `::Float64`)
"""
function parse_command_line(args)
    (isempty(args) || length(args)==1 || length(args)>4) && throw(Exception)	  
    infile = nothing; outfile = nothing; a=0.18; γ=1.0
    try
        infile = args[1]
        outfile = args[2]
        open(infile, "r") do io
            read(io, UInt8)
        end
    catch e
        throw(RuntimeError("invalid input file: $(args[1]) does not exist"))
    end

    if length(args)>2
        try
            a = parse(Float64, args[3])
            a > 0. || throw(Exception)
        catch e
            throw(InvalidArgumentError("invalid value for a: $(args[3])  must be a positive number"))
        end

        if length(args) == 4
            try
                γ = parse(Float64, args[4])
                γ > 0. || throw(Exception)
            catch e
                throw(InvalidArgumentError("invalid value for γ: $(args[4])  must be a positive number"))
            end
        end
    end

    return infile, outfile, a, γ
end


##########################################################################################92


function parse_tonemapping_settings(dict::Dict{String, Any})
    a::Float64 = dict["alpha"]
    γ::Float64 = dict["gamma"]
    pfm::String = dict["pfm_infile"]
    png::String = dict["outfile"]
    return (pfm, png, a, γ)
end

function parse_demo_settings(dict::Dict{String, Any})
    ort::Bool = dict["orthogonal"]
    per::Bool = dict["perspective"]
    α::Float64 = dict["alpha"]
    w::Int64 = dict["width"]
    h::Int64 = dict["height"]
    pfm::String = dict["set-pfm-name"]
    png::String = dict["set-png-name"]

    if ( (ort==true) || (ort==per==false) ) 
        view_ort=true
    elseif ((ort==false) && (per==true))
        view_ort=false
    else
        view_ort=nothing
    end

    return (view_ort, α, w, h, pfm, png)
end



function parse_demoanimation_settings(dict::Dict{String, Any})
    ort::Bool = dict["orthogonal"]
    per::Bool = dict["perspective"]
    w::Int64 = dict["width"]
    h::Int64 = dict["height"]
    anim::String = dict["set-anim-name"]

    if ( (ort==true) || (ort==per==false) ) 
        view_ort=true
    elseif ((ort==false) && (per==true))
        view_ort=false
    else
        view_ort=nothing
    end

    return (view_ort, w, h, anim)
end
