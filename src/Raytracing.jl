module Raytracing

using Colors  #generico
import ColorTypes:RGB  #specificare sempre cosa si importa. In questo caso posso evitare di secificare nella funzione "x::ColorTypes.RGB{T}"
import Base.:+; import Base.:-; import Base.:≈; import Base.:*
#export HDRimage

#=
#T = Float64 errato

function Base.:+(x::RGB{T}, y::RGB{T}) where{T} #in questo modo tipo qualsiasi, per specificare: where{T<:real}
     RGB(x.r + y.r, x.g + y.g, x.b + y.b)
end
=#

Base.:+(a::RGB{T}, b::RGB{T}) where {T} = RGB(a.r + b.r, a.g + b.g, a.b + b.b)
Base.:-(a::RGB{T}, b::RGB{T}) where {T} = RGB(a.r - b.r, a.g - b.g, a.b - b.b)
Base.:*(scalar, c::RGB{T}) where {T} = RGB(scalar*c.r , scalar*c.g, scalar*c.b)
Base.:*(c::RGB{T}, scalar) where {T} = scalar * c
Base.:≈(a::RGB{T}, b::RGB{T}) where {T} = are_close(a.r,b.r) && are_close(a.g,b.g) && are_close(a.b, b.b)

are_close(x,y,epsilon=1e-10) = abs(x-y) < epsilon

struct HDRimage
    width::Int
    height::Int
    rgb_m::Array{RGB{Float32}}
    HDRimage(w,h) = new(w,h, fill(RGB(0.0, 0.0, 0.0), (w*h,)) )
    function HDRimage(w,h, rgb_m) 
        @assert size(rgb_m) == (w*h,)
        new(w,h, rgb_m)
    end
end

valid_coordinates(hdr::HDRimage, x::Int, y::Int) = x>=0 && y>=0 && x<hdr.width && y<hdr.height
function pixel_offset(hdr::HDRimage, x::Int, y::Int)
    @assert valid_coordinates(hdr, x, y)
    y*hdr.width + (x+1)
end

get_pixel(hdr::HDRimage, x::Int, y::Int) = hdr.rgb_m[pixel_offset(hdr, x, y)]
function set_pixel(hdr::HDRimage, x::Int, y::Int, c::RGB{T}) where {T}
    hdr.rgb_m[pixel_offset(hdr, x,y)] = c
    nothing
end


end # module
