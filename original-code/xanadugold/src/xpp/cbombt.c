/* ========================================================================== *
 *
 *	Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
 *
 * ========================================================================== *
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
 * ========================================================================== *
 *
 *			cbombt.c
 *
 *		By Michael McClary		1991
 *
 * ========================================================================== *
 *
 * ========================================================================== */

static char cbombt_c_rcsid[] = "$Id: cbombt.c,v 1.3 1992/08/14 22:06:57 shap Exp $";

/* #include <stdlib.h> */
#include <stdio.h>
#include <assert.h>

#include "cbombc.h"

/* ========================================================================== *
 *
 *	main() normally just sets up the environment,
 *	then calls a subroutine to do each test.
 *
 *	Called with a single argument of -d, it writes two lines that
 *	contain correctly-sized #defines of C_{BOMB,SHIELD}_SIZE.  This
 *	can be used to automatically generate an include file, if anybody
 *	ever figures out how to do it without feeding a circular dependency
 *	to "make".
 *
 * ========================================================================== */

void sub0();
void sub1();
void sub1a();
void sub2();
void sub2a();
void sub4();
void sub8a();
void sub9();

main(argc, argv)
	int	argc;
	char **	argv;
{
	if (argc > 1 && strcmp(argv[1], "-d") == 0) {
		printf("#define C_BOMB_SIZE	%d\n", getCBombSize());
		printf("#define C_SHIELD_SIZE	%d\n", getCShieldSize());
		return 0;
	}

	doStaticInit();

	fprintf(stderr, "Testing C Bombs\n");

	sub0();		/* Print any errors in C_{BOMB,SHIELD}_SIZE. */

	sub1();		/* Test arming/firing sequence */

	sub1a();	/* Tests C_BLAST() macro */

	sub2();		/* Tests BOMBs and smartbomb source detection. */

	sub2a();	/* Test REBLAST and some miscelaneous shield macros. */

	sub4();		/* Tests DISARM_BOMB() */

	sub8a();	/* Test C_BOOBY_TRAP() macro. */

/* 	sub9(); */	/* Tests Doomsday Bombs. */
			/* Therefore, turned off in this module. */


	doStaticTerm();
	return 0;
}
/* ==========================================================================
 *
 *	sub0():	Print any errors in C_{BOMB,SHIELD}_SIZE.
 *
 * ========================================================================== */

void sub0()
{
	fprintf(stderr,"C_BOMB_SIZE   - getCBombSize()   = %d\n",
			C_BOMB_SIZE   - getCBombSize());

	fprintf(stderr,"C_SHIELD_SIZE - getCShieldSize() = %d\n",
			C_SHIELD_SIZE - getCShieldSize());
}
/* ==========================================================================
 *
 *	sub1(): Test arming/firing sequence
 *
 * ========================================================================== */

C_DESIGN_BOMB(printError,voidStar, {
	fprintf(stderr, "%s", (char *)CHARGE);
})

C_DESIGN_BOMB(integer,int, {
	fprintf(stderr, "%d, therefore: %d\n", SOURCE, CHARGE);
})

void sub1()
{
	char*	message = "BLAM!.\n";

	fprintf(stderr, "\nsub1(): Testing arming/firing sequence\n");

	fprintf(stderr, "About to do C_PLANT_BOMB() on integer bomb\n");
	C_PLANT_BOMB_BEGIN(integer,integer);

	fprintf(stderr, "About to do C_ARM_BOMB() on integer bomb\n");
	C_ARM_BOMB(integer,int,42);

	fprintf(stderr, "About to leave area of integer bomb\n");
	C_PLANT_BOMB_END;

	fprintf(stderr, "About to do C_PLANT_BOMB()\n");
	C_PLANT_BOMB(printError,mess, {

		fprintf(stderr, "About to do C_ARM_BOMB()\n");
		C_ARM_BOMB(mess,voidStar,(voidStar)message);

		fprintf(stderr, "About to do C_ARM_BOMB()\n");
		C_ARM_BOMB(mess,voidStar,(voidStar)message);

		fprintf(stderr, "About to do C_DETONATE_BOMB()\n");
		C_DETONATE_BOMB(mess);

		fprintf(stderr, "About to do C_DETONATE_BOMB()\n");
		C_DETONATE_BOMB(mess);

		fprintf(stderr, "About to do C_ARM_BOMB()\n");
		C_ARM_BOMB(mess,voidStar, (voidStar)message);

		fprintf(stderr, "Leaving sub1()\n");
	});
}
/* ========================================================================== *
 *
 *	sub1a():	Test the C_BLAST() macros.
 *
 * ========================================================================== */

