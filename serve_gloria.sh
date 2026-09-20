#!/bin/sh
# serve_gloria.sh – local development server for the Gloria playground.
# Requires ciao-serve-mt or falls back to Python http.server.

cd /home/jacinto/git/gloria

# Try ciao-serve-mt first (bundled with ciao_playground; handles wasm loading better)
if command -v ciao-serve-mt >/dev/null 2>&1; then
  echo "Starting ciao-serve-mt on port 8000 serving the playground..."
  ciao-serve-mt -port 8000 playground/
  echo "Open http://localhost:8000/playground/gloria.html in your browser"
else
  echo "cii-serve-mt not found, falling back to Python http.server..."
  # Find python
  for py in python3 python; do
    if command -v $py >/dev/null 2>&1; then
      echo "Starting Python HTTP server on port 8000..."
      cd playground
      $py -m http.server 8000 --directory ./
      echo "Open http://localhost:8000/playground/gloria.html in your browser"
      break
    fi
  done
  if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
    echo "Neither Python nor ciao-serve-mt available. Please start a static server manually:"
    echo "  cd /home/jacinto/git/gloria/playground && python -m http.server 8000"
    echo "Then open http://localhost:8000/playground/gloria.html"
  fi
fi