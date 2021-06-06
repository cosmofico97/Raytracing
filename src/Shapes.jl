# -*- encoding: utf-8 -*-
#
# The MIT License (MIT)
#
# Copyright © 2021 Matteo Foglieni and Riccardo Gervasoni
#


##########################################################################################92

"""
    ray_intersection(shape::Shape, ray::Ray) :: ErrorException

Compute the intersection between a [`Ray`](@ref) and a [`Shape`](@ref)
"""
function ray_intersection(shape::Shape, ray::Ray)
    return ErrorException("ray_intersection is an abstract method
                           and cannot be called directly"
    )
end

##########################################################################################92

@doc raw"""
    sphere_point_to_uv(point::Point) :: Vec2d

Convert a 3D `Point` ``point = (P_x, P_y, P_z)`` on the surface of the unit sphere
into a 2D `Vec2d` using the following spherical coordinates:

```math
u = \frac{\phi}{2\pi} = \frac{\arctan (P_y / P_x)}{2\pi}, 
    \quad 
v = \frac{\theta}{\pi} = \frac{\arccos (P_z)}{\pi}
```

See also: [`Point`](@ref), [`Vec2d`](@ref), [`Sphere`](@ref)
"""
function sphere_point_to_uv(point::Point)
    u = acos(point.z) / π
    v = atan(point.y, point.x) / (2.0 * π)
    v>=0 ? nothing : v+= 1.0
    return Vec2d(u,v)
end

@doc raw"""
    plane_point_to_uv(point::Point) :: Vec2d

Convert a 3D `Point` ``point = (P_x, P_y, P_z)`` on the surface of the unit plane
into a 2D `Vec2d` using the following periodical coordinates:

```math
u = P_x - \lfloor P_x \rfloor,
    \quad 
v = P_y - \lfloor P_y \rfloor,
```
    
where ``\lfloor \cdot \rfloor`` indicates the rounding down approximation,
in order to guarantee that ``u, v \in [0, 1)``.

See also: [`Point`](@ref), [`Vec2d`](@ref), [`Plane`](@ref)
"""
function plane_point_to_uv(point::Point)
    u = point.x - floor(point.x)
    v = point.y - floor(point.y)
    return Vec2d(u,v)
end

##########################################################################################92

@doc raw"""
    sphere_normal(point::Point, ray_dir::Vec) :: Normal

Compute the `Normal` of a unit sphere.

The normal is computed for the given `Point` ``point = (P_x, P_y, P_z)`` 
(with ``\sqrt{P_x^2 + P_y^2 + P_z^2}=1``) on the 
surface of the sphere, and it is chosen so that it is always in the opposite
direction with respect to the given `Vec` `ray_dir`.

See also: [`Point`](@ref), [`Ray`](@ref), [`Normal`](@ref), [`Sphere`](@ref)
"""
function sphere_normal(point::Point, ray_dir::Vec)
    result = Normal(point.x, point.y, point.z)
    Vec(point) ⋅ ray_dir < 0.0 ? nothing : result = -result
    return result
end

@doc raw"""
    plane_normal(point::Point, ray_dir::Vec) :: Normal

Compute the `Normal` of a unit plane.

The normal is computed for the given `Point` ``point = (P_x, P_y, 0)`` on the 
surface of the plane, and it is chosen so that it is always in the opposite
direction with respect to the given `Vec` `ray_dir`.

See also: [`Point`](@ref), [`Ray`](@ref), [`Normal`](@ref), [`Plane`](@ref)
"""
function plane_normal(point::Point, ray_dir::Vec)
    result = Normal(0., 0., 1.)
    Vec(0., 0., 1.) ⋅ ray_dir < 0.0 ? nothing : result = -result
    return result
end

##########################################################################################92

"""
    ray_intersection(sphere::Sphere, ray::Ray) -> HitRecord

Check if a ray ([`Ray`](@ref)) intersects the sphere ([`Sphere`](@ref))

Return a [`HitRecord`](@ref), or `nothing` if no intersection is found.
"""
function ray_intersection(sphere::Sphere, ray::Ray)
    inv_ray = inverse(sphere.T) * ray
    origin_vec = Vec(inv_ray.origin)

    a = squared_norm(inv_ray.dir)
    b = 2.0 * origin_vec ⋅ inv_ray.dir
    c = squared_norm(origin_vec) - 1.0
    Δ = b * b - 4.0 * a * c 
     
    (Δ > 0.0) || (return nothing)

    tmin = (-b - √Δ) / (2.0 * a)
    tmax = (-b + √Δ) / (2.0 * a)

    if (tmin > inv_ray.tmin) && (tmin < inv_ray.tmax)
        first_hit_t = tmin
    elseif (tmax > inv_ray.tmin) && (tmax < inv_ray.tmax)
        first_hit_t = tmax
    else
        return nothing
    end

    hit_point = at(inv_ray, first_hit_t)
    
    return HitRecord(
        sphere.T * hit_point,
        sphere.T * sphere_normal(hit_point, inv_ray.dir),
        sphere_point_to_uv(hit_point),
        first_hit_t,
        ray, 
        sphere
    )
end


"""
    ray_intersection(plane::Plane, ray::Ray) -> HitRecord

Check if a ray ([`Ray`](@ref)) intersects the plane ([`Plane`](@ref))

Return a [`HitRecord`](@ref), or `nothing` if no intersection is found.
"""
function ray_intersection(plane::Plane, ray::Ray)
    inv_ray = inverse(plane.T) * ray

    !(inv_ray.dir.z ≈ 0.) || (return nothing)

    hit_t = - inv_ray.origin.z / inv_ray.dir.z

    ( (hit_t > inv_ray.tmin) && (hit_t < inv_ray.tmax) ) || (return nothing)

    hit_point = at(inv_ray, hit_t)

    return HitRecord(
        plane.T * hit_point,
        plane.T * plane_normal(hit_point, inv_ray.dir),
        plane_point_to_uv(hit_point),
        hit_t,
        ray,
        plane
    )
end


##########################################################################################92

"""
    add_shape!(W::World, S::Shape)

Append a new shape to this world

See also: [`Shape`](@ref), [`World`](@ref)
"""
function add_shape!(W::World, S::Shape)
    push!(W.shapes, S)
    return nothing
end

##########################################################################################92

"""
    ray_intersection(world::World, ray::Ray) -> HitRecord

Determine whether a [`Ray`](@ref) intersects any of the objects in this [`World`](@ref)
"""
function ray_intersection(world::World, ray::Ray)
    closest = nothing

    for shape in world.shapes
        intersection = ray_intersection(shape, ray)

        # The ray missed this shape, skip to the next one
        !(isnothing(intersection)) || continue

        # There was a hit, and it was closer than any other hit found before
        ( isnothing(closest) || (intersection.t < closest.t) ) &&  (closest = intersection)
    end
    
    return closest
end
