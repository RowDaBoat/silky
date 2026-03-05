## Tests for atlas JSON embedded inside PNG files.

import
  std/[os, tables],
  pixie,
  silky/atlas

proc assertRaisesMissingChunk(path: string) =
  ## Asserts that reading metadata fails when chunk is missing.
  var raised = false
  try:
    discard extractAtlasJsonFromPng(readFile(path))
  except SilkyAtlasError:
    raised = true
  doAssert raised, "Expected missing atlas metadata exception"

block:
  echo "Testing atlas builder single-file PNG output"
  let
    outputPath = "tests/dist/atlas_embedded.png"
    builder = newAtlasBuilder(64, 2)
  builder.write(outputPath)
  let loadedAtlasData = readAtlas(outputPath)
  doAssert loadedAtlasData.atlas != nil
  doAssert WhiteTileKey in loadedAtlasData.atlas.entries
  doAssert loadedAtlasData.image.width == builder.size
  doAssert loadedAtlasData.image.height == builder.size

block:
  echo "Testing direct writePng and metadata roundtrip"
  let
    path = "tests/dist/atlas_custom_chunk.png"
    json = """{"tag":"hello","count":3}"""
    image = newImage(8, 8)
  image.fill(color(1, 0, 0, 1))
  writePng(path, json, image)
  let extracted = extractAtlasJsonFromPng(readFile(path))
  doAssert extracted == json
  let decoded = readImage(path)
  doAssert decoded.width == 8
  doAssert decoded.height == 8

block:
  echo "Testing failure when metadata chunk is missing"
  let
    path = "tests/dist/plain.png"
    image = newImage(4, 4)
  image.fill(color(0, 1, 0, 1))
  createDir(path.splitPath().head)
  image.writeFile(path)
  assertRaisesMissingChunk(path)

echo "All atlas PNG tests passed."