C_PROBLEM_LIST(FOO,3,(BAR_ERROR,FOO_ERROR,BAZ_ERROR))
C_PROBLEM_LIST(SNURD,2,(BAR_ERROR,SNURD_ERROR))

void sub1a()
{
	fprintf(stderr, "\nsub1a(): Testing the C_BLAST() macro\n");

	fprintf(stderr, "About to do C_INSTALL_LOUD_SHIELD()\n");
	C_INSTALL_LOUD_SHIELD_BEGIN(BAZ)
		fprintf(stderr, "Inside loud shield.\n");

		for (;;) {
		  fprintf(stderr,"\nAbout to raise shield for FOO problems.\n");
		  C_SHIELD_UP_BEGIN(BAZ, FOO) {
 			fprintf(stderr, "Caught it!  VAL = %d\n", VAL);
			fprintf(stderr, "About to do a C_BREAK_FROM_SHIELD\n");
		/**/	C_BREAK_FROM_SHIELD;
		  } C_SHIELD_UP_END(BAZ);

		  fprintf(stderr, "About to C_BLAST(FOO_ERROR)\n");
		  C_BLAST(FOO_ERROR);
		  fprintf(stderr, "Oops!  Got past C_BLAST(FOO_ERROR)\n");
		}

		for (;;) {
		  fprintf(stderr,"\nAbout to raise shield for FOO problems.\n");
		  C_SHIELD_UP_BEGIN(BAZ, FOO) {
 			fprintf(stderr, "Caught it!  VAL = %d\n", VAL);
			fprintf(stderr, "About to do a C_BREAK_FROM_SHIELD\n");
		/**/	C_BREAK_FROM_SHIELD;
		  } C_SHIELD_UP_END(BAZ);

		  fprintf(stderr, "About to C_BLAST_FROM_THE_PASSED(FOO_ERROR,9,\"F\",999)\n");
		  C_BLAST_FROM_THE_PASSED(FOO_ERROR,9,"F",999);
		  fprintf(stderr, "Oops!  Got past C_BLAST_FROM_THE_PASSED(FOO_ERROR,9,\"F\",999)\n");
		}

		fprintf(stderr,"\nAbout to raise shield for FOO problems.\n");
		C_SHIELD_UP_BEGIN(BAZ, FOO) {
 			fprintf(stderr, "Caught it!  VAL = %d\n", VAL);
			fprintf(stderr, "Leaving sub1a()\n");
			C_RETURN_THROUGH(BAZ,C_RETURN_VOID);
		} C_SHIELD_UP_END(BAZ);

		fprintf(stderr, "About to C_BLAST_WITH_VAL(FOO_ERROR,15)\n");
		C_BLAST_WITH_VAL(FOO_ERROR,15);

	C_INSTALL_LOUD_SHIELD_END;

	fprintf(stderr, "Leaving sub1a() the wrong way.\n");
}
/* ==========================================================================
 *
 *	sub2():	Test BOMBs and smartbomb source detection.
 *
 * ========================================================================== */

C_DESIGN_SMART_BOMB(smart,voidStar, {
	fprintf(stderr, "%d, therefore: %s\n", SOURCE, (char *)CHARGE);
})

