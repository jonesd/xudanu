/*
      (C) Copyright 1992 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
**************************************************************************** */

static char bibopt_hxx_id[] = "$Id: bibopt.hxx,v 3.6 1993/03/19 21:54:21 hibbert Exp $";

#include "tofux.hxx"
#include "bibopp.hxx"
#include "bibopt.oxx"

void  allTestsOn (ostream& aStream);
void warmUpExerciseOn(ostream& aStream);
void allocAndFreeTestOn(ostream& aStream);
void reuseExerciseOn(ostream& aStream);
void freeExerciseOn(ostream& aStream);
void freeWithBlastShield(ostream& o, BibopHeap * heap, void * ptr);
void pointerCheckExerciseOn(ostream& aStream);
void checkPointer(ostream& o, BibopHeap * heap, void * ptr);

PROBLEM_LIST(MemAllocFilter,1,(MEM_ALLOC_ERROR));

CLASS(Live,Heaper) {
    CONCRETE(Live)
    EQ(Live)
    NO_GC(Live)
  public:
    Live() {}
    virtual void printOn (ostream& o) = 0 /* DEFERRED_FUNC */;
    void operator delete (void *);
};

CLASS(Zero,Live) {
    CONCRETE(Zero)
    EQ(Zero)
    NO_GC(Zero)
  public:
    Zero() {}
    virtual void printOn (ostream& o);
    static Zero * make(BibopHeap * aHeap, Int32);
};

CLASS(One,Live) {
    CONCRETE(One)
    EQ(One)
    NO_GC(One)
  public:
    One(Int32, TCSJ);
    virtual void printOn (ostream& o);
    static One * make(BibopHeap * aHeap, Int32 index);
 private:
    Int32 myFirst;
};

CLASS(Two,Live) {
    CONCRETE(Two)
    EQ(Two)
    NO_GC(Two)
  public:
    Two(Int32, TCSJ);
    virtual void printOn (ostream& o);
    static Two * make(BibopHeap * aHeap, Int32 a);
 private:
    Int32 myFirst;
    Int32 mySecond;
};

CLASS(Three,Live) {
    CONCRETE(Three)
    EQ(Three)
    NO_GC(Three)
  public:
    Three(Int32, TCSJ);
    virtual void printOn (ostream& o);
    static Three * make(BibopHeap * aHeap, Int32 a);
 private:
    Int32 myFirst;
    Int32 mySecond;
    Int32 myThird;
};

CLASS(Six,Live) {
    CONCRETE(Six)
    EQ(Six)
    NO_GC(Six)
  public:
    Six(Int32, TCSJ);
    virtual void printOn (ostream& o);
    static Six * make(BibopHeap * aHeap, Int32 a);
 private:
    Int32 myFirst;
    Int32 mySecond;
    Int32 myThird;
    Int32 myFourth;
    Int32 myFifth;
    Int32 mySixth;
};

CLASS(Thirteen,Live) {
    CONCRETE(Thirteen)
    EQ(Thirteen)
    NO_GC(Thirteen)
  public:
    Thirteen(Int32, TCSJ);
    virtual void printOn (ostream& o);
    static Thirteen * make(BibopHeap * aHeap, Int32 a);
 private:
    Int32 myFirst;
    Int32 mySecond;
    Int32 myThird;
    Int32 myFourth;
    Int32 myFifth;
    Int32 my6;
    Int32 my7;
    Int32 my8;
    Int32 my9;
    Int32 my10;
    Int32 my11;
    Int32 my12;
    Int32 my13;
};

CLASS(TwentyFive,Live) {
    CONCRETE(TwentyFive)
    EQ(TwentyFive)
    NO_GC(TwentyFive)
  public:
    TwentyFive(Int32, TCSJ);
    virtual void printOn (ostream& o);
    static TwentyFive * make(BibopHeap * aHeap, Int32 a);
 private:
    Int32 myFirst;
    Int32 mySecond;
    Int32 myThird;
    Int32 myFourth;
    Int32 myFifth;
    Int32 my6;
    Int32 my7;
    Int32 my8;
    Int32 my9;
    Int32 my10;
    Int32 my11;
    Int32 my12;
    Int32 my13;
    Int32 my14;
    Int32 my15;
    Int32 my16;
    Int32 my17;
    Int32 my18;
    Int32 my19;
    Int32 my20;
    Int32 my21;
    Int32 my22;
    Int32 my23;
    Int32 my24;
    Int32 my25;
};

