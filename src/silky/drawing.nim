when defined(windyDirectX):
  import silky/dx12_drawing
  export dx12_drawing
else:
  import silky/opengl_drawing
  export opengl_drawing
