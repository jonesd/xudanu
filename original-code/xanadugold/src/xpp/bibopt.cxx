/* Copyright 1992 Xanadu Operating Company.  All Rights Reserved. */

#include <stream.h>

#include "bibopt.hxx"

#include "initx.hxx"

#include "bibopp.hxx"
#include "bibopt.sxx"
#include "tofux.hxx"

#define __EXTENSIONS__
#include <stdlib.h>	/* for putenv() */

VERSION_ID(bibopt_cxx,
	   "$Id: bibopt.cxx,v 3.9 1993/03/19 21:54:20 hibbert Exp $")

void initializeBibopHeap()
{
    putenv("BIBOP_LOG_PAGE_SIZE=10");
    putenv("BIBOP_MAX_MEMORY=16777216");
    putenv("BIBOP_ALLOC_INCREMENT=3072");
    BibopLogger.init("cerr");
}

/* main */
int  XU_MAIN (int ac, char **av)
{
    initializeBibopHeap();

	Initializer mainInit(ac,av);

	allTestsOn(cerr);
	return 0;
}

/* running tests */
void  allTestsOn (ostream& aStream)
{
	aStream << "Running all Bibop tests.\nTest 1\n";
    warmUpExerciseOn(aStream);
    allocAndFreeTestOn(aStream);
    reuseExerciseOn(aStream);
    freeExerciseOn(aStream);
    pointerCheckExerciseOn(aStream);
	aStream << "\n";
}

void warmUpExerciseOn(ostream& aStream)
{
    BibopHeap * warmUpHeap = new BibopHeap(128, 4);
    Int32 counter = 0;

    /*  make one of each */
    aStream << "\n making a few objects";
    Zero::make(warmUpHeap, counter++);
    One::make(warmUpHeap, counter++);		/*  #1  */
    Two::make(warmUpHeap, counter++);
    Three::make(warmUpHeap, counter++);
    Six::make(warmUpHeap, counter++);
    Thirteen::make(warmUpHeap, counter++);		/*  #5  */
    TwentyFive::make(warmUpHeap, counter++);

    /*  enumerate objects, printing and deleting */
    aStream << "\n the heap currently contains: \n";
    LiveHeaperStepper * stepper = warmUpHeap->stepper();
    for (Heaper * living = stepper->fetch()
         ; living != NULL
         ; stepper->step(), living = stepper->fetch()) {
             living->printOn(aStream);
             aStream << "\n";
             warmUpHeap->free(living);
         }
    delete stepper;
    aStream << "\n and nothing else. \n";

    /*  enumerate objects */
    aStream << "\n the heap should now be empty:  ";
    stepper = warmUpHeap->stepper();
    for (Heaper * dead = stepper->fetch()
         ; dead != NULL
         ; stepper->step(), dead = stepper->fetch()) {
             dead->printOn(aStream);
             aStream << "\n";
         }
    delete stepper;
    aStream << "  . \n";

    /*  make a few of each and keep some */
    aStream << "\n making some more objects";
    Zero::make(warmUpHeap, counter++);
    One * one1 = One::make(warmUpHeap, counter++);
    Six::make(warmUpHeap, counter++);
    Two::make(warmUpHeap, counter++);		/*  #10  */
    Zero * zero1 = Zero::make(warmUpHeap, counter++);
    Three::make(warmUpHeap, counter++);
    Three * three1 = Three::make(warmUpHeap, counter++);
    Six * six1 = Six::make(warmUpHeap, counter++);
    Two * two1 = Two::make(warmUpHeap, counter++);		/*  #15  */
    Six::make(warmUpHeap, counter++);
    Thirteen * th1 = Thirteen::make(warmUpHeap, counter++);
    Thirteen::make(warmUpHeap, counter++);
    TwentyFive * tw1 = TwentyFive::make(warmUpHeap, counter++);
    TwentyFive::make(warmUpHeap, counter++);		/*  #20  */
    TwentyFive::make(warmUpHeap, counter++);

    /* delete some */
    delete one1;
    warmUpHeap->free(one1);
    delete six1;
    warmUpHeap->free(six1);
    delete two1;
    warmUpHeap->free(two1);
    delete zero1;
    warmUpHeap->free(zero1);
    delete th1;
    warmUpHeap->free(th1);
    delete tw1;
    warmUpHeap->free(tw1);

    /*  make some more */
    Zero::make(warmUpHeap, counter++);
    Zero * zero2 = Zero::make(warmUpHeap, counter++);
    One::make(warmUpHeap, counter++);
    One * one2 = One::make(warmUpHeap, counter++);		/*  #25  */
    One::make(warmUpHeap, counter++);
    Two::make(warmUpHeap, counter++);
    Two * two2 = Two::make(warmUpHeap, counter++);
    Three::make(warmUpHeap, counter++);
    Three * three2 = Three::make(warmUpHeap, counter++);		/*  #30  */
    Three::make(warmUpHeap, counter++);
    Six::make(warmUpHeap, counter++);
    Six::make(warmUpHeap, counter++);
    Thirteen::make(warmUpHeap, counter++);
    Thirteen::make(warmUpHeap, counter++);		/*  #35  */
    Thirteen::make(warmUpHeap, counter++);
    TwentyFive::make(warmUpHeap, counter++);
    TwentyFive::make(warmUpHeap, counter++);
    TwentyFive::make(warmUpHeap, counter++);
    
    /*  enumerate the live ones */
    aStream << "\n The heap should be interesting: \n";
    stepper = warmUpHeap->stepper();
    for (Heaper * aLive = stepper->fetch()
         ; aLive != NULL
         ; stepper->step(), aLive = stepper->fetch()) {
             aLive->printOn(aStream);
             aStream << "\n";
         }
    delete stepper;
    aStream << " end of round 2. \n";
}

