## Compile and run all examples sequentially for visual verification.
## Close each window to proceed to the next example.

import std/[osproc, os, strformat]

const examples = [
  "basicwindow",
  "calculator",
  "gameplayer",
  "menu",
  "panels",
  "the7gui",
]

proc main() =
  let rootDir = currentSourcePath().parentDir.parentDir
  let examplesDir = rootDir / "examples"

  echo "=== Silky Examples Runner ==="
  echo "Compiling and running each example."
  echo "Close each window to proceed to the next example.\n"

  for i, name in examples:
    let exampleDir = examplesDir / name
    let nimFile = name & ".nim"
    
    echo fmt"[{i + 1}/{examples.len}] Compiling and running: {name}"
    
    # Change to example directory so it can find its data folder
    setCurrentDir(exampleDir)
    
    let exitCode = execCmd(fmt"nim r {nimFile}")
    if exitCode != 0:
      echo fmt"  ERROR: {name} failed with exit code {exitCode}"
      quit(exitCode)
    echo ""

  echo "=== All examples completed ==="

when isMainModule:
  main()
