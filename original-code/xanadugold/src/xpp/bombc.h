/* ==========================================================================
 *
 *	Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
 *
 * ==========================================================================
 *
 * The information contained herein is confidential, proprietary to Xanadu
 * Operating Company, and considered a trade secret as defined in section
 * 499C of the penal code of the State of California.
 *
 * Use of this information by anyone other than authorized employees of
 * Xanadu is granted only under a written nondisclosure agreement,
 * expressly prescribing the scope and manner of such use.
 *
 * The above copyright notice is not to be construed as evidence of
 * publication or the intent to publish.
 *
 * ==========================================================================
 *
 *				bombc.h
 *
 *	The bailout bomb declarations which are exported to C clients.
 *
 *		By Michael McClary		1991
 *
 * ==========================================================================
 *
 *	Cloned from bombx.hxx
 *	Edited down to just what was needed both by c++ and c bombs
 *		- michael Oct 27 1991
 *
 * ========================================================================== */
/* ==========================================================================
 *
 *	Repitition suppression switch
 *
 * ========================================================================== */

#ifndef BOMBC_H
#define BOMBC_H
/* ==========================================================================
 *
 *	Includes
 *
 * ========================================================================== */

#ifndef CCOMPATC_H
#include "ccompatc.h"
#endif /* CCOMPATC_H */

static char *bombc_h_version() {
    return "$Id: bombc.h,v 2.3 1992/11/25 23:25:56 eric Exp $";
}

/* ==========================================================================
 *
 *	#define BOMB_REPORT_LINE if file and line numbers are to be
 *	displayed in error messages.
 *
 * ========================================================================== */

#define	BOMB_REPORT_LINE		/* !!!! */

/* ==========================================================================
 *
 *	BOMBs are the objects which do the cleanup actions.  They are strung
 *	on a "fuse" which grows or shrinks as the program flow goes deeper
 *	or shallower in block/subroutine nesting, and they "detonate"
 *	sequentially when an exception exit bypasses ordinary program flow.
 *
 * ==========================================================================
 *
 *	Arguments to detonateBomb()
 *	  - Generally: the reason the bomb is being detonated.
 *	  - BLASTING_STOPS is a special case of BLASTING that is passed
 *	    to the SHIELD that catches the blast.
 *
 * ========================================================================== */

enum SourceOfDetonationSignal {
	  LEFT_AREA
	, BLASTING
	, BLASTING_STOPS
	, LOCAL_DETONATE
	, REARMED
};
/* ==========================================================================
 *
 *	PROBLEM_LIST(LTAG,NUMBER,(LIST)):
 *
 *	A (set of) macro(s) to generate the list of problems that a SHIELD
 *	catches.
 *
 *	LTAG:	An identifier to be used in the SHIELD_UP() macro.
 *	NUMBER:	The number of problems in LIST.
 *	LIST:	A (paren)-enclosed, comma-separated, list of problems.
 *
 *	(The problems in LIST may be any string, but by convention are
 *	 suitable for use as manefest constants in a #define, i.e.
 *	 ALL_CAPS_UNDERSCORES_FOR_BLANKS.)
 *
 *	"ALL_BUT" in the first position of LIST says to invert sense on
 *	the rest of test.
 *
 *	"DOOMSDAY" in the first position of LIST says the SHIELD is really
 *	a DOOMSDAY_BOMB.
 *
 *	(Though problem lists are only defined for a limited number of
 *	 problems, adding more, should they become necessary, is trivial.)
 *
 * ========================================================================== */


#define	PROBLEM_LIST(LTAG, NUMBER, LIST)				\
		static char **	CAT(LTAG,_shieldList)() {		\
					static char *local[] = { ERRLIST(NUMBER,LIST), 0}; \
					return local;			\
				    }

#define	ERRLIST(n,list)	CAT(ERRLIST_,n)list

#define	ERRLIST_1(a)			STR(a)
#define	ERRLIST_2(a,b)			STR(a),STR(b)
#define	ERRLIST_3(a,b,c)		STR(a),STR(b),STR(c)
#define	ERRLIST_4(a,b,c,d)		STR(a),STR(b),STR(c),STR(d)
#define	ERRLIST_5(a,b,c,d,e)		STR(a),STR(b),STR(c),STR(d),STR(e)
#define	ERRLIST_6(a,b,c,d,e,f)		STR(a),STR(b),STR(c),STR(d),STR(e),STR(f)
#define	ERRLIST_7(a,b,c,d,e,f,g)	STR(a),STR(b),STR(c),STR(d),STR(e),STR(f),STR(g)
#define	ERRLIST_8(a,b,c,d,e,f,g,h)	STR(a),STR(b),STR(c),STR(d),STR(e),STR(f),STR(g),STR(h)
#define	ERRLIST_9(a,b,c,d,e,f,g,h,i)	STR(a),STR(b),STR(c),STR(d),STR(e),STR(f),STR(g),STR(h),STR(i)

#endif /* BOMBC_H */