void allocAndFreeTestOn(ostream& aStream)
{
    BibopHeap * aAndFHeap = new BibopHeap(128, 4);
    Int32 counter = 0;
    Zero* zeroArray[100];
    One* oneArray[100];
    Two* twoArray[100];
    Three* threeArray[100];
    Six* sixArray[100];
    Thirteen* thirteenArray[100];
    TwentyFive* twentyFiveArray[100];

    /*  make some of each */
    aStream << "\n making a lot of objects";

    for (int index = 0; index < 50 ; index++) {
        zeroArray[index] = Zero::make(aAndFHeap, counter++);
        oneArray[index] = One::make(aAndFHeap, counter++);
        twoArray[index] = Two::make(aAndFHeap, counter++);
        threeArray[index] = Three::make(aAndFHeap, counter++);
        sixArray[index] = Six::make(aAndFHeap, counter++);
        thirteenArray[index] = Thirteen::make(aAndFHeap, counter++);
        twentyFiveArray[index] = TwentyFive::make(aAndFHeap, counter++);
    }

    for (int i2 = 25; i2 < 50 ; i2++) {
        delete zeroArray[i2];
        aAndFHeap->free(zeroArray[i2]);
        delete twoArray[i2];
        aAndFHeap->free(twoArray[i2]);
    }

    for (int i3 = 0; i3 < 40 ; i3 += 2) {
        delete threeArray[i3];
        aAndFHeap->free(threeArray[i3]);
        delete thirteenArray[i3];
        aAndFHeap->free(thirteenArray[i3]);
    }

    for (int i4 = 0; i4 < 50 ; i4++) {
        delete oneArray[i4];
        aAndFHeap->free(oneArray[i4]);
        delete twentyFiveArray[i4];
        aAndFHeap->free(twentyFiveArray[i4]);
    }

    for (int i5 = 50; i5 < 100 ; i5++) {
        zeroArray[i5] = Zero::make(aAndFHeap, counter++);
        oneArray[i5] = One::make(aAndFHeap, counter++);
        twoArray[i5] = Two::make(aAndFHeap, counter++);
        threeArray[i5] = Three::make(aAndFHeap, counter++);
        sixArray[i5] = Six::make(aAndFHeap, counter++);
        thirteenArray[i5] = Thirteen::make(aAndFHeap, counter++);
        twentyFiveArray[i5] = TwentyFive::make(aAndFHeap, counter++);
    }

    /*  enumerate the live ones */
    aStream << "\n The heap should be interesting: \n";
    LiveHeaperStepper * stepper = aAndFHeap->stepper();
    for (Heaper * aLive = stepper->fetch()
         ; aLive != NULL
         ; stepper->step(), aLive = stepper->fetch()) {
             aLive->printOn(aStream);
             aStream << "\n";
         }
    delete stepper;

    aStream << "\ndestruct the heap, next test should see if the pages get re-used.\n";
    delete aAndFHeap;
}

