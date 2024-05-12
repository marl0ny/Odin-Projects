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

#define complex vec2

uniform sampler2D tex;
uniform sampler2D bgTex;
uniform float phaseAdjust;

complex mul(complex w, complex z) {
    return complex(w.x*z.x - w.y*z.y, w.x*z.y + w.y*z.x);
}

vec3 complexToColour(complex val) {
    float re = val[0];
    float im = val[1];
    float pi = 3.141592653589793;
    float argVal = atan(im, re);
    float maxCol = 1.0;
    float minCol = 50.0/255.0;
    float colRange = maxCol - minCol;
    if (argVal <= pi/3.0 && argVal >= 0.0) {
        return vec3(maxCol,
                    minCol + colRange*argVal/(pi/3.0), minCol);
    } else if (argVal > pi/3.0 && argVal <= 2.0*pi/3.0){
        return vec3(maxCol - colRange*(argVal - pi/3.0)/(pi/3.0),
                    maxCol, minCol);
    } else if (argVal > 2.0*pi/3.0 && argVal <= pi){
        return vec3(minCol, maxCol,
                    minCol + colRange*(argVal - 2.0*pi/3.0)/(pi/3.0));
    } else if (argVal < 0.0 && argVal > -pi/3.0){
        return vec3(maxCol, minCol,
                    minCol - colRange*argVal/(pi/3.0));
    } else if (argVal <= -pi/3.0 && argVal > -2.0*pi/3.0){
        return vec3(maxCol + (colRange*(argVal + pi/3.0)/(pi/3.0)),
                    minCol, maxCol);
    } else if (argVal <= -2.0*pi/3.0 && argVal >= -pi){
        return vec3(minCol,
                    minCol - (colRange*(argVal + 2.0*pi/3.0)/(pi/3.0)),
                    maxCol);
    }
    else {
        return vec3(minCol, maxCol, maxCol);
    }
}

void main() {
    vec4 psiPotential = texture2D(tex, UV);
    complex phaseFactor = vec2(cos(phaseAdjust), sin(phaseAdjust));
    vec2 psi = mul(phaseFactor, vec2(psiPotential[0], psiPotential[1]));
    // float absVal = min(psi[0]*psi[0] + psi[1]*psi[1], 1.0);
    float absVal = psi[0]*psi[0] + psi[1]*psi[1];
    // fragColor = vec4(min(absVal, 1.0)*complexToColour(psi), 1.0);
    vec4 bg = texture2D(bgTex, UV);
    fragColor = vec4(absVal*complexToColour(psi), 1.0) + bg;
    // fragColor = vec4(absVal, absVal, absVal, 1.0);
}
