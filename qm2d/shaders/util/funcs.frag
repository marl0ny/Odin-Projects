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
#define complex2 vec4

uniform sampler2D tex;
uniform int whichFunction;

#define R_COS 0
#define R_SIN 1
#define R_EXP 2
#define R_LOG 3
#define R_TAN 4
#define R_SQRT 5

#define C_COS 64
#define C_SIN 65
#define C_EXP 66
#define C_SQRT 67

const complex IMAG_UNIT = complex(0.0, 1.0);

complex conj(complex z) {
    return complex(z.x, -z.y);
}

complex inv(complex z) {
    return conj(z)/(z.x*z.x + z.y*z.y);
}

complex mul(complex w, complex z) {
    return complex(w.x*z.x - w.y*z.y, w.x*z.y + w.y*z.x);
}

complex cexp(complex z) {
    // return complex(cos(z.y), sin(z.y));
    return exp(z.x)*complex(cos(z.y), sin(z.y));
}

complex ccos(complex z) {
    return (cexp(mul(z, IMAG_UNIT)) + cexp(-mul(z, IMAG_UNIT)))/2.0;
}

complex csin(complex z) {
    return mul(cexp(mul(z, IMAG_UNIT)) - cexp(-mul(z, IMAG_UNIT)),
               -0.5*IMAG_UNIT);
}

complex ccosh(complex z) {
    return (cexp(z) + cexp(-z))/2.0;
}

complex csinh(complex z) {
    return mul(cexp(z) - cexp(-z), -0.5*IMAG_UNIT);
}

void main() {
    vec4 val = texture2D(tex, UV);
    if (whichFunction == R_COS) {
        fragColor = cos(val);
    } else if (whichFunction == R_SIN) {
        fragColor = sin(val);
    } else if (whichFunction == R_EXP) {
        fragColor = exp(val);
    } else if (whichFunction == R_LOG) {
        fragColor = log(val);
    } else if (whichFunction == R_TAN) {
        fragColor = tan(val);
    } else if (whichFunction == R_SQRT) {
        fragColor = sqrt(val);
    } else if (whichFunction == C_COS) {
        fragColor = complex2(ccos(val.xy), ccos(val.zw));
    } else if (whichFunction == C_SIN) {
        fragColor = complex2(csin(val.xy), csin(val.zw));
    } else if (whichFunction == C_EXP) {
        fragColor = complex2(cexp(val.xy), cexp(val.zw));
    } else if (whichFunction == C_SQRT) {
        float absVal1 = sqrt(val.x*val.x + val.y*val.y);
        float absVal2 = sqrt(val.z*val.z + val.w*val.w);
        float arg1 = atan(val.y, val.x);
        float arg2 = atan(val.w, val.z);
        fragColor = complex2(sqrt(absVal1)*cexp(IMAG_UNIT*arg1/2.0),
                             sqrt(absVal2)*cexp(IMAG_UNIT*arg2/2.0));
    }
}
