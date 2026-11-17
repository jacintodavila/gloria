import subprocess
import json

def run_test():
    proc = subprocess.Popen(
        ["swipl", "-q", "-s", "web/mcp/runner.pl", "-g", "main", "-t", "halt"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1
    )
    
    # Send a request
    # Need to send JSON per line
    request = {"cmd": "run_step", "agent": "emergencia", "input": "[emergencia]", "session": "ses1"}
    proc.stdin.write(json.dumps(request) + "\n")
    proc.stdin.flush()
    
    reply = proc.stdout.readline()
    print(f"Reply: {reply}")
    
    proc.stdin.write(json.dumps({"cmd": "quit"}) + "\n")
    proc.stdin.flush()
    proc.wait()

run_test()
