# Dotfiles Hub V2 - Internal Function Map (func.md)

This file documents the internal logic flows for complex Hub functions.

## 1. Selective Input Parser (Removal Menu)
The logic used in `target_bundle_remove_menu` to process human selection strings.

```text
[ HUMAN INPUT: "1-3,5" ]
    │
    ▼
[ 1. Split by Comma ] ──────▶ [ "1-3", "5" ]
    │
    ▼
[ 2. Range Check ]
    │
    ├── Contains "-"? ──▶ [ 3. Range Expansion ] ──▶ [ 1, 2, 3 ]
    │
    └── Single Digit? ──▶ [ 4. Direct Selection ] ──▶ [ 5 ]
    │
    ▼
[ 5. Valid Number Check ] ──▶ [[ $num =~ ^[0-9]+$ ]]
    │
    ▼
[ 6. Key Mapping ]
    │
    └── [ 1 ] ──▶ [ "hyprland" ]
    └── [ 2 ] ──▶ [ "waybar" ]
    └── [ 3 ] ──▶ [ "quickshell" ]
    └── [ 5 ] ──▶ [ "fastfetch" ]
    │
    ▼
[ 7. File System Action ] ──▶ rm -rf "$bundles_dir/$target_bundle/$folder"
```

## 2. Dynamic Scoping & Shadowing (Dashboard)
How the `dashboard` function isolates its scan from the global state.

```text
[ Global State ] ────▶ [ target_bundle="1.0.0" ]
    │
    ▼
[ dashboard() ] ─────▶ [ local target_bundle ] (SHADOW CREATED)
    │
    ├── Loop 1: "0.0.1" ─▶ target_bundle="0.0.1" (Shadow updated)
    │                        └─▶ Worker functions use Shadow
    │
    ├── Loop 2: "vNext" ─▶ target_bundle="vNext" (Shadow updated)
    │                        └─▶ Worker functions use Shadow
    │
    ▼
[ Function Ends ] ───▶ [ Shadow Destroyed ]
    │
    ▼
[ Return to Menu ] ──▶ [ target_bundle="1.0.0" ] (Global Restored)
```

## 3. Discovery Pipeline
```text
[ init() ]
    │
    ├── [ fetch_latest_versions & ] ──▶ Background process
    │      └─▶ git ls-remote ──▶ /tmp/key.version
    │
    └── [ list_bundles() ]
           └─▶ [ wait_pid ] ──▶ Blocks until background finishes
           └─▶ [ collect_web_versions ] ──▶ Reads /tmp into memory
```