C_DESIGN_BOMB_BEGIN(recursive,voidStar) {
	char*	message = "This is the recursive message.\n";

	fprintf(stderr, "recursive %s", (char *)CHARGE);

	fprintf(stderr, "About to do C_PLANT_BOMB()\n");
	C_PLANT_BOMB_BEGIN(printError,mess)

	fprintf(stderr, "About to do C_ARM_BOMB()\n");
	C_ARM_BOMB(mess,voidStar,(voidStar)message);

	C_PLANT_BOMB_END;
} C_DESIGN_BOMB_END

C_DESIGN_SMART_BOMB_BEGIN(disarmer,voidStar) {
	if (SOURCE == BLASTING) {
		fprintf(stderr, "disarming.\n");
		cBombDisarm((CBomb *)CHARGE);
	}
} C_DESIGN_SMART_BOMB_END


void sub2()
{
	char*	message = "BLAM!.\n";

	fprintf(stderr,
		"\nsub2(): Testing BOMBs and smartbomb source detection.\n");

	{
		fprintf(stderr, "About to do C_PLANT_BOMB() on smart bomb\n");
		C_PLANT_BOMB_BEGIN(smart,smart);

		fprintf(stderr, "About to do C_ARM_BOMB() on smart bomb\n");
		C_ARM_BOMB(smart,voidStar,(void *)message);

		fprintf(stderr, "About to leave area of smart bomb\n");
		C_PLANT_BOMB_END;
	}

	fprintf(stderr, "About to do PLANT_BOMB() on smart bomb\n");
	C_PLANT_BOMB_BEGIN(smart,smart);

	fprintf(stderr, "About to do ARM_BOMB() on smart bomb\n");
	C_ARM_BOMB(smart,voidStar,(voidStar) message);

	fprintf(stderr, "About to do DETONATE_BOMB() on smart bomb\n");
	C_DETONATE_BOMB(smart);
	
	fprintf(stderr, "About to do ARM_BOMB() on smart bomb\n");
	C_ARM_BOMB(smart,voidStar,(voidStar) message);

	fprintf(stderr, "About to rearm smart bomb\n");
	C_ARM_BOMB(smart,voidStar,(voidStar) message);

	fprintf(stderr, "About to do ARM_BOMB() on smart bomb\n");
	C_ARM_BOMB(smart,voidStar,(voidStar) "First bomb message.\n");

/*
 * Next stuff mostly tests that results are same as with C++ bombs
 * We get to pick up a few macros this way, too.
 */

	fprintf(stderr, "About to do C_INSTALL_LOUD_SHIELD()\n");
	C_INSTALL_LOUD_SHIELD_BEGIN(BAZ)

	fprintf(stderr, "About to do C_SHIELD_UP()\n");
	C_SHIELD_UP_BEGIN(BAZ, FOO) {
 		fprintf(stderr, "Caught it!  VAL = %d\n", VAL);
		fprintf(stderr, "problemName = %s", cProblemFetchProblemName(C_PROBLEM_P));
		fprintf(stderr, ", val = %d", cProblemFetchVal(C_PROBLEM_P));
		fprintf(stderr, ", fileName = %s", cProblemFetchFileName(C_PROBLEM_P));
		fprintf(stderr, ", lineNumber = %d", cProblemFetchLineNumber(C_PROBLEM_P));
		fprintf(stderr, "\n");
		/* assert(FALSE); */
		C_RETURN_THROUGH(smart,C_RETURN_VOID);
	} C_SHIELD_UP_END(BAZ);

	fprintf(stderr, "About to do C_PLANT_BOMB() on second smart bomb\n");
	C_PLANT_BOMB_BEGIN(smart,smart2)

	fprintf(stderr, "About to do C_ARM_BOMB() on second smart bomb\n");
	C_ARM_BOMB(smart2,voidStar,(voidStar) "Second bomb message.\n");

	fprintf(stderr, "About to do C_INSTALL_LOUD_SHIELD()\n");
	C_INSTALL_LOUD_SHIELD_BEGIN(SNURD)

	fprintf(stderr, "About to do C_SHIELD_UP()\n");
	C_SHIELD_UP_BEGIN(SNURD, SNURD) {
		fprintf(stderr, "Caught it!  VAL = %s\n", (char *)VAL);
		assert(FALSE);
	} C_SHIELD_UP_END(SNURD);

	fprintf(stderr, "About to do C_PLANT_BOMB() on recursive bomb.\n");
	C_PLANT_BOMB_BEGIN(recursive,recurs)

	fprintf(stderr, "About to do C_ARM_BOMB() on recursive bomb.\n");
	C_ARM_BOMB(recurs,voidStar,(voidStar)message);

	fprintf(stderr, "About to do C_PLANT_BOMB() on third smart bomb\n");
	C_PLANT_BOMB_BEGIN(smart,smart3)

	fprintf(stderr, "About to do C_ARM_BOMB() on third smart bomb\n");
	C_ARM_BOMB(smart3,voidStar,(voidStar) "Third bomb message.\n");

	fprintf(stderr, "About to do C_PLANT_BOMB() on disarmer bomb\n");
	C_PLANT_BOMB_BEGIN(disarmer,disarmer)

	fprintf(stderr, "About to do C_ARM_BOMB() on disarmer bomb\n");
	C_ARM_BOMB(disarmer,voidStar,(voidStar) &SNURD_cShield);

	/* fprintf(stderr, "About to do BLAST_WITH_VAL()\n");
	 * BLAST_WITH_VAL(X_ERROR, 5);
	 * BLAST_WITH_VAL(SNURD_ERROR, 5);	// Uncaught Signal Escaped Detection
	 */
	fprintf(stderr, "About to do C_BLAST()\n");
	C_BLAST(FOO_ERROR);

	C_PLANT_BOMB_END;		/* disarmer */
	C_PLANT_BOMB_END;		/* smart3 */
	C_PLANT_BOMB_END;		/* recurs */
	C_INSTALL_LOUD_SHIELD_END;	/* SNURD */
	C_PLANT_BOMB_END;		/* smart2 */
	C_INSTALL_LOUD_SHIELD_END;	/* BAZ */
	C_PLANT_BOMB_END;		/* smart */
}
/* ==========================================================================
 *
 *	sub2a(): Test REBLAST and some miscelaneous shield macros.
 *
 * ========================================================================== */

