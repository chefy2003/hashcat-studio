import json
import subprocess
import shutil
import unreal

def inspect_hardware_storage():
    """Чете топологията на дисковете от Linux ядрото през lsblk"""
    cmd = "lsblk -J -b -o NAME,MOUNTPOINT,FSTYPE,SIZE,ROTA,RM,HOTPLUG,MODEL"
    try:
        raw = subprocess.check_output(cmd, shell=True, text=True)
        data = json.loads(raw)
    except Exception as e:
        unreal.log_error(f"[StorageEngine] Грешка при lsblk: {e}")
        return []

    discovered = []

    def parse_device_tree(devices):
        for dev in devices:
            mount = dev.get("mountpoint")
            if mount and dev.get("fstype") not in ["swap", "squashfs", None] and not mount.startswith(('/snap', '/boot')):
                try:
                    usage = shutil.disk_usage(mount)
                    is_removable = bool(dev.get("rm") or dev.get("hotplug"))
                    is_ssd = (dev.get("rota") == False or dev.get("rota") == 0)

                    if mount == "/":
                        hw_class = "SYSTEM_ROOT"
                    elif is_removable:
                        hw_class = "HOTPLUG_MEDIA"
                    elif is_ssd:
                        hw_class = "NVME_FAST"
                    else:
                        hw_class = "BULK_VAULT"

                    discovered.append({
                        "mount": mount,
                        "device": f"/dev/{dev.get('name')}",
                        "hw_class": hw_class,
                        "total_gb": round(usage.total / (1024**3), 1),
                        "free_gb": round(usage.free / (1024**3), 1)
                    })
                except PermissionError:
                    pass

            if "children" in dev:
                parse_device_tree(dev["children"])

    parse_device_tree(data.get("blockdevices", []))
    return discovered

def spawn_spatial_storage_matrix():
    drives = inspect_hardware_storage()
    count = len(drives)
    if count == 0:
        return

    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

    # 1. Изчистване на пиедестала от старите плочки и огледален текст
    for a in subsystem.get_all_level_actors():
        if a.actor_has_tag("StorageNode") or a.actor_has_tag("ArtifactShard"):
            subsystem.destroy_actor(a)

    # 2. Взимане на трансформацията от СЕЛЕКТИРАНИЯ ПАНЕЛ (жълтия контур)
    selected = subsystem.get_selected_level_actors()
    if selected:
        target_panel = selected[0]
        panel_loc = target_panel.get_actor_location()
        panel_rot = target_panel.get_actor_rotation()
        forward_vec = target_panel.get_actor_forward_vector()
        unreal.log_warning(f"[StorageEngine] Автоматично скачване към селектирания панел: {target_panel.get_actor_label()}")
    else:
        # Резервна позиция, ако нищо не е селектирано
        panel_loc = unreal.Vector(-40.0, -280.0, 160.0)
        panel_rot = unreal.Rotator(0.0, 15.0, 0.0)
        forward_vec = unreal.Vector(1.0, 0.0, 0.0)

    # Базова точка: леко пред лицето на панела (+6 см по нормалата, за да няма z-fighting)
    origin_loc = panel_loc + (forward_vec * 6.0)
    cube_mesh = unreal.load_asset("/Engine/BasicShapes/Cube.Cube")

    start_z_offset = 35.0
    spacing_z = 13.0

    # 3. Заглавна табела за панела
    header_loc = unreal.Vector(origin_loc.x, origin_loc.y, origin_loc.z + start_z_offset + 10.0)
    header_actor = subsystem.spawn_actor_from_class(unreal.TextRenderActor, header_loc, panel_rot)
    header_actor.tags.append("StorageNode")
    header_actor.set_actor_label("Label_Storage_Header")

    h_comp = header_actor.get_component_by_class(unreal.TextRenderComponent)
    if h_comp:
        h_comp.set_text(unreal.Text("// ACTIVE STORAGE VOLUMES"))
        h_comp.set_world_size(6.0)
        h_comp.set_horizontal_alignment(unreal.HorizTextAligment.EHTA_CENTER)

    # 4. Спаунване на редовете залепени върху панела
    for i, d in enumerate(drives):
        z_curr = origin_loc.z + start_z_offset - (i * spacing_z)
        loc = unreal.Vector(origin_loc.x, origin_loc.y, z_curr)

        # Тънка плочка/слот върху таблото
        plate = subsystem.spawn_actor_from_class(unreal.StaticMeshActor, loc, panel_rot)
        plate.tags.append("StorageNode")
        plate.set_actor_label(f"Blade_{d['hw_class']}_{i}")

        sm = plate.static_mesh_component
        sm.set_static_mesh(cube_mesh)
        plate.set_actor_scale3d(unreal.Vector(0.02, 1.05, 0.10))

        # Текст за монтиране (Mount & Class) - четим отпред
        t_loc = unreal.Vector(loc.x, loc.y, z_curr + 1.2) + (forward_vec * 2.0)
        t_actor = subsystem.spawn_actor_from_class(unreal.TextRenderActor, t_loc, panel_rot)
        t_actor.tags.append("StorageNode")

        tc = t_actor.get_component_by_class(unreal.TextRenderComponent)
        if tc:
            tc.set_text(unreal.Text(f"[{d['hw_class']}]  {d['mount']}"))
            tc.set_world_size(4.5)
            tc.set_horizontal_alignment(unreal.HorizTextAligment.EHTA_CENTER)

        t_actor.attach_to_actor(plate, unreal.Name("None"), unreal.AttachmentRule.KEEP_WORLD, unreal.AttachmentRule.KEEP_WORLD, unreal.AttachmentRule.KEEP_WORLD, False)

        # Текст за обема (Free / Total GB)
        c_loc = unreal.Vector(loc.x, loc.y, z_curr - 3.2) + (forward_vec * 2.0)
        c_actor = subsystem.spawn_actor_from_class(unreal.TextRenderActor, c_loc, panel_rot)
        c_actor.tags.append("StorageNode")

        cc = c_actor.get_component_by_class(unreal.TextRenderComponent)
        if cc:
            cc.set_text(unreal.Text(f"{d['free_gb']} GB FREE / {d['total_gb']} GB"))
            cc.set_world_size(3.6)
            cc.set_horizontal_alignment(unreal.HorizTextAligment.EHTA_CENTER)

        c_actor.attach_to_actor(plate, unreal.Name("None"), unreal.AttachmentRule.KEEP_WORLD, unreal.AttachmentRule.KEEP_WORLD, unreal.AttachmentRule.KEEP_WORLD, False)

    unreal.log_warning("=== [STORAGE HUD DOCKED TO SELECTED PANEL] ===")

if __name__ == "__main__":
    spawn_spatial_storage_matrix()
