#include "utils.h"

size_t strlcpy(char *dst, const char *src, size_t dstsize) {
    size_t srclen = strlen(src);
    if (dstsize > 0) {
        size_t copylen = srclen < dstsize - 1 ? srclen : dstsize - 1;
        memcpy(dst, src, copylen);
        dst[copylen] = '\0';
    }
    return srclen;
}


float ScaleUI(float value) {
    return value * globalScalingFactor;
}

int ScaleUIToInt(float value) {
    return (int)(value * globalScalingFactor);
}
