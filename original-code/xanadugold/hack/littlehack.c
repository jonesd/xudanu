From node!michael Fri Jan  4 12:46:24 1991
Return-Path: <node!michael>
Received: from node.UUCP by xanadu  (4.1/SMI-4.0.2) id AA00258; Fri, 4 Jan 91 12:46:24 PST
Received: by node.noname (4.1/SMI-4.1)
        id AA05940; Fri, 4 Jan 91 12:44:24 PST
Date: Fri, 4 Jan 91 12:44:24 PST
From: node!michael (Michael McClary)
Message-Id: <9101042044.AA05940@node.noname>
To: roger@xanadu.uucp
Subject: littlehack.c
Status: RO

#include <stdio.h>

unsigned vec1[10] = {
                2311,
                1807,
                1597,
                1861,
                2661,
                4081,
                3661,
                3877,
                3613,
                1366
};                                      /* 672a8 */

unsigned vec2[10] = {
                25367,
                45289,
                51649,
                49297,
                36979,
                25673,
                30809,
                29573,
                45289,
                150889
};                                      /* 672d0 */

char *  tabp[10] = {
                "qtr5sxed",
                "cr3vtgby",
                "h2ujmi5o",
                "piyrwl4g",
                "dcnv7xrc",
                "3ybunimp",
                "nwpsxdrf",
                "xdcshk4x",
                "glcowmho",
                "62xleoc1"
};                                      /* 6732c */

void sub2(buff,j)                       /* ef50 */
  char          buff[];
  unsigned      j;
{
        char ** p = tabp;
        int     k = 0;
        do {
                buff[k] = (*p)[j&7] ^ 1;
                p++;
                j >>= 3;
        } while (++k < 10);
}

sub(buff,j,k)                           /* efc8 */
  char          buff[];
  unsigned      j;
  unsigned      k;
{
        unsigned u;
        unsigned v;

        u = j^(j<<16);
        v = vec2[k] + (u * vec1[k]);
        sub2 (buff, v);
}

main()
{
        char    hashbuff[11];
        char    namebuff[50];

        hashbuff[sizeof(hashbuff)-1] = '\0';
        sub(hashbuff,gethostid(),1);

        namebuff[sizeof(namebuff)-1] = '\0';
        gethostname(namebuff,sizeof(namebuff)-1);

        printf("%s # %s\n",hashbuff,namebuff);
}

