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

uniform ivec2 texelDimensions2D;
uniform ivec3 texelDimensions3D;

uniform vec4 w000;
uniform vec4 w100;
uniform vec4 w010; 
uniform vec4 w110;

uniform vec4 w001;
uniform vec4 w101;
uniform vec4 w011; 
uniform vec4 w111;


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

void main() {
    vec3 uvw = to3DTextureCoordinates(UV);
    fragColor = mix(
        mix(mix(w000, w100, uvw.x), 
            mix(w010, w110, uvw.x), uvw.y),
        mix(mix(w001, w101, uvw.x), 
            mix(w011, w111, uvw.x), uvw.y), uvw.z);
}