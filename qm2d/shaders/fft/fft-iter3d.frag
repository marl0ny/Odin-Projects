/* This file forms part of the GLSL implementation of the 
radix-2 Cookey-Tukey FFT algorithm for 3D array data that is
stored in a texture. The dimensions of the 3D array must be a 
power of two, or else this will not work properly.

References:

Wikipedia - Cooley–Tukey FFT algorithm
https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm

MathWorld Wolfram - Fast Fourier Transform:
http://mathworld.wolfram.com/FastFourierTransform.html 

William Press et al.
12.2 Fast Fourier Transform (FFT) - Numerical Recipes
https://websites.pmc.ucsc.edu/~fnimmo/eart290c_17/NumericalRecipesinF77.pdf

*/
#if (__VERSION__ >= 330) || (defined(GL_ES) && __VERSION__ >= 300)
#define texture2D texture
#else
#define texture texture2D
#endif

#if (__VERSION__ > 120) || defined(GL_ES)
precision highp float;
#endif
 
#if __VERSION__ <= 120
varying vec2 UV;
#define fragColor gl_FragColor
#else
in vec2 UV;
out vec4 fragColor;
#endif


uniform sampler2D tex;
uniform float blockSize;
uniform int orientation;
uniform float angleSign;
uniform float size;
uniform float scale;

uniform ivec2 texelDimensions2D;
uniform ivec3 texelDimensions3D;

const float TAU = 6.283185307179586;

const int ORIENTATION_0 = 0;
const int ORIENTATION_1 = 1;
const int ORIENTATION_2 = 2;

vec2 to2DTextureCoordinates(vec3 uvw) {
    int width2D = texelDimensions2D[0];
    int height2D = texelDimensions2D[1];
    int width3D = texelDimensions3D[0];
    int height3D = texelDimensions3D[1];
    int length3D = texelDimensions3D[2];
    float wStack = float(width2D)/float(width3D);
    // float hStack = float(height2D)/float(height3D);
    float xIndex = float(width3D)*mod(uvw[0], 1.0);
    float yIndex = float(height3D)*mod(uvw[1], 1.0);
    float zIndex = mod(floor(float(length3D)*uvw[2]), float(length3D));
    float uIndex = mod(zIndex, wStack)*float(width3D) + xIndex; 
    float vIndex = floor(zIndex / wStack)*float(height3D) + yIndex; 
    return vec2(uIndex/float(width2D), vIndex/float(height2D));
}

vec3 to3DTextureCoordinates(vec2 uv) {
    int width3D = texelDimensions3D[0];
    int height3D = texelDimensions3D[1];
    int length3D = texelDimensions3D[2];
    int width2D = texelDimensions2D[0];
    int height2D = texelDimensions2D[1];
    float wStack = float(width2D)/float(width3D);
    float hStack = float(height2D)/float(height3D);
    float u = mod(uv[0]*wStack, 1.0);
    float v = mod(uv[1]*hStack, 1.0);
    float w = (floor(uv[1]*hStack)*wStack
               + floor(uv[0]*wStack) + 0.5)/float(length3D);
    return vec3(u, v, w);
}

/* 
vec2 to2DTextureCoordinates(vec3 position) {
    int width2D = texelDimensions2D[0];
    int width3D = texelDimensions3D[0];
    int length3D = texelDimensions3D[2];
    float xIndex = float(width3D)*mod(position.x, 1.0);
    float zIndex = float(length3D)*mod(position.z, 1.0);
    float uIndex = floor(zIndex)*float(width3D) + xIndex; 
    return vec2(uIndex/float(width2D), mod(position.y, 1.0));
}

vec3 to3DTextureCoordinates(vec2 uv) {
    int length3D = texelDimensions3D[2];
    float u = mod(uv[0]*float(length3D), 1.0);
    float v = uv[1];
    float w = (floor(uv[0]*float(length3D)) + 0.5)/float(length3D);
    return vec3(u, v, w);
}*/

vec4 getOdd1(vec3 uvw) {
    if (orientation == ORIENTATION_0) {
        vec3 uvw2 = vec3(uvw[0] + 0.5*blockSize, uvw[1], uvw[2]);
        return texture2D(tex, to2DTextureCoordinates(uvw2));
    } else if (orientation == ORIENTATION_1) {
        vec3 uvw2 = vec3(uvw[0], uvw[1] + 0.5*blockSize, uvw[2]);
        return texture2D(tex, to2DTextureCoordinates(uvw2));
    } else if (orientation == ORIENTATION_2) {
        vec3 uvw2 = vec3(uvw[0], uvw[1], uvw[2] + 0.5*blockSize);
        return texture2D(tex, to2DTextureCoordinates(uvw2));
    }
}

vec4 getEven2(vec3 uvw) {
    if (orientation == ORIENTATION_0) {
        vec3 uvw2 = vec3(uvw[0] - 0.5*blockSize, uvw[1], uvw[2]);
        return texture2D(tex, to2DTextureCoordinates(uvw2));
    } else if (orientation == ORIENTATION_1) {
        vec3 uvw2 = vec3(uvw[0], uvw[1] - 0.5*blockSize, uvw[2]);
        return texture2D(tex, to2DTextureCoordinates(uvw2));
    } else if (orientation == ORIENTATION_2) {
        vec3 uvw2 = vec3(uvw[0], uvw[1], uvw[2] - 0.5*blockSize);
        return texture2D(tex, to2DTextureCoordinates(uvw2));
    }
}

void main() {
    vec3 uvw = to3DTextureCoordinates(UV);
    float val = 0.0;
    if (orientation == ORIENTATION_0) {
        val = mod(uvw[0], blockSize);
    } else if (orientation == ORIENTATION_1) {
        val = mod(uvw[1], blockSize);
    } else if (orientation == ORIENTATION_2) {
        val = mod(uvw[2], blockSize);
    }

    // Even lower half
    vec4 even1 = texture2D(tex, UV);
    vec4 odd1 = getOdd1(uvw);
    float phi1 = angleSign*TAU*(val - 0.5/size)/(blockSize);
    float cosVal1 = cos(phi1);
    float sinVal1 = sin(phi1);
    vec4 expOdd1 = vec4(odd1.r*cosVal1 - odd1.g*sinVal1,
                        odd1.r*sinVal1 + odd1.g*cosVal1,
                        odd1.b*cosVal1 - odd1.a*sinVal1,
                        odd1.b*sinVal1 + odd1.a*cosVal1);
    vec4 out1 = scale*(even1 + expOdd1);

    // Odd upper half
    vec4 even2 = getEven2(uvw);
    vec4 odd2 = texture2D(tex, UV);
    float phi2 = angleSign*TAU*((val - 0.5/size) - blockSize/2.0)/(blockSize);
    float cosVal2 = cos(phi2);
    float sinVal2 = sin(phi2);
    vec4 expOdd2 = vec4(odd2.r*cosVal2 - odd2.g*sinVal2,
                        odd2.r*sinVal2 + odd2.g*cosVal2,
                        odd2.b*cosVal2 - odd2.a*sinVal2,
                        odd2.b*sinVal2 + odd2.a*cosVal2);
    vec4 out2 = scale*(even2 - expOdd2);

    fragColor = (val <= blockSize/2.0)? out1: out2;
}
