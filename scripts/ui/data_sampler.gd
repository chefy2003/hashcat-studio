class_name DataSampler
extends RefCounted

## Dynamic Operator Data Sampling Engine.
## Samples target wordlist inputs and simulates rule transformations live in the UI.

static func sample_wordlist_file(file_path: String, max_samples: int = 5) -> Array[String]:
    var samples: Array[String] = []
    if file_path.is_empty() or not FileAccess.file_exists(file_path):
        return _get_default_samples()

    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return _get_default_samples()

    var count: int = 0
    while not file.eof_reached() and count < max_samples:
        var line: String = file.get_line().strip_edges()
        if not line.is_empty():
            samples.append(line)
            count += 1
    file.close()

    if samples.is_empty():
        return _get_default_samples()
    return samples

static func simulate_rule_transformation(sample_word: String, rule_cmd: String) -> String:
    if rule_cmd.is_empty():
        return sample_word

    var result: String = sample_word
    # Simple rule parser simulation for key Hashcat rules:
    # 'l' (lowercase), 'u' (uppercase), 'c' (capitalize), '$x' (append x), '^x' (prepend x), 'r' (reverse)
    var i: int = 0
    while i < rule_cmd.length():
        var char_cmd: String = rule_cmd[i]
        match char_cmd:
            "l":
                result = result.to_lower()
            "u":
                result = result.to_upper()
            "c":
                result = result.capitalize()
            "r":
                var reversed_chars: Array[String] = []
                for j in range(result.length() - 1, -1, -1):
                    reversed_chars.append(result[j])
                result = "".join(reversed_chars)
            "$":
                if i + 1 < rule_cmd.length():
                    result += rule_cmd[i + 1]
                    i += 1
            "^":
                if i + 1 < rule_cmd.length():
                    result = rule_cmd[i + 1] + result
                    i += 1
        i += 1

    return result

static func _get_default_samples() -> Array[String]:
    return ["admin", "password", "company2024", "letmein", "operator"]
