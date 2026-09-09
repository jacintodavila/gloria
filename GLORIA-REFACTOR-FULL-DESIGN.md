# Gloria Refactor & Agentic Platform Design

This document provides the comprehensive design for refactoring the Gloria codebase, including the rationale, phased plan, and the architecture of the Agentic Refactor Platform (based on ADK) used to execute this plan safely.

---

## 1. Context and Rationale

Gloria is a legacy BDI-style reactive planning agent research artifact written in SWI-Prolog (pre-2010s style). The codebase is powerful but difficult to maintain due to several critical technical debt issues:

- **No Module System**: Global namespace collisions.
- **Dead Code**: Abandoned experiments mixed with live logic.
- **Silent Failures**: Use of `not/1` and cuts for control flow.
- **Tightly Coupled I/O**: The planning core is inseparable from terminal I/O and global state.
- **Testing Gap**: Lack of automated tests for the reasoning engine.

The goal of this refactor is to **preserve the logic while making the codebase legible, testable, and safe to change.**

---

## 2. Phased Remediation Roadmap

The refactor follows a low-risk, incremental approach:

### Phase 0 — Safety Net
- **Goal**: Establish a baseline for correctness.
- **Actions**:
    - Ensure clean loading on modern SWI-Prolog.
    - Write characterization tests: Run existing `examples/*.g` agents and snapshot output.
    - Add `plunit` tests for pure, side-effect-free predicates.

### Phase 1 — Modularize
- **Goal**: Surface dependencies and isolate components.
- **Actions**:
    - Wrap each file in a proper SWI module (`:- module(...)`).
    - Replace `not/1` with `\+/1`.
    - Cleanup dead/commented-out code.

### Phase 2 — Separate Engine from I/O
- **Goal**: Make the reasoning core testable.
- **Actions**:
    - Extract `read/write` calls behind a minimal IO-strategy interface (`agent_input/1`, `agent_output/2`).
    - Isolate global state management.

### Phase 3 — Core Representation
- **Goal**: Formalize the internal data structure.
- **Actions**:
    - Document the `[Delta, UC, CN, HF, M]` tuple formally.
    - Introduce accessor predicates.
    - Triage TODOs/backlog.

### Phase 4 — Performance & Correctness
- **Goal**: Optimize and harden the reasoning engine.
- **Actions**:
    - Audit linear scan performance (`contain/2`, etc.).
    - Audit cuts and backtracking logic.

---

## 3. Agentic Refactor Platform Design

To execute the refactor safely and reliably, we use an agentic platform governed by a **Micro-Control Plane (MCP)**.

### Platform Components
- **MCP Orchestrator**: A stateful controller that manages dependencies, snapshots, and rollbacks for each pipeline step defined in `pipeline.yaml`.
- **Secure Agents**: Each refactor phase is performed by an `ADK`-based agent inheriting from a `SecureAgent` base class.

### Risk Mitigation Mechanisms (built into the platform)
- **Atomic Edit Verification**: Agents verify file modifications after editing.
- **Idempotency**: Agents check if a change is already applied before running.
- **Snapshots & Rollback**: Orchestrator takes filesystem snapshots (via git) before high-risk steps and reverts on failure.
- **Human-in-the-Loop (HITL)**: High-risk steps (e.g., modularization) require manual approval via `pending_review.patch` files.
- **Dual-Run Validation**: Compare execution traces between original and refactored code to ensure semantic equivalence.
- **Dry-Run Mode**: Validate the pipeline logic without applying changes.

### Platform Architecture

```yaml
# Simplified Pipeline Schema
pipeline:
  - name: step_name
    agent: AgentClassName
    requires_approval: bool
    optional: bool
    depends_on: [list_of_steps]
```

### Base SecureAgent Class

```python
class SecureAgent(Agent):
    def safe_edit(self, filePath, old, new):
        # 1. Idempotency Check
        # 2. Local Snapshot
        # 3. Edit
        # 4. Verification Check
        # 5. Rollback on failure
```

---

## 4. Execution Workflow

1. **Pipeline Analysis**: Orchestrator parses `pipeline.yaml`.
2. **Snapshot**: System takes a git snapshot.
3. **Agent Execution**: Agent applies changes to the filesystem.
4. **Verification**: Platform validates file changes and semantic parity (dual-run).
5. **Finalize**: If all checks pass, finalize the changes.
6. **Failure Recovery**: On any check failure, roll back to the last snapshot and halt.
