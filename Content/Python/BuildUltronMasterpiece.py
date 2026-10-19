import unreal

def build():
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    
    # 1. Clean existing UltronCore actors
    actors_to_delete = []
    for a in list(subsystem.get_all_level_actors()):
        try:
            label = a.get_actor_label()
            if "Ultron" in label or a.actor_has_tag("UltronCore") or "Matrix_EnergyCore" in label:
                actors_to_delete.append(a)
        except Exception:
            pass
            
    for a in actors_to_delete:
        try:
            subsystem.destroy_actor(a)
        except Exception:
            pass
            
    unreal.log(f"[BuildUltronMasterpiece] Cleaned {len(actors_to_delete)} legacy actors.")

    # 2. Load Assets
    mat_holo = unreal.load_asset("/Game/M_Ultron_DigitalHolo.M_Ultron_DigitalHolo")
    mat_belt = unreal.load_asset("/Game/M_Ultron_WaveformBelt.M_Ultron_WaveformBelt")
    mat_orbit = unreal.load_asset("/Game/M_Ultron_AtomicOrbit.M_Ultron_AtomicOrbit")
    mat_nucleus = unreal.load_asset("/Game/MI_UltronAmber_BrightCore.MI_UltronAmber_BrightCore")
    
    mesh_plane = unreal.load_asset("/Engine/BasicShapes/Plane.Plane")
    mesh_sphere = unreal.load_asset("/Engine/BasicShapes/Sphere.Sphere")
    mesh_cylinder = unreal.load_asset("/Engine/BasicShapes/Cylinder.Cylinder")
    
    center_loc = unreal.Vector(0.0, 0.0, 165.0)

    # 3. Helper to create and configure elements
    def create_element(name, mesh, mat, scale, rot, spin_rate=None):
        actor = subsystem.spawn_actor_from_class(unreal.StaticMeshActor, center_loc, unreal.Rotator(rot[0], rot[1], rot[2]))
        actor.set_actor_label(f"Ultron_{name}")
        actor.tags.append("UltronCore")
        try:
            actor.set_folder_path("UltronCore")
        except Exception:
            pass
            
        smc = actor.static_mesh_component
        smc.set_mobility(unreal.ComponentMobility.MOVABLE)
        smc.set_static_mesh(mesh)
        smc.set_material(0, mat)
        smc.set_world_scale3d(unreal.Vector(scale[0], scale[1], scale[2]))
        smc.set_collision_enabled(unreal.CollisionEnabled.NO_COLLISION)
        
        if spin_rate:
            try:
                rot_comp = actor.add_component_by_class(unreal.RotatingMovementComponent, False, unreal.Transform(), False)
                rot_comp.rotation_rate = unreal.Rotator(spin_rate[0], spin_rate[1], spin_rate[2])
            except Exception as e:
                unreal.log_warning(f"[BuildUltronMasterpiece] RotatingMovement error for {name}: {e}")
                
        return actor

    # ==========================================
    # LAYER 1: Core Radiant Nucleus (Singularity)
    # ==========================================
    create_element("Nucleus", mesh_sphere, mat_nucleus, (0.16, 0.16, 0.16), (0.0, 0.0, 0.0), (0.0, 45.0, 0.0))

    # ==========================================
    # LAYER 2: Equatorial Waveform Spectrograph Belt
    # (Matches Brahma Echo UI horizontal audio/data equalizer ring)
    # ==========================================
    create_element("WaveformBelt", mesh_cylinder, mat_belt, (2.3, 2.3, 0.14), (0.0, 0.0, 0.0), (0.0, 6.0, 0.0))
    create_element("WaveformBelt_Inner", mesh_cylinder, mat_belt, (1.7, 1.7, 0.08), (0.0, 0.0, 0.0), (0.0, -12.0, 0.0))

    # ==========================================
    # LAYER 3: Counter-Rotating Gyroscopic Gimbals
    # (Matches Brahma Echo tilted orbital hoops)
    # ==========================================
    create_element("Gimbal_HoopA", mesh_plane, mat_holo, (2.55, 2.55, 2.55), (48.0, 22.0, 0.0), (12.0, 26.0, 8.0))
    create_element("Gimbal_HoopB", mesh_plane, mat_holo, (2.55, 2.55, 2.55), (-48.0, -22.0, 0.0), (-10.0, -30.0, -6.0))
    create_element("Gimbal_EquatorialDial", mesh_plane, mat_holo, (2.4, 2.4, 2.4), (0.0, 0.0, 0.0), (0.0, 16.0, 0.0))

    # ==========================================
    # LAYER 4: Atomic Celestial Particle Orbits
    # (Matches Marvel Astrolabe Rutherford-Bohr electron tracks with traveling beads)
    # ==========================================
    create_element("AtomicOrbitA", mesh_plane, mat_orbit, (3.1, 3.1, 3.1), (25.0, 40.0, 10.0), (6.0, 18.0, 4.0))
    create_element("AtomicOrbitB", mesh_plane, mat_orbit, (3.25, 3.25, 3.25), (-55.0, -35.0, 40.0), (-8.0, -22.0, 9.0))
    create_element("AtomicOrbitC", mesh_plane, mat_orbit, (2.85, 2.85, 2.85), (65.0, -55.0, -30.0), (15.0, -14.0, 18.0))

    # ==========================================
    # LAYER 5: Inner Spiral Helix & Neural Spherical Shells
    # ==========================================
    create_element("InnerHelixSphere", mesh_sphere, mat_holo, (0.85, 0.85, 0.85), (-40.0, 30.0, 60.0), (16.0, -25.0, 14.0))
    create_element("MidNeuralSphere", mesh_sphere, mat_holo, (1.55, 1.55, 1.55), (20.0, -35.0, 15.0), (-6.0, 14.0, -8.0))

    # ==========================================
    # LAYER 6: Warm Amber Core Light
    # ==========================================
    light_actor = subsystem.spawn_actor_from_class(unreal.PointLight, center_loc, unreal.Rotator(0.0, 0.0, 0.0))
    light_actor.set_actor_label("Ultron_Core_PointLight")
    light_actor.tags.append("UltronCore")
    try:
        light_actor.set_folder_path("UltronCore")
    except Exception:
        pass
        
    plc = light_actor.point_light_component
    plc.set_intensity(4800.0)
    plc.set_light_color(unreal.LinearColor(1.0, 0.58, 0.10, 1.0))
    plc.set_attenuation_radius(500.0)
    plc.set_cast_shadows(False)

    unreal.log_warning("[BuildUltronMasterpiece] SUCCESS: Ultron Masterpiece Core assembled with all 6 dynamic layers!")

build()