void reuseExerciseOn(ostream& aStream)
{
    aStream << "\nreuse the heap, what happens?  (expect no sbrk() calls.)\n";

    BibopHeap * reuseHeap = new BibopHeap(128, 4);
    Int32 counter = 0;
    Zero* zeroArray[40];
    One* oneArray[40];
    Two* twoArray[40];
    Three* threeArray[40];
    Six* sixArray[40];
    Thirteen* thirteenArray[40];
    TwentyFive* twentyFiveArray[40];

    for (int i = 0; i < 40 ; i++) {
        zeroArray[i] = Zero::make(reuseHeap, counter++);
        oneArray[i] = One::make(reuseHeap, counter++);
        twoArray[i] = Two::make(reuseHeap, counter++);
        threeArray[i] = Three::make(reuseHeap, counter++);
        sixArray[i] = Six::make(reuseHeap, counter++);
        thirteenArray[i] = Thirteen::make(reuseHeap, counter++);
        twentyFiveArray[i] = TwentyFive::make(reuseHeap, counter++);
    }

    /*  enumerate the live ones */
    aStream << "\n The heap should be interesting: \n";
    LiveHeaperStepper * stepper = reuseHeap->stepper();
    for (Heaper * aLive = stepper->fetch()
         ; aLive != NULL
         ; stepper->step(), aLive = stepper->fetch()) {
             aLive->printOn(aStream);
             aStream << "\n";
         }
    delete stepper;

    delete reuseHeap;
    aStream << "End of Reuse test\n";
}

void freeExerciseOn(ostream& aStream)
{
    BibopHeap * freeHeap = new BibopHeap(128, 4);
    Int32 counter = 0;
    Zero* zeroArray[40];
    One* oneArray[40];
    Two* twoArray[40];
    Three* threeArray[40];
    Six* sixArray[40];
    Thirteen* thirteenArray[40];
    TwentyFive* twentyFiveArray[40];

    for (int i = 0; i < 10 ; i++) {
        zeroArray[i] = Zero::make(freeHeap, counter++);
        oneArray[i] = One::make(freeHeap, counter++);
        twoArray[i] = Two::make(freeHeap, counter++);
        threeArray[i] = Three::make(freeHeap, counter++);
        sixArray[i] = Six::make(freeHeap, counter++);
        thirteenArray[i] = Thirteen::make(freeHeap, counter++);
        twentyFiveArray[i] = TwentyFive::make(freeHeap, counter++);
    }

    aStream << "\nfreeing random pointers (three of them).\n";
    freeWithBlastShield(aStream, freeHeap, freeHeap);
    freeWithBlastShield(aStream, freeHeap, aStream);
    freeWithBlastShield(aStream, freeHeap, &freeHeap);

    aStream << "\nfreeing pointers multiply.\n";

    aStream << "\nfreeing a zero...";
    freeHeap->free(zeroArray[5]);
    aStream << "and free it again: ";
    freeWithBlastShield(aStream, freeHeap, zeroArray[5]);

    aStream << "\nfreeing a one...";
    freeHeap->free(oneArray[5]);
    aStream << "and free it again: ";
    freeWithBlastShield(aStream, freeHeap, oneArray[5]);

    aStream << "\nfreeing a two...";
    freeHeap->free(twoArray[5]);
    aStream << "and free it again: ";
    freeWithBlastShield(aStream, freeHeap, twoArray[5]);

    aStream << "\nfreeing a three...";
    freeHeap->free(threeArray[5]);
    aStream << "and free it again: ";
    freeWithBlastShield(aStream, freeHeap, threeArray[5]);

    aStream << "\nfreeing a six...";
    freeHeap->free(sixArray[5]);
    aStream << "and free it again: ";
    freeWithBlastShield(aStream, freeHeap, sixArray[5]);

    aStream << "\nfreeing a thirteen...";
    freeHeap->free(thirteenArray[5]);
    aStream << "and free it again: ";
    freeWithBlastShield(aStream, freeHeap, thirteenArray[5]);

    aStream << "\nfreeing a twentyFive...";
    freeHeap->free(twentyFiveArray[5]);
    aStream << "and free it again: ";
    freeWithBlastShield(aStream, freeHeap, twentyFiveArray[5]);

    aStream << "\nfreeing pointers before the beginning of a page (expect 30):\n";
    void * ptr = threeArray[0];
    for (char * pageBeginPtr = ((char *)ptr) - sizeof(struct BibopPage) - 6
             ; pageBeginPtr < (void *)threeArray[0]
             ; pageBeginPtr++) {
        freeWithBlastShield(aStream, freeHeap, pageBeginPtr);
    }

    aStream << "\nfreeing the pointer at the beginning of the page...";
    freeHeap->free(threeArray[0]);
    aStream << "and free it again: ";
    freeWithBlastShield(aStream, freeHeap, threeArray[0]);

    aStream << "\nfreeing pointers just after the beginning of the page (expect 19 blasts):\n";
    ptr = threeArray[0];
    for (pageBeginPtr = ((char *)ptr) + 1
             ; pageBeginPtr < (void *)threeArray[1]
             ; pageBeginPtr++) {
        freeWithBlastShield(aStream, freeHeap, pageBeginPtr);
    }

    ptr = threeArray[9];
    aStream << "\nfreeing pointers near the high water mark (expect 39 blasts):\n";
    for (char * highWaterPtr = (char *)ptr + 1
             ; highWaterPtr < ((char *)threeArray[9]) + (2 * sizeof(struct Three))
             ; highWaterPtr++) {
        freeWithBlastShield(aStream, freeHeap, highWaterPtr);
    }

    delete freeHeap;
}

