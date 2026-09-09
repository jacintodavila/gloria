#!/usr/bin/env python3
import yaml, json, subprocess, pathlib, sys, importlib, re

def load_pipeline(path):
    with open(path) as f:
        return yaml.safe_load(f)["pipeline"]

def load_agent(agent_name):
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', agent_name)
    module_name = 'agents.' + re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()
    module = importlib.import_module(module_name)
    return getattr(module, agent_name)

def exec_step(step, state):
    print(f"Executing step: {step['name']}")
    agent_cls = load_agent(step['agent'])
    agent = agent_cls()
    inputs = {"files": [str(p) for p in pathlib.Path('.').glob(step['inputs'][0]['path'])]}
    outputs = {"files": [str(p) for p in pathlib.Path('.').glob(o['path'])] for o in step.get('outputs', [])}
    task = {"inputs": inputs, "outputs": outputs, "config": step.get("config", {})}
    try:
        result = agent.run(task)
    except NotImplementedError:
        print(f"Step {step['name']} not implemented yet.")
        return state, "skipped"
    if result.get("status") != "ok":
        raise RuntimeError(f"Step {step['name']} failed: {result.get('msg')}")
    state[step["name"]] = {"status": "ok", "outputs": result.get("outputs", {})}
    return state, "ok"

def main():
    pipeline = load_pipeline("pipeline.yaml")
    state = {}
    for step in pipeline:
        deps_ok = all(state.get(dep, {}).get("status") == "ok" for dep in step.get("depends_on", []))
        if not deps_ok:
            print(f"Dependency not satisfied for {step['name']}. Skipping.")
            continue
        state, status = exec_step(step, state)
        pathlib.Path("pipeline_state.json").write_text(json.dumps(state, indent=2))
    print("✅ Pipeline execution finished.")

if __name__ == "__main__":
    main()