void sub2a()
{
	C_INSTALL_LOUD_SHIELD_BEGIN(OUTER)
	  C_INSTALL_LOUD_SHIELD_BEGIN(INNER)

		fprintf(stderr, "About to do C_SHIELD_UP(OUTER...)\n");
		C_SHIELD_UP(OUTER, FOO, {
 			fprintf(stderr, "Outer caught it!\n");
			C_RETURN_THROUGH(OUTER,C_RETURN_VOID);
		});

		fprintf(stderr, "About to do C_SHIELD_UP(INNER...)\n");
		C_SHIELD_UP(INNER, FOO, {
			fprintf(stderr, "Inner caught it!\n");
			fprintf(stderr, "About to do C_REBLAST\n");
			C_REBLAST;
		});

		fprintf(stderr, "About to do C_BLAST_WITH_VAL(FOO_ERROR, 9)\n");
		C_BLAST_WITH_VAL(FOO_ERROR, 9);
	  C_INSTALL_LOUD_SHIELD_END;	/* INNER */
	C_INSTALL_LOUD_SHIELD_END;	/* OUTER */
}
/* ==========================================================================
 *
 *	sub4():	Tests DISARM_BOMB()
 *
 * ========================================================================== */

void sub4()
{
	char*	message = "This is the message.\n";

	fprintf(stderr, "\nsub4(): Testing disarm\n");

	fprintf(stderr, "About to do C_PLANT_BOMB()\n");
	C_PLANT_BOMB(printError,mess, {

		fprintf(stderr, "About to do C_ARM_BOMB()\n");
		C_ARM_BOMB(mess,voidStar,(voidStar)message);

		fprintf(stderr, "About to do C_DISARM_BOMB()\n");
		C_DISARM_BOMB(mess);

		fprintf(stderr, "leaving sub4()\n");
	});
}
/* ========================================================================== 
 *
 *  sub8a(): Test C_BOOBY_TRAP() macro.
 *
 * ========================================================================== */