void freeWithBlastShield(ostream& o, BibopHeap * heap, void * ptr)
{
    INSTALL_SHIELD(freeShield);
    SHIELD_UP_BEGIN(freeShield, MemAllocFilter) {
        o << "Memory Alloc Error (as expected)\n";
        return;
    } SHIELD_UP_END(freeShield);
    heap->free(ptr);
    o << "PROBLEM:  No Alloc Error Blast!\n";
} 

void pointerCheckExerciseOn(ostream& aStream)
{
    BibopHeap * pcHeap = new BibopHeap(128, 4);
    Int32 counter = 0;
    One* oneArray[40];

    for (int i = 0; i < 20 ; i++) {
        oneArray[i] = One::make(pcHeap, counter++);
    }

    for (int i2 = 5; i < 10 ; i++) {
        delete oneArray[i2];
        pcHeap->free(oneArray[i2]);
    }

    aStream << "\nChecking pointers at the beginning of a page.  Expect 30 invalid, then one valid.\n";
    void * ptr = oneArray[0];
    for (char * pageBeginPtr = ((char *)ptr) - sizeof(struct BibopPage) - 6
             ; pageBeginPtr <= (void *)oneArray[0]
             ; pageBeginPtr++) {
                 checkPointer(aStream, pcHeap, pageBeginPtr);
    }

    aStream << "\nChecking live and dead pointers (expect 1 valid in the middle of many insides):\n";
    ptr = oneArray[4]; 
   for (char * livedeadPtr = ((char *)ptr) + 1
             ; livedeadPtr < (void *)oneArray[6]
             ; livedeadPtr++) {
                 checkPointer(aStream, pcHeap, livedeadPtr);
    }

    ptr = oneArray[19];
    aStream << "\nChecking pointers near the high water mark"
            << "\n  (expect 1 valid, then its contents, and then invalid memory):\n";
    for (char * highWaterPtr = (char *)ptr
             ; highWaterPtr < ((char *)oneArray[19]) + (2 * sizeof(struct One))
             ; highWaterPtr++) {
                 checkPointer(aStream, pcHeap, highWaterPtr);
    }

    aStream << "\n\nCheck a pointer, reset the high water mark, and check again:\n";
    checkPointer(aStream, pcHeap, oneArray[1]);
    BibopPage::fetchPageForPointer(oneArray[1])->resetHighWaterMark();
    checkPointer(aStream, pcHeap, oneArray[1]);

    delete pcHeap;
}

