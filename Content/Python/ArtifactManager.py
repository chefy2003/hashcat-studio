import os
import math
import unreal

TARGET_EXTENSIONS = {
    ".cap": "WIFI_CAPTURE",
    ".pcap": "WIFI_CAPTURE",
    ".pcapng": "WIFI_CAPTURE",
    ".22000": "HASHCAT_22000",
    ".kdbx": "KEEPASS_DB",
    ".dit": "ACTIVE_DIRECTORY",
    ".ntds": "ACTIVE_DIRECTORY"
}

def scan_mount_for_artifacts(mount_path, max_depth=3, max_results=5):
    """Сканира директорията за офанзивни файлове с ограничен обхват за бързодействие"""
    found = []
    ignored = {"proc", "sys", "dev", "snap", "var", "usr", "lib", ".git", "node_modules"}

    for root, dirs, files in os.walk(mount_path):
        # Пропускане на системни папки
        dirs[:] = [d for d in dirs if d not in ignored and not d.startswith('.')]
        
        depth = root[len(mount_path):].count(os.sep)
        if depth > max_depth:
            continue

        for f in files:
            ext = os.path.splitext(f)[1].lower()
            if ext in TARGET_EXTENSIONS or "shadow" in f.lower() or "hashes" in f.lower():
                full_path = os.path.join(root, f)
                found.append({
                    "name": f,
                    "path": full_path,
                    "type": TARGET_EXTENSIONS.get(ext, "GENERIC_HASH"),
                    "size_kb": round(os.path.getsize(full_path) / 1024, 1)
                })
                if len(found) >= max_results:
                    return found
    return found

def deploy_artifacts_above_cartridge(cartridge_actor, mount_path):
    """Разгръща откритите файлове като светещи капсули над посочената касета"""
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)

    # Изчистване на стари капсули
    for actor in subsystem.get_all_level_actors():
        if actor.actor_has_tag("ArtifactShard"):
            subsystem.destroy_actor(actor)

    artifacts = scan_mount_for_artifacts(mount_path)
    if not artifacts:
        unreal.log_warning(f"[ArtifactManager] Няма открити офанзивни цели в {mount_path}")
        return

    unreal.log_warning(f"=== [ARTIFACTS DISCOVERED: {len(artifacts)}] Разгръщане над {mount_path} ===")

    base_loc = cartridge_actor.get_actor_location()
    base_rot = cartridge_actor.get_actor_rotation()
    cone_mesh = unreal.load_asset("/Engine/BasicShapes/Cone.Cube") or unreal.load_asset("/Engine/BasicShapes/Cube.Cube")

    for idx, art in enumerate(artifacts):
        # Позициониране стъпаловидно над касетата
        offset_z = 35.0 + (idx * 22.0)
        shard_loc = unreal.Vector(base_loc.x, base_loc.y, base_loc.z + offset_z)

        # 1. Спаунване на капсулата (Shard)
        shard = subsystem.spawn_actor_from_class(unreal.StaticMeshActor, shard_loc, base_rot)
        shard.tags.append("ArtifactShard")
        shard.tags.append(f"Path::{art['path']}")
        shard.set_actor_label(f"Shard_{art['type']}_{idx}")
        
        sm_comp = shard.static_mesh_component
        sm_comp.set_static_mesh(cone_mesh)
        shard.set_actor_scale3d(unreal.Vector(0.3, 0.3, 0.3))

        # 2. Текст с името на файла и типа
        label_loc = unreal.Vector(base_loc.x, base_loc.y, shard_loc.z + 8.0)
        label = subsystem.spawn_actor_from_class(unreal.TextRenderActor, label_loc, base_rot)
        label.tags.append("ArtifactShard")
        
        t_comp = label.get_component_by_class(unreal.TextRenderComponent)
        if t_comp:
            t_comp.set_text(unreal.Text(f"[{art['type']}] {art['name']} ({art['size_kb']} KB)"))
            t_comp.set_world_size(9.0)
            t_comp.set_horizontal_alignment(unreal.HorizTextAligment.EHTA_CENTER)

        label.attach_to_actor(shard, unreal.Name("None"), unreal.AttachmentRule.KEEP_WORLD, unreal.AttachmentRule.KEEP_WORLD, unreal.AttachmentRule.KEEP_WORLD, False)
        unreal.log(f"  [>] Цел: {art['name']} -> Готова за избор.")

def interact_with_node(node_label):
    """Извиква се при клик върху StorageNode диск от BP_operator"""
    unreal.log(f"=== [ArtifactManager] Взаимодействие с възел: {node_label} ===")
    subsystem = unreal.get_editor_subsystem(unreal.EditorActorSubsystem)
    target_actor = None
    for a in subsystem.get_all_level_actors():
        if a.get_actor_label() == str(node_label):
            target_actor = a
            break

    if not target_actor:
        unreal.log_warning(f"[ArtifactManager] Не е намерен актьор с етикет '{node_label}'")
        return

    # Проверка дали актьорът е StorageNode
    if not target_actor.actor_has_tag("StorageNode"):
        unreal.log(f"[ArtifactManager] Актьорът '{node_label}' няма таг 'StorageNode', пропускане.")
        return

    # Намиране на съответния mount point
    try:
        import DriveSpawner
        drives = DriveSpawner.inspect_hardware_storage()
    except Exception as e:
        drives = []
        unreal.log_warning(f"[ArtifactManager] Грешка при четене на дискове: {e}")

    mount_path = "/"
    for idx, d in enumerate(drives):
        if f"Blade_{d['hw_class']}_{idx}" == node_label:
            mount_path = d['mount']
            break
        elif node_label in d['mount']:
            mount_path = d['mount']
            break

    unreal.log(f"[ArtifactManager] Стартиране на сканиране за {node_label} ({mount_path})...")
    deploy_artifacts_above_cartridge(target_actor, mount_path)