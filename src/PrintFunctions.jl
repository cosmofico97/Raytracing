# -*- encoding: utf-8 -*-
#
# The MIT License (MIT)
#
# Copyright © 2021 Matteo Foglieni and Riccardo Gervasoni
#

# RBG print functions
print(io::IO, c::RGB{T}) where T = print(io, "RGB = (", c.r, ", ", c.g, ", ", c.b, ")" )
print(c::RGB{T}) where T = print(stdout, c)
println(io::IO, c::RGB{T}) where T = println(io, "RGB = (", c.r, ", ", c.g, ", ", c.b, ")" )
println(c::RGB{T}) where T = println(stdout, c)

# Point print functions
print(io::IO, p::Point) = print(io, "Point = (", p.x, ", ", p.y, ", ", p.z, ")" )
print(p::Point) = print(stdout, p)
println(io::IO, p::Point) = print(io, "Point = (", p.x, ", ", p.y, ", ", p.z, ")" )
println(p::Point) = println(stdout, p)

# Vec print functions
print(io::IO, v::Vec) = print(io, "Vec = (", v.x, ", ", v.y, ", ", v.z, ")" )
print(v::Vec) = print(stdout, v)
println(io::IO,v::Vec) = println(io, "Vec = (", v.x, ", ", v.y, ", ", v.z, ")" )
println(v::Vec) = println(stdout,v)

# Normal print functions
print(io::IO, n::Normal) = print(io, "Normal = (", n.x, ", ", n.y, ", ", n.z, ")" )
print(n::Normal) = print(stdout, n)
println(io::IO,n::Normal) = println(io, "Normal = (", n.x, ", ", n.y, ", ", n.z, ")" )
println(n::Normal) = println(stdout,n)

# Ray print functions
function println(io::IO, ray::Ray)
     println(io, "Ray with origin-direction-tmin-tmax-depth:")
     println(io, ray.origin, " \t  ", ray.dir)
     println(io, "tmin = ", ray.tmin, " \t tmax = ", ray.tmax, " \t depth = ", ray.depth)
end
function print(io::IO, ray::Ray)
     println(io, "Ray with origin-direction-tmin-tmax-depth:")
     println(io, ray.origin, " \t  ", ray.dir)
     println(io, "tmin = ", ray.tmin, " \t tmax = ", ray.tmax, " \t depth = ", ray.depth)
end
println(ray::Ray) = println(stdout, ray)
print(ray::Ray) = print(stdout, ray)

# Vec2d print functions
println(io::IO, uv::Vec2d) =  println(io, "Vec2d = (", uv.u, ", ", uv.v, ")" )
println(uv::Vec2d) =  println(stdout, "Vec2d = (", uv.u, ", ", uv.v, ")" )
print(io::IO, uv::Vec2d) =  print(io, "Vec2d = (", uv.u, ", ", uv.v, ")" )
print(uv::Vec2d) =  print(stdout, "Vec2d = (", uv.u, ", ", uv.v, ")" )


# HitRecord print functions
function println(io::IO, hit::HitRecord)
     println(io, "HitRecord with  the following criteria:")
     println(io, "world point :\t" , hit.world_point)
     println(io, "normal :\t" , hit.normal)
     println(io, "surface point :\t" , hit.surface_point)
     println(io, "t of hit :\t" , hit.t)
     println(io, "ray :\t" , hit.ray)
     println(io, "shape = ", typeof(hit.shape))
end
print(io::IO, hit::HitRecord) = println(io, hit)
println(hit::HitRecord) = println(stdout, hit)
print(hit::HitRecord) = print(stdout, hit)


# AABB print functions
function println(io::IO, aabb::AABB)
     println(io, "AABB with the following points:")
     println(io, "minimum point m :\t" , aabb.m)
     println(io, "maximum point M :\t" , aabb.M)
end
print(io::IO,  aabb::AABB) = println(io, aabb)
println(aabb::AABB) = println(stdout, aabb)
print(aabb::AABB) = print(stdout, aabb)

function println(img::HDRimage, n::Int64=5)
     n>=1 || throw(ArgumentError("not a valid index; $n must be >0"))
     n<=50 || throw(ArgumentError("too big index; $n must be <=50"))

     w=img.width
     h=img.height
     println("HDRImage to be printed")
     println("width = ", w, "\t height = ", h)
     if (w*h) <= (2*n)
          for c in img.rgb_m; println(c); end
     else
          for i in 1:n; println(img.rgb_m[n]);end
          println("...")
          for i in 1:n; println(img.rgb_m[end-n+i]);end
     end
     nothing
end

function print_not_black(img::HDRimage)
     w=img.width
     h=img.height
     println("HDRImage to be printed")
     println("width = ", w, "\t height = ", h)

     for (i, color) in enumerate(img.rgb_m)
          color==BLACK ? nothing : println(i, "\t", color)
     end

     nothing
end

