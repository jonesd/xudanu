#ifndef BIBOPX_IXX
#define BIBOPX_IXX

/* ************************************************************************ *
 * 
 *                    Class     LiveHeaperStepper
 *
 * ************************************************************************ */

INLINE BooleanVar LiveHeaperStepper::hasValue()
{
    return myHeaper != NULL;
}

INLINE Heaper * OR(NULL) LiveHeaperStepper::fetch()
{
    return myHeaper;
}

INLINE BibopPage * LiveHeaperStepper::page () {
    return myPage;
}

#endif /* BIBOPX_IXX */