PROBLEM_LIST(BLAP,1,(BLAP))
PROBLEM_LIST(BOOBY_BLEW,1,(BOOBY_BLEW))

void sub8a()
{
	fprintf(stderr, "\nsub8(): Testing C_BOOBY_TRAP()()\n");

	fprintf(stderr, "About to do C_INSTALL_SHIELD_BEGIN(OUTER)\n");
	C_INSTALL_SHIELD_BEGIN(OUTER)

	fprintf(stderr, "About to do C_SHIELD_UP(OUTER...)\n");
	C_SHIELD_UP(OUTER, BOOBY_BLEW, {
 		fprintf(stderr, "Outer caught the boobytrap's warning!\n");
		fprintf(stderr, "\nLeaving sub8()\n");
		C_RETURN_THROUGH(OUTER,C_RETURN_VOID);
	});

	fprintf(stderr, "About to do C_INSTALL_LOUD_SHIELD_BEGIN(C_BOOBY_TRAPPING)\n");
	C_INSTALL_LOUD_SHIELD_BEGIN(C_BOOBY_TRAPPING);

	fprintf(stderr, "\nAbout to do C_BOOBY_TRAP_BEGIN()\n");
	C_BOOBY_TRAP_BEGIN(BLAP) {
		fprintf(stderr, "About to do C_BLAST(BLAP)\n");
		C_BLAST(BLAP);
		fprintf(stderr, "Oops!\n");
	} C_BOOBY_TRAP_END(BOOBY_BLEW);

	fprintf(stderr, "\nAbout to do C_BOOBY_TRAP()\n");
	C_BOOBY_TRAP(BLAP,BOOBY_BLEW, {
		fprintf(stderr, "About to do C_BLAST(BLAP)\n");
		C_BLAST(BLAP);
		fprintf(stderr, "Oops!\n");
	});

	fprintf(stderr, "\nAbout to do C_BOOBY_TRAP_BEGIN()\n");
	C_BOOBY_TRAP_BEGIN(BLAP) {
		fprintf(stderr, "About to do C_BLAST(BLAP)\n");
		C_BLAST(BLAP);
		fprintf(stderr, "Oops!\n");
	} C_BOOBY_TRAP_END(BOOBY_BLEW);

	fprintf(stderr, "\nAbout to do C_BOOBY_TRAP_BEGIN()\n");
	C_BOOBY_TRAP_BEGIN(BLAP) {
		fprintf(stderr, "About to neglect to do a C_BLAST(BLAP)\n");
	} C_BOOBY_TRAP_END(BOOBY_BLEW);

	fprintf(stderr, "Oops!\n");
	C_INSTALL_LOUD_SHIELD_END;	/* C_BOOBY_TRAPPING */
	C_INSTALL_SHIELD_END;		/* OUTER */
}
/* ==========================================================================
 *
 *	Test DOOMSDAY_BOMB()
 *
 * ========================================================================== */

void sub9()
{
	fprintf(stderr, "\nsub9(): Testing Doomsday Bomb.  (YIKE!)\n");

	fprintf(stderr, "About to do PLANT_DOOMSDAY_BOMB()\n");
	C_PLANT_DOOMSDAY_BOMB_BEGIN;

	fprintf(stderr, "About to do ARM_DOOMSDAY_BOMB()\n");
	C_ARM_DOOMSDAY_BOMB();

	fprintf(stderr, "About to do BLAST_WITH_VAL()\n");
	C_BLAST_WITH_VAL(FOO_ERROR, 1);

	fprintf(stderr, "Leaving sub9()\n");
	C_PLANT_DOOMSDAY_BOMB_END;
}
