#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#ifdef _WIN32
#define popen _popen
#define pclose _pclose
#endif

static void find_delim(char *s, char **res, int *ix)
{
    for(; *ix && s[*ix] != '-'; *ix -= 1);
    if (*ix) {
        s[*ix] = '\0';
        *res = s + *ix + 1;
    } else {
        *res = s;
    }
}

int main(int argc, char **argv)
{
    char vbuf[4096] = { 0 };
    char *version, *ncommits, *sha;
    FILE *po;
    int buflen;
    char *format;
    int force;
    int ncommits_i;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <FORMAT>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    /** Get the output */
    po = popen("git describe --long", "r");
    if (!po) {
        perror("git describe");
        exit(EXIT_FAILURE);
    }

    if (!fgets(vbuf, sizeof(vbuf), po)) {
        fprintf(stderr, "git describe closed stream\n");
        exit(EXIT_FAILURE);
    }
    pclose(po);
    buflen = strlen(vbuf);
    vbuf[buflen-2] = '\0';
    buflen -= 1;

    find_delim(vbuf, &sha, &buflen);
    find_delim(vbuf, &ncommits, &buflen);
    version = vbuf;

    sscanf(ncommits, "%d", &ncommits_i);
    format = argv[1];
    force = *format == 'F';
    if (force) {
        format++;
    }

    if (!force) {
        force = ncommits_i;
    }

    for (; *format; format++) {
        switch (*format) {
            case 'T':
            case 't':
                printf("%s\n", version);
                break;
            case 'N':
            case 'n':
                if (force) {
                    printf("%s\n", ncommits);
                }
                break;
            case 's':
            case 'S':
                if (force) {
                    printf("%s\n", sha);
                }
        }
    }
    return 0;
}
