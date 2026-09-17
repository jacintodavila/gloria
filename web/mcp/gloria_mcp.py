"""Gloria MCP server.

Exposes Gloria's reactive agents (enclosure, burocratin, gerente, arch, ...)
to MCP clients such as opencode.  Each agent is a goal-directed reactive
reasoner written in Prolog; this server brokers a single long-lived SWI-Prolog
worker (web/mcp/runner.pl) that loads one agent at a time into the Prolog
`user` module, runs one reasoning step, and returns the set of actions it
issued at that time step.

Run directly:

    .venv/bin/python web/mcp/gloria_mcp.py

and register it in opencode.json as a local MCP server, see README.md.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import threading
import time

from mcp.server.mcpserver import MCPServer

HERE = os.path.dirname(os.path.abspath(__file__))
RUNNER = os.path.join(HERE, "runner.pl")
GITROOT = os.path.dirname(os.path.dirname(HERE))
SWIPL = os.environ.get("SWIPL", "swipl")


class GloriaWorker:
    """Persistent GLORIA runner process speaking a JSON-lines protocol."""

    def __init__(self) -> None:
        self._proc: subprocess.Popen[str] | None = None
        self._lock = threading.Lock()
        self._last_trace: list[str] = []
        self._started_proc: subprocess.Popen[str] | None = None

    # -- process lifecycle ------------------------------------------------

    @property
    def proc(self) -> subprocess.Popen[str]:
        if self._proc is None or self._proc.poll() is not None:
            self._start()
        assert self._proc is not None
        return self._proc

    def _start(self) -> None:
        self._proc = subprocess.Popen(
            [SWIPL, "-q", "-s", RUNNER, "-g", "main", "-t", "halt"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=GITROOT,
            text=True,
            bufsize=1,
        )
        self._started_proc = self._proc
        self._last_trace = []
        threading.Thread(
            target=self._drain_stderr, args=(self._proc,), daemon=True
        ).start()
        self._warmup()

    def _warmup(self) -> None:
        # Loading gloria.pl emits a few warnings on stderr.  Consume them with
        # a throwaway ping so they do not leak into the first tool's trace.
        proc = self._proc
        assert proc is not None and proc.stdin is not None and proc.stdout is not None
        try:
            proc.stdin.write(json.dumps({"cmd": "ping"}) + "\n")
            proc.stdin.flush()
            proc.stdout.readline()
            self._settle_trace()
        except Exception:
            pass
        self._last_trace = []

    def _drain_stderr(self, proc: subprocess.Popen[str]) -> None:
        assert proc.stderr is not None
        for line in proc.stderr:
            line = line.rstrip("\n")
            if self._started_proc is proc:
                self._last_trace.append(line)

    def stop(self) -> None:
        if self._proc is not None and self._proc.poll() is None:
            try:
                self._send_one({"cmd": "quit"})
            except Exception:
                pass
            self._proc.terminate()
        self._proc = None

    # -- protocol ---------------------------------------------------------

    def _send_one(self, request: dict) -> dict:
        proc = self.proc
        assert proc.stdin is not None and proc.stdout is not None
        with self._lock:
            self._last_trace = []
            proc.stdin.write(json.dumps(request) + "\n")
            proc.stdin.flush()
            line = proc.stdout.readline()
            if line == "":
                raise RuntimeError(
                    "GLORIA worker closed its stdout; is `swipl` on PATH?"
                )
            reply = json.loads(line)
            # The runner flushes its trace (user_error) before writing the
            # reply, but the draining thread may not have caught up yet.  Let
            # it settle briefly so `trace` is complete.
            self._settle_trace()
        if not reply.get("ok"):
            raise RuntimeError(reply.get("error", "unknown GLORIA error"))
        return reply

    def _settle_trace(self) -> None:
        deadline = time.monotonic() + 0.5
        previous = len(self._last_trace)
        stable = 0
        while time.monotonic() < deadline:
            time.sleep(0.02)
            current = len(self._last_trace)
            if current == previous:
                stable += 1
                if stable >= 2:
                    break
            else:
                stable = 0
                previous = current

    def list_agents(self) -> list[str]:
        return self._send_one({"cmd": "list_agents"})["agents"]

    def agent_info(self, agent: str) -> dict:
        return self._send_one({"cmd": "agent_info", "agent": agent})["info"]

    def run_step(self, agent: str, inputs: str, session: str) -> dict:
        reply = self._send_one(
            {"cmd": "run_step", "agent": agent, "input": inputs, "session": session}
        )
        return {
            "actions": reply.get("actions", []),
            "time": reply.get("time", 0),
            "next_time": reply.get("next_time", 0),
            "session": reply.get("session", session),
            "trace": list(self._last_trace),
        }

    def reset(self, agent: str, session: str) -> dict:
        reply = self._send_one({"cmd": "reset", "agent": agent, "session": session})
        return {"reset": reply.get("reset"), "session": reply.get("session")}


_worker = GloriaWorker()


def gloria_list_agents() -> list[str]:
    """List the names of the Gloria agents available in examples/."""
    return _worker.list_agents()


def gloria_agent_info(agent: str) -> dict:
    """Describe a Gloria agent: its TITLE, goals, beliefs, observables and
    abducibles, extracted from its .main/.kb source files."""
    return _worker.agent_info(agent)


def gloria_run_step(agent: str, input: str, session: str = "default") -> dict:
    """Run one reasoning step of `agent` at time T with the given `input`
    observations (a Prolog term, e.g. "[time_day(am), it_is(sunny)]").

    Returns the actions the agent issued (as Prolog terms), the current and
    next time, and the reasoning trace.  Use `session` to give the agent
    continuity between steps."""
    return _worker.run_step(agent, input, session)


def gloria_reset(agent: str = "_all_", session: str = "default") -> dict:
    """Forget the internal clock for one agent/session (or all if agent is
    '_all_'), so the next run_step restarts at time 0."""
    return _worker.reset(agent, session)


def main() -> None:
    server = MCPServer(
        name="gloria",
        title="Gloria Agent Reasoner",
        version="0.1.0",
        instructions=(
            "Gloria is a goal-directed reactive agent reasoner.  Use "
            "gloria_list_agents to discover agents, gloria_agent_info to learn "
            "an agent's goals/observables/abducibles, gloria_run_step to make "
            "the agent reason for one time step given observations, and "
            "gloria_reset to clear a session's clock."
        ),
    )
    server.add_tool(
        gloria_list_agents,
        name="gloria_list_agents",
        title="List Gloria agents",
        description="List the names of the Gloria agents available in examples/.",
    )
    server.add_tool(
        gloria_agent_info,
        name="gloria_agent_info",
        title="Describe a Gloria agent",
        description=(
            "Describe a Gloria agent: its TITLE, goals, beliefs, observables "
            "and abducibles, extracted from its .main/.kb source files."
        ),
    )
    server.add_tool(
        gloria_run_step,
        name="gloria_run_step",
        title="Run one Gloria reasoning step",
        description=(
            "Run one reasoning step of `agent` at time T given `input` "
            "observations (a Prolog term list). Returns the actions issued, "
            "current/next time, and the reasoning trace."
        ),
    )
    server.add_tool(
        gloria_reset,
        name="gloria_reset",
        title="Reset a Gloria session",
        description=(
            "Forget the internal clock for one agent/session (or all agents if "
            "agent is '_all_'), so the next run_step restarts at time 0."
        ),
    )

    try:
        server.run(transport="stdio")
    finally:
        _worker.stop()


if __name__ == "__main__":
    main()