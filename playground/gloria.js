// Gloria Playground JavaScript
// This file is loaded after the HTML and provides the app logic.
// Configuration is set via window.playgroundCfg and window.toplevelCfg in gloria.html.

// Helper: check if config already exists (for modular loading)
if (typeof window.playgroundCfg === 'undefined') {
  window.playgroundCfg = {
    title: "playground for Gloria reactive agents",
    window_layout: ['E','T','P'],
    storage_key: 'code_gloria',
    splash_code: '',
    example_list: [],
    has_run_tests_button: false,
    has_doc_button: false,
  };
}

// Helper: check if toplevel config already exists
if (typeof window.toplevelCfg === 'undefined') {
  window.toplevelCfg = {
    special_query: { "load": { read_code: true } },
    init_bundles: ['ciaowasm', 'core', 'builder'],
    init_queries: [],
    custom_load_query: m => "load('" + m + "')",
    custom_run_query: q => q,
    custom_postprint_sol: () => {},
  };
}

// Placeholder: step the simulation
function runGloriaStep() {
  // Will be connected to the wasm runtime
  console.log("runGloriaStep called – connect to wasm runtime");
}

// Placeholder: reset the clock
function resetGloriaClock() {
  console.log("resetGloriaClock called – connect to wasm runtime");
}

// Placeholder: load an agent
function loadGloriaAgent(agentDir) {
  console.log("loadGloriaAgent('" + agentDir + "') called – connect to wasm runtime");
}

// Expose for HTML onclick attributes
window.runGloriaStep = runGloriaStep;
window.resetGloriaClock = resetGloriaClock;
window.loadGloriaAgent = loadGloriaAgent;