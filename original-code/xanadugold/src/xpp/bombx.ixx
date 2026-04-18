/* ========================================================================== */
//
//      Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
//
/* ========================================================================== */
//
// The information contained herein is confidential, proprietary to Xanadu
// Operating Company, and considered a trade secret as defined in section
// 499C of the penal code of the State of California.
//
// Use of this information by anyone other than authorized employees of
// Xanadu is granted only under a written nondisclosure agreement,
// expressly prescribing the scope and manner of such use.
//
// The above copyright notice is not to be construed as evidence of
// publication or the intent to publish.
//
/* ========================================================================== */
//
//                              bombx.ixx
//
//      Executables and globals for the objects supporting the Bomb macros.
//
//              By Michael McClary              1989
//
/* ========================================================================== */
//
//      Made << into opreator<< in one palace to avoid ambiguity with libg++
//              -roger Jan 12 1995
//
//      Initial inlining
//              -eric Apr 30 1991
//
//      Changed from arming-ordered detonation to construction-ordered
//      detonation.  (This matches the implementation that can be built on
//      the proposed standard, and works natuarally with a single-linked
//      list, eliminating two member variables and considerable overhead
//      in BombSuperclass and its children (i.e. strong pointers).)
//              - michael Jun 21 1991
//
//      Made bombStringDetonatorP a static member variable (renamed currentP).
//              - michael Feb 27 1992
//
//      Switched to inline bombs.  BUILD_BOMB() stuff moved from cxx to ixx
//              - michael Mar 2 1992

#ifndef BOMBX_IXX
#define BOMBX_IXX

VERSION_ID(bombx_ixx,
           "$Id: bombx.ixx,v 2.5 1992/08/14 22:06:53 shap Exp $")

/* ========================================================================== */
//
//                      the BombSuperclass
//
/* ========================================================================== */
//
//      Constructor:  Clear the "armed" flag.
//
/* ========================================================================== */

INLINE BombSuperclass::
BombSuperclass()
{
        this->bombArmed = FALSE;

        nextP = BombStringDetonator::currentP->firstP;
        BombStringDetonator::currentP->firstP = this;
}

/* ========================================================================== */
//
//      Destructor:  Do the bomb as flow goes out of scope.
//
//      Subclass destructors must this->detonateBomb(LEFT_AREA);
//      Once that's done, this one clips the bomb from the end of the string.
//      (If the bomb is returned (i.e. SPTRs), it may not be at the end.
//       In that case, call a function.)
//
/* ========================================================================== */

INLINE BombSuperclass::
~BombSuperclass()
{
        if (BombStringDetonator::currentP->firstP != this) {
                this->removeFromMidString();
        } else {
                (BombStringDetonator::currentP->firstP = nextP, 0);
                        //// KLUDGE!!!! because of SGI bug as of 5-4-92
        }
}

/* ========================================================================== */
//
//      armBomb():  Arm the bomb object.
//
//       - If already armed, fire it.
//       - set the armed flag.
//
/* ========================================================================== */

INLINE void BombSuperclass::
armBomb()
{
        if (bombArmed) {
                this->detonateBomb(REARMED);
        }
        bombArmed = TRUE;
};

/* ========================================================================== */
//
//      disarmBomb():  Disarm the bomb object.
//
//       - Clear the armed flag.
//
//      (Also called when the object is fired.)
//
/* ========================================================================== */

INLINE void BombSuperclass::
disarmBomb()
{
        bombArmed = FALSE;
}

/* ========================================================================== */
//
//      detonateBomb():  Fire the armed object.
//
//      - Call disarmBomb() to clear the flag.
//
//      The subclass re-defines this to call disarmBomb, then do its
//      own thing.
//
//      Some subclasses don't need to do anything extra, so it is defined
//      here for their benefit - though they can be optimized by defining
//      their destructor to call disarmBomb() directly, rather than
//      detonateBomb(LEFT_AREA).  (inlining should do this automatically)
//
/* ========================================================================== */

INLINE void BombSuperclass::
detonateBomb(SourceOfDetonationSignal)
{
        this->disarmBomb();
}

/* ========================================================================== */
//
//      BUILD_BOMBs for predefined bombs.
//
/* ========================================================================== */
//
//      SHIELD:  Catch a set of exceptions.
//
/* ========================================================================== */

BUILD_BOMB_BEGIN(_shield, Shield *) {
        ;
} BUILD_BOMB_END(_shield);

/* ========================================================================== */
//
//      LOUD_SHIELD:    Same as SHIELD, but also complain on standard error
//
/* ========================================================================== */
// uses operator<< explicitly to avoid ambiguity with libg++ 
BUILD_SMART_BOMB_BEGIN(_lshield, Shield *) {
        if (SOURCE == BLASTING_STOPS) {
                operator<<(cerr, BombStringDetonator::currentP->getProblemInstanceP()); 
                cerr << "\n";
        }
} BUILD_SMART_BOMB_END(_lshield);

/* ========================================================================== */
//
//      ShieldFree Bomb:
//
//      Free the __FILE__ and __LINE__ strings if they came in over the com.
//
/* ========================================================================== */

BUILD_BOMB_BEGIN(ShieldFree, Problem *) {
        CHARGE->freeStrings();
} BUILD_BOMB_END(ShieldFree);

#endif /* BOMBX_IXX */