void checkPointer(ostream& o, BibopHeap * heap, void * ptr)
{
    if (heap->isAValidHeaper(ptr)) {
        if (heap->fetchContainer(ptr) == ptr) {
            o << "It is Valid\n";
        } else {
            o << "ERROR: It claims to be valid, but isn't a container\n";
        }
    } else {
        if (heap->fetchContainer(ptr) == NULL) {
            o << "It isn't part of a live object\n";
        } else {
            o << "It points inside a live object\n";
        }
    }
}


/* ************************************************************************ *
 * 
 *                    Sample Objects
 *
 * ************************************************************************ */

void Zero::printOn(ostream& o)
{
    o << "A zero";
}

Zero * Zero::make(BibopHeap * aHeap, Int32)
{
    void * chunk = aHeap->alloc(sizeof(Zero));
    return new (chunk) Zero();
}

One::One(Int32 n, TCSJ)
{
    myFirst = n;
}

void One::printOn(ostream& o)
{
    o << "A One: " << myFirst;
}

One * One::make(BibopHeap * aHeap, Int32 index)
{
    void * chunk = aHeap->alloc(sizeof(One));
    return new (chunk) One(index, tcsj);
}

Two::Two(Int32 a, TCSJ)
{
    myFirst = mySecond = a;
}

void Two::printOn(ostream& o)
{
    o << "A Two: " << myFirst << ", " << mySecond ;
}

Two * Two::make(BibopHeap * aHeap, Int32 a)
{
    void * chunk = aHeap->alloc(sizeof(Two));
    return new (chunk) Two(a, tcsj);
}

Three::Three(Int32 a, TCSJ)
{
    myFirst = mySecond = myThird = a;
}

void Three::printOn(ostream& o)
{
    o << "A Three: " << myFirst << ", " << mySecond << ", " << myThird;
}

Three * Three::make(BibopHeap * aHeap, Int32 a)
{
    void * chunk = aHeap->alloc(sizeof(Three));
    return new (chunk) Three(a, tcsj);
}

Six::Six(Int32 a, TCSJ)
{
    myFirst = mySecond = myThird = myFourth = myFifth = mySixth = a; 
}

void Six::printOn(ostream& o)
{
    o << "A Six: " << myFirst;
}

Six * Six::make(BibopHeap * aHeap, Int32 a)
{
    void * chunk = aHeap->alloc(sizeof(Six));
    return new (chunk) Six(a, tcsj);
}

Thirteen::Thirteen(Int32 a, TCSJ)
{
    myFirst = mySecond = myThird = myFourth = myFifth = a;
    my6 = my7 = my8 = my9 = my10 = my11 = my12 = my13 = a;
}

void Thirteen::printOn(ostream& o)
{
    o << "A Thirteen: " << myFirst;
}

Thirteen * Thirteen::make(BibopHeap * aHeap, Int32 a)
{
    void * chunk = aHeap->alloc(sizeof(Thirteen));
    return new (chunk) Thirteen(a, tcsj);
}

TwentyFive::TwentyFive (Int32 a, TCSJ)
{
    myFirst = mySecond = myThird = myFourth = a;
    myFifth = my6 = my7 = my8 = my9 = my10 = my11 = a;
    my12 = my13 = my14 = my15 = my16 = my17 = my18 = a;
    my19 = my20 = my21 = my22 = my23 = my24 = my25 = a;
}

void TwentyFive::printOn(ostream& o)
{
    o << "A TwentyFive: " << myFirst;
}

TwentyFive * TwentyFive::make(BibopHeap * aHeap, Int32 a)
{
    void * chunk = aHeap->alloc(sizeof(TwentyFive));
    return new (chunk) TwentyFive(a, tcsj);
}

void Live::operator delete (void* p)
{

}
