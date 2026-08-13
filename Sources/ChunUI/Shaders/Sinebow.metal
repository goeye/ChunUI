//
// Sinebow.metal
// Inferno
// https://www.github.com/twostraws/Inferno
// See LICENSE for license information.
//

#include <metal_stdlib>
using namespace metal;

/// A shader that generates multiple twisted rotating lines with cycling colors.
///
/// How it works:
/// 1. Calculates each pixel's distance to 10 lines
/// 2. Each line has unique position changes based on different sine waves
/// 3. Background is fixed pink color
/// 4. Lines are pure white, creating bright contrast on pink background
/// 5. Uses multiple layers of sine waves for complex wavy motion
/// 6. Time parameter creates continuous animation
/// 7. Lines move quickly for more dynamic effect
///
/// - Parameter position: Current pixel's user space coordinate
/// - Parameter color: Current pixel color
/// - Parameter size: Total image size in user space
/// - Parameter time: Seconds since shader creation
/// - Returns: New pixel color
[[ stitchable ]] half4 sinebow(float2 position, half4 color, float2 size, float time) {
    // Calculate aspect ratio
    half aspectRatio = size.x / size.y;

    // Calculate UV space coordinates, range from -1 to 1
    half2 uv = half2(position / size.x) * 2.0h - 1.0h;

    // Ensure effect looks similar regardless of aspect ratio
    uv.x /= aspectRatio;

    // Calculate overall wave motion - increased frequency and speed
    half wave = sin(uv.x * 2.0h + time * 2.5h);

    // Square the wave and multiply by larger value
    // Makes peaks and troughs more pronounced
    wave *= wave * 150.0h;

    // Fixed pink background
    // Pink: RGB(1.0, 0.7, 0.9)
    half3 backgroundColor = half3(1.0h, 0.7h, 0.9h);

    // Initialize wave color as background color
    half3 waveColor = backgroundColor;

    // Create 10 lines total
    for (int i = 0; i < 10; i++) {
        // Calculate each pixel's distance to line, larger value = closer to line
        half luma = abs(1.0h / (80.0h * uv.y + wave));

        // Calculate each line's unique second sine wave (wave within wave effect)
        // Increased time coefficient and amplitude for more dramatic movement
        half y = sin(uv.x * sin(time * 2.0h) * 1.5h + half(i) * 0.3h + time * 2.5h);

        // Increase offset for larger wave amplitude
        uv.y += 0.1h * y;

        // Calculate line intensity - using exponential function for sharper lines
        half lineIntensity = pow(luma, 1.8h) * 1.5h;
        lineIntensity = min(lineIntensity, 1.0h);

        // Pure white lines
        half3 lineColor = half3(1.0h, 1.0h, 1.0h);

        // Add line color to current wave color
        // Only add color at line positions
        waveColor = mix(waveColor, lineColor, lineIntensity);
    }

    // Return final color, considering current alpha value
    return half4(waveColor, 1.0h) * color.a;
}
