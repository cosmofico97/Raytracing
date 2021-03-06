# -*- encoding: utf-8 -*-
#
# The MIT License (MIT)
#
# Copyright © 2021 Matteo Foglieni and Riccardo Gervasoni
#

@testset "test_OnOffRenderer" begin
     sphere = Sphere(translation(Vec(2, 0, 0)) * scaling(Vec(0.2, 0.2, 0.2)),
                    Material(DiffuseBRDF(UniformPigment(WHITE))))
     image = HDRimage(3, 3)
     camera = OrthogonalCamera()
     tracer = ImageTracer(image, camera, 0) # without antialiasing
     world = World()
     add_shape!(world, sphere)
     renderer = OnOffRenderer(world)
     fire_all_rays!(tracer, renderer)

     @test Raytracing.get_pixel(image, 0, 0) ≈ BLACK
     @test Raytracing.get_pixel(image, 1, 0) ≈ BLACK
     @test Raytracing.get_pixel(image, 2, 0) ≈ BLACK

     @test Raytracing.get_pixel(image, 0, 1) ≈ BLACK
     @test Raytracing.get_pixel(image, 1, 1) ≈ WHITE # gives error with antialiasing
     @test Raytracing.get_pixel(image, 2, 1) ≈ BLACK

     @test Raytracing.get_pixel(image, 0, 2) ≈ BLACK
     @test Raytracing.get_pixel(image, 1, 2) ≈ BLACK
     @test Raytracing.get_pixel(image, 2, 2) ≈ BLACK
end

@testset "test_FlatRenderer" begin
     sphere_color = RGB{Float32}(5.0, 6.0, 7.0)
     α = 0.2
     sphere = Sphere(translation(Vec(2, 0, 0)) * scaling(Vec(α, α, α)),
                    Material(DiffuseBRDF(UniformPigment(sphere_color))))
     
     @test sphere.Material.brdf.pigment == UniformPigment(sphere_color)

     image = HDRimage(3, 3)
     camera = OrthogonalCamera()
     tracer = ImageTracer(image, camera, 0) # without antialiasing

     world = World()
     add_shape!(world, sphere)
     renderer = FlatRenderer(world)
     fire_all_rays!(tracer, renderer)

     @test Raytracing.get_pixel(image, 0, 0) ≈ BLACK
     @test Raytracing.get_pixel(image, 1, 0) ≈ BLACK
     @test Raytracing.get_pixel(image, 2, 0) ≈ BLACK

     @test Raytracing.get_pixel(image, 0, 1) ≈ BLACK
     @test Raytracing.get_pixel(image, 1, 1) ≈ sphere_color # gives error with antialiasing
     @test Raytracing.get_pixel(image, 2, 1) ≈ BLACK

     @test Raytracing.get_pixel(image, 0, 2) ≈ BLACK
     @test Raytracing.get_pixel(image, 1, 2) ≈ BLACK
     @test Raytracing.get_pixel(image, 2, 2) ≈ BLACK
end

@testset "test_PathTracer" begin
     # Here is impemented the Furnace test.
     # It is runned several times using random values 
     # for the emitted radiance and reflectance.
     
     pcg = PCG()

     for i in 1:10
          world = World()
          emitted_radiance = random(pcg)
          reflectance = random(pcg)
          enclosure_material = 
               Material(
                    DiffuseBRDF(UniformPigment(RGB{Float32}(1., 1., 1.) * reflectance)),
                    UniformPigment(RGB{Float32}(1., 1., 1.) * emitted_radiance),
               )

          add_shape!(world, Sphere(enclosure_material))

          path_tracer = PathTracer(world, BLACK, pcg, 1, 100, 101)

          ray = Ray(Point(0., 0., 0.), Vec(1., 0., 0.))
          color = path_tracer(ray)

          expected = emitted_radiance / (1.0 - reflectance)
          
          err=1e-3
          @test are_close(expected, color.r, err)
          @test are_close(expected, color.g, err)
          @test are_close(expected, color.b, err)

     end
end

@testset "test_PointLightTracer" begin
     @testset "quick_ray_intersection_sphere" begin
          world = World()

          sphere1 = Sphere(translation(Vec(2.0, 0.0, 0.0)))
          sphere2 = Sphere(translation(Vec(8.0, 0.0, 0.0)))
          add_shape!(world, sphere1)
          add_shape!(world, sphere2)

          @test is_point_visible(world, Point(-10.0, 0.0, 0.0), Point(0.0, 0.0, 0.0))
          @test !is_point_visible(world, Point(10.0, 0.0, 0.0), Point(0.0, 0.0, 0.0))
          @test !is_point_visible(world, Point(5.0, 0.0, 0.0), Point(0.0, 0.0, 0.0))
          @test is_point_visible(world, Point(5.0, 0.0, 0.0), Point(4.0, 0.0, 0.0))
          @test is_point_visible(world, Point(0.5, 0.0, 0.0), Point(0.0, 0.0, 0.0))
          @test is_point_visible(world, Point(0.0, 10.0, 0.0), Point(0.0, 0.0, 0.0))
          @test is_point_visible(world, Point(0.0, 0.0, 10.0), Point(0.0, 0.0, 0.0))
     end

     @testset "quick_ray_intersection_plane" begin
          world = World()

          plane1 = 
               Plane(
                    translation(Vec(2.0, 0.0, 0.0)) * rotation_y(π/2.)
               )
          plane2 = 
               Plane(
                    translation(Vec(8.0, 0.0, 0.0)) * rotation_y(π/2.)
               )
          add_shape!(world, plane1)
          add_shape!(world, plane2)

          @test is_point_visible(world, Point(-10.0, 0.0, 0.0), Point(0.0, 0.0, 0.0))
          @test !is_point_visible(world, Point(10.0, 0.0, 0.0), Point(0.0, 0.0, 0.0))
          @test !is_point_visible(world, Point(5.0, 0.0, 0.0), Point(0.0, 0.0, 0.0))
          @test is_point_visible(world, Point(5.0, 0.0, 0.0), Point(4.0, 0.0, 0.0))
          @test is_point_visible(world, Point(0.5, 0.0, 0.0), Point(0.0, 0.0, 0.0))
          @test is_point_visible(world, Point(0.0, 10.0, 0.0), Point(0.0, 0.0, 0.0))
          @test is_point_visible(world, Point(0.0, 0.0, 10.0), Point(0.0, 0.0, 0.0))
     end
end