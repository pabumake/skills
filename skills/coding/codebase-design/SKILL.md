---
name: codebase-design
description: Design or improve module interfaces, seams, adapters, and testability while hiding complexity behind small interfaces. Use for architecture, module boundaries, dependency placement, refactoring structure, or comparing interface designs.
metadata:
  origin: "https://github.com/mattpocock/skills/tree/5b15a47f2d7150f545fbcacbfe381787fc0230dc/skills/engineering/codebase-design"
  source_commit: "5b15a47f2d7150f545fbcacbfe381787fc0230dc"
  license: "MIT"
---

# Codebase design

Design deep modules: substantial behavior behind a small interface at a clean seam. The interface includes types, invariants, ordering, error modes, configuration, and performance facts a caller must know.

Use these terms consistently:

- **Module:** an interface plus its implementation, at any scale.
- **Seam:** a location where behavior can vary without editing the caller.
- **Adapter:** an implementation that fills a seam.
- **Depth:** how much useful behavior callers gain for how little interface they must learn.
- **Locality:** how well change, bugs, knowledge, and verification stay in one place.

## Design checks

- Reduce methods, parameters, modes, ordering rules, and caller setup.
- Hide policy and coordination inside the module instead of spreading them across callers.
- Apply the deletion test. A useful module's removal would push complexity into several callers. If its removal deletes complexity, it was probably pass-through code.
- Let callers and tests use the same interface. Pressure to test behind it signals a poor seam or interface.
- Accept external dependencies and return results where practical.
- Introduce an adapter seam when behavior truly varies. One implementation alone rarely justifies a new abstraction.
- Replace a shallow module when deepening it. Do not leave both layers in place.

For consequential interfaces, produce at least two meaningfully different designs. Compare interface size, hidden complexity, locality, failure behavior, testability, and migration cost before recommending one. Do not change the code during a design-only request.
