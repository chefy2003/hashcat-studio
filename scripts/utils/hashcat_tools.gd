class_name HashcatTools
extends RefCounted

## Utility Suite for Search Space Calculation, Potfile Inspection, and Benchmarking.

static func calculate_mask_search_space(mask_pattern: String) -> int:
    if mask_pattern.is_empty():
        return 0

    var charsets: Dictionary = {
        "?l": 26, # lowercase
        "?u": 26, # uppercase
        "?d": 10, # digits
        "?s": 33, # special chars
        "?a": 95, # all printable ASCII
        "?b": 256 # binary bytes
    }

    var total_combinations: int = 1
    var i: int = 0
    while i < mask_pattern.length():
        if mask_pattern[i] == "?" and i + 1 < mask_pattern.length():
            var spec: String = "?" + mask_pattern[i + 1]
            var count: int = charsets.get(spec, 1)
            total_combinations *= count
            i += 2
        else:
            total_combinations *= 1
            i += 1

    return total_combinations

static func calculate_dictionary_search_space(wordlist_size: int, rule_count: int = 1) -> int:
    if wordlist_size <= 0:
        return 0
    if rule_count <= 0:
        rule_count = 1
    return wordlist_size * rule_count

static func format_search_space_human(total: int) -> String:
    if total < 1000:
        return str(total) + " candidates"
    elif total < 1_000_000:
        return str(snapped(float(total) / 1000.0, 0.01)) + " Thousand"
    elif total < 1_000_000_000:
        return str(snapped(float(total) / 1_000_000.0, 0.01)) + " Million"
    elif total < 1_000_000_000_000:
        return str(snapped(float(total) / 1_000_000_000.0, 0.01)) + " Billion"
    else:
        return str(snapped(float(total) / 1_000_000_000_000.0, 0.01)) + " Trillion"
