#version 450

layout(location = 0) in vec2 inPos;
layout(location = 1) in vec2 inUv;
layout(location = 2) in vec4 inColor;
layout(location = 3) in vec2 inClipPos;
layout(location = 4) in vec2 inClipSize;

layout(location = 0) out vec2 fragUv;
layout(location = 1) out vec4 fragColor;
layout(location = 2) out vec2 fragClipPos;
layout(location = 3) out vec2 fragClipSize;
layout(location = 4) out vec2 fragPos;

layout(push_constant) uniform PushConstants {
  vec2 viewportSize;
} pc;

void main() {
  gl_Position = vec4(inPos, 0.0, 1.0);
  fragUv = inUv;
  fragColor = inColor;
  fragClipPos = inClipPos;
  fragClipSize = inClipSize;
  // Recover pixel position from NDC for clip-rect testing
  fragPos = vec2(
    (inPos.x * 0.5 + 0.5) * pc.viewportSize.x,
    (0.5 - inPos.y * 0.5) * pc.viewportSize.y
  );
}
