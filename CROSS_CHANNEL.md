# Cross-channel compatibility contract

Evangelion Rice supports three distribution channels: the standalone Omarchy
theme, the complete tagged suite archive, and the Arch package with explicit
per-user activation. A Git checkout is a development source for the same suite
transaction, not a fourth ownership tier. MAGI plugins are suite-internal.

## Transitions

| From | To | Required transition |
|---|---|---|
| Theme | Suite/archive/Arch activation | Switch away, remove the Git theme clone, then run the suite plan |
| Git suite | Tagged archive | Apply as a new suite transaction; rollback restores the prior payload |
| Tagged archive | Arch | Roll back/deactivate user state, install package, then explicitly activate |
| Arch | Git/archive | Deactivate, remove the pacman package, then apply the chosen suite source |

The installer refuses a Git-owned standalone theme tree before preflight or any
mutation. It never combines ownership models in place. Pacman never mutates a
home directory, and removing a system package never guesses how to clean up a
user transaction.

## Regression evidence

`tests/cross-channel.py` produces `test-results/cross-channel.json`. It records
channel versions, ownership boundaries, transition outcomes, and these gates:

- theme-only export/install/update/removal remains independent;
- suite install and exact v1.3 upgrade remain transactional;
- release archives retain their allowlist and checksum contract;
- Arch package and activation ownership remain separate;
- theme/suite overlap is detected without mutation;
- a forced partial activation restores the previous state;
- internal plugins and the optional MAGI runtime are not standalone products;
- browser selection remains XDG-default based;
- full/reduced/off motion, privacy boundaries, and responsive layouts retain
  their existing regression contracts;
- Omarchy compatibility is capability-based and optional MAGI integration
  falls back safely when absent, stale, malformed, or incompatible.

The JSON report is retained by CI. A distribution ticket is complete only when
the pushed commit's required CI run finishes successfully.
