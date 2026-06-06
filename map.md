# Dotfiles Hub V2 - Execution & Orchestration Map

This map reflects the **actual current state** of the codebase as of June 2026.

## 1. Hub Entry Tree (main.sh)
Maps how `main.sh` handles incoming CLI arguments.

```text
[CLI CALL: ./main.sh]
    │
    ├── (no args) ─────────▶ [ init() ] ────────▶ [ main_menu() ]
    │                                                 │
    │                                                 └─▶ Interactive TUI/CLI
    │
    ├── "bundles" ─────────▶ [ init() ] ────────▶ [ echo_bundle_versions ]
    │                                                 │
    │                                                 └─▶ OUT: "v1.0.0:1.1.0"
    │
    ├── "install" ─────────▶ [ init() ] ────────▶ [ Placeholder Case ]
    │                                                 │
    │                                                 └─▶ OUT: (No action)
    │
    ├── "force" ───────────▶ [ init() ] ────────▶ [ Placeholder Case ]
    │                                                 │
    │                                                 └─▶ OUT: (No action)
    │
    └── "check-update" ────▶ [ init() ] ────────▶ [ echo string ]
                                                      │
                                                      └─▶ OUT: "will return if..."
```

## 2. Install Mode Expansion Tree
Maps how the Hub's internal state expects to influence deployment.

```text
[ $install_mode ]
    │
    ├── "rookie" (Default) ─▶ [ Logic: Backup -> Install ]
    │                            │
    │                            └─▶ STATUS: Active in Hub Logic
    │
    ├── "force" ────────────▶ [ Logic: Overwrite ]
    │                            │
    │                            └─▶ STATUS: Selectable in Menu
    │
    └── "interactive" ──────▶ [ Logic: Prompt for each ]
                                 │
                                 └─▶ STATUS: Fully Implemented in deploy loop
```

## 3. Leaf Installer Interface Mapping
The "contract" between the Hub and independent Rice repositories.

```text
[ HUB (main.sh) ] ──▶ (Arrows IN) ──▶ [ LEAF (installer.sh) ] ──▶ (Arrows OUT) ──▶ [ SYSTEM ]
  │                                        │                                       │
  ├─▶ $1 (install_mode) ───[MISSING]───────┤                                       │
  │     (Logic exists but NOT passed)      │                                       │
  │                                        │                                       │
  ├─▶ PWD (vault_path) ───[ACTIVE]─────────┤                                       │
  │     (Hub cd's before running)          │                                       │
  │                                        │                                       │
  │                                        ├─▶ Logic: Handle $1 ───────────────────┤
  │                                        │                                       │
  │                                        ├─▶ Action: Apply Configs ─────────────▶┤
  │                                        │                                       │
  │                                        └─▶ Artifact: .version ────────────────▶┘
  │                                                                                │
  └─▶ (Detection) ◀───[ [ OK ] / [DIFF] ]─── [ Hub reads .version from HOME ] ─────┘
```

---

## 4. Leaf Installer Tree (../dotfile/installer.sh)
Maps how the independent Rice installer handles the passed `$1` argument.

```text
[CLI CALL: ./installer.sh (Leaf)]
    │
    ├── "rookie" ─────────▶ [ backup_logic() ] ─────▶ [ deploy_configs() ]
    │                                                   │
    │                                                   └─▶ OUT: New Configs + .version
    │
    ├── "force" ──────────▶ [ delete_logic() ] ─────▶ [ deploy_configs() ]
    │                                                   │
    │                                                   └─▶ OUT: Forced Overwrite
    │
    └── "interactive" ────▶ [ prompt_logic() ] ─────▶ [ deploy_configs() ]
                                                        │
                                                        └─▶ OUT: User-Approved Configs
```

### **Leaf Installer Argument Logic**
| Arg ($1) | Expectancy (Input) | Outcome (Actual Behavior) |
| :--- | :--- | :--- |
| **`rookie`** | Safe deployment. | Renames existing config to `.bak` before copying. |
| **`force`** | Aggressive deployment. | `rm -rf` existing config path then copies new files. |
| **`interactive`** | Controlled deployment. | Loops through every file with `read -p` confirmation. |

---

## 5. Verbose Argument Expectancy & Outcome (General)

### **A. main.sh Arguments**
| Arg | Expectancy (Input) | Outcome (Actual Behavior) |
| :--- | :--- | :--- |
| **`bundles`** | Expects `matrix.txt` to exist. | Prints `:` separated list of versions. |
| **`install`** | Expects automated deployment. | **FAIL**: Currently a commented-out placeholder. |
| **`check-update`** | Expects GitHub tag comparison. | **FAIL**: Currently just prints a "will return" string. |

### **B. Hub -> Leaf Communication**
| Channel | Expectancy (Input) | Outcome (Actual Behavior) |
| :--- | :--- | :--- |
| **`$1`** | Expects `rookie`, `force`, or `interactive`. | **FAIL**: Hub currently calls `./installer.sh` without args. |
| **`PWD`** | Expects to be in the component folder. | **SUCCESS**: Hub uses `(cd ...; ./script)` correctly. |
