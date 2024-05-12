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

uniform vec4 w00;
uniform vec4 w10;
uniform vec4 w01; 
uniform vec4 w11;

void main() {
    fragColor = mix(mix(w00, w10, UV.x), mix(w01, w11, UV.x), UV.y);
}
