$//
$//	Undocumented fixes to make calc run
$//		- May 26 1989
$//	
$//	Modifications for SnarfXcvrs:
$//
$//	 - Revision of Transciever hierarchy to:
$//	   Xcvr->CommXcvr->TextyCommXcvr
$//		- michael Jun 14 1990
$//
$//	Replaced yourCommHandler() with getExistingObject() and
$//	deleteEntryFor().
$//		- michael Jun 19 1990
$//
$//	Fixed PROXYs so ACTUAL --(com)-- PROXY --(com)-- PROXY works.
$//	!!!! NOT TESTED !!!!
$//		- michael Jun 21 1990
$//
$//	Added new RECEIVER and SENDER restart stuff per Markm.
$//	(Also changes in Stubble.lexex.)
$//		- michael Jun 25 1990
$//
$//	Removed SELF_COPY protection type.  (Changes to Stubble.lexex, too)
$//	(Also removed bogus commented-out actualSize method.)
$//	Moved trans->assignNumber() into Xcvr
$//		- michael Jun 28 1990
$//
$//	Merged changes from wjr's:
$//	 - Heaper Proxies are now CHECKED_CLASSes.  (Two places.)
$//	 - delete message now takes deleteObjToo argument (proxy ~ & handler).
$//	 - Proxy now holds commHandler with CHKPTR()
$//		- michael Jul 13 1990
$//
$//    Removed makeProxy declarations and methods.
$//    Added sendProxyTo declatations and methods.
$//		-wjr Jul 22 1990
$//
$//    reduce the size of the proxy methods,
$//    use messageHandler objects instead of writing new classes
$//	    -cth  Aug 18 1990
$//
$//    Reformed Recipes for "become"
$//    Got rid of Var support--added support IntegerVar directly
$//    SP2_+ and CP2_+ handling
$//	-msm Aug 17 1990
$//
$//    Cleaned up scalar cases
$//	-msm Aug 22 1990
$//
$//	Grabbed from Hibbert for merge
$//		-ech Sep 1 1990
$//
$//	Kludged in UInt8[] and char[] send() and receive() stuff.
$//	(Fix it right later!!!!)
$//	 - michael Sep 16 1990
$//
$//	Made calls on entry->setObjTo() conditional on entry non-NULL.
$//	 - michael Sep 20 1990
$//
$//	Undid previous change when Entry* arg added to transmute()
$//	 - michael Oct	1 1990
$//
$//	!!!! Kluged around formic bug by matching $(VAR name: *+) in sendSelfTo
$//	and receiving constructor.  Formic presently puts the '*' as part of the
$//	VAR name, not the type.  When this is fixed these two spots will need to
$//	be undone.
$//	- ech Oct 13 1990  (merged Nov 6 -michael)
$//
$//	Modifcations for backend classes begins.  (Comments moved with
$//	backend code to backend2.hf on Nov 24.)
$//		- michael Oct  2 1990
$//
$//	Fixed RECEIVER section
$//		- michael Nov 11-15 1990
$//
$//	Moved echoed text from stubble script to StubbleForm.f.
$//		- michael Nov 16-17 1990
$//
$//	Reorganized for processing of StubbleForm.f by preprocessor:
$//	 - Added $(VANISH) before preprocessor directives which are to be
$//	   in the output file, rather than processed here.
$//	 - Converted Stubble.lexex into $LEX lines, and renamed it Stubble.hlx
$//	 - Made backend code conditional on definition of WITH_BACKEND_HOOKS
$//	 - Moved backend code to backend[12].hf, related comments to .2.hf
$//		- michael Nov 24 1990
$//
$//	Moved define of VANISH= from stubble script to this file.
$//		- michael Dec 3 1990
$//
$//	added a section to build Unlocked classes.  Also added class 
$//	attribute checks for copy and proxy.
$//		- cth  Dec 9 1990
$//
$//	Converted completely to Class attributes:
$//	  - converted to not use DEFINE_CLASS.
$//		- cth Dec 11 1990
$//
$//	Moved Locking code to server.hf.  Added support for EQ classes. 
$//	Moved Copy code to copy.hf.  Moved proxy code to proxy.hf.  
$//		-cth  Dec 13 1990
$//
$//	Added Package support
$//		-rnp Feb 1991
$//
$//	Added first pass of Become support
$//		-rnp Mar 1 1991
$//
$//	Note about package stuff:  It can't be separated into a 'package.hf'
$//	since it is intertwined with the DEFINE_CLASS stuff - ech
$//
$//
$// MODIFIED FOR NEW FORMIC - rek Nov '91
$//
$// - removed $VANISH - '$#' at beginning of line shields '#' character
$//    from cpp.  Formic treats it as an escape sequence for '#'
$// - changed 'CAPFNAME' to 'FNAME mod: .hxx$/ cap' - i.e. take the file 
$//    name from the 1st #line of the input, delete the final '.hxx' and
$//    capitalize the remainder
$// - changed '$(FOR CLASSES)' to '$(FOR CLASSES infiles)' 
$// - changed 'ATTR attr:' to 'ATTR arg: 1' - this is the second argument
$//    to the class attribute: 0-based indexing, as in 'C--
$// - removed ':'s from all 0-place predicates
$//
$//	Took out Package support
$//		- ech Feb 27 1993
$//
#include "copyrite.hf"
$#ifndef STUBBLEFORM_F_IDENT
VERSION_ID(StubbleForm_f,
	"$$Id: stubblef.f,v 2.12 1993/03/01 21:28:20 eric Exp $$")
$#define STUBBLEFORM_F_IDENT
$#endif /* STUBBLEFORM_F_IDENT */
#include "stubble.hlx"

$#define $(FNAME mod: .hxx$/ cap)_SXX
$//
$(FOR CLASSES infiles)

/*----------------------- BEGIN $(CLASS) -----------------------*/
$//
$(  IF CLASS | attr: DEFERRED attr: CONCRETE)
$//
$(    IF CLASS & attr: DEFERRED attr: CONCRETE)
$#error "$(CLASS) can't be both DEFERRED and CONCRETE"
$(    FI)
$//
$(    FOR ATTRS name: MAY_BECOME)
DEFINE_MAY_BECOME($(CLASS),$(ATTR arg: 1))
$(    ROF)
$//
$(    FOR ATTRS name: MAY_BECOME_ANY_SUBCLASS_OF)
DEFINE_MAY_BECOME_ANY_SUBCLASS_OF($(CLASS),$(ATTR arg: 1))
$(    ROF)
$//
DEFINE_CLASS_CATEGORY($(CLASS),$(CLASS base))
$//
$(  IF CLASS ! attr: NOT_A_TYPE)
DEFINE_OPAQUE_TYPE($(CLASS));
$(  FI CLASS ! attr: NOT_A_TYPE)
$//
$(  IF CLASS attr: CONCRETE)

void $(CLASS)::deferredHack () { /* intentionally blank */ }
$(  FI CLASS attr: CONCRETE)
$//
#include "copy.hf"
$//
$//#ifdef WITH_SERVER_HOOKS
$//#include "server.hf"
$//#endif */ /* WITH_SERVER_HOOKS */
$LEX CLASS_ATTRIBUTE: LOCKED
$LEX CLASS_ATTRIBUTE: DEFERRED_LOCKED
$LEX PRE_METHOD_ATTRIBUTE: NOLOCK
$//
$//
#ifdef WITH_SERVER_HOOKS
#include "backend1.hf"
#include "backend2.hf"
#endif /* WITH_SERVER_HOOKS */
$//
$(  IF CLASS attr: EQ)

BooleanVar $(CLASS)::isEqual (Heaper * other)
{
    return this == other;
}

UInt32 $(CLASS)::actualHashForEqual ()
{
    return Heaper::takeOop ();
}

$(  FI EQ Class)
$//
$(  IF CLASS attr: AUTO_GC)$// ** garbage ** 
$//
/* ====== Object Migrator for Scavenging of $(CLASS) ====== */

void $(CLASS)::
migrate (void * origin, BooleanVar destinationIsOld) {
$(	  IF CLASS | superattr: AUTO_GC superattr: MANUAL_GC)
	this->$(CLASS base)::migrate(origin, destinationIsOld);
$(	  FI)
	if (destinationIsOld) {
$(	    FOR VARS kind: CheckedPtrVar)
		Heaplet::forwardToOld ((Heaper**)&(($(CLASS)*)origin)->$(VAR),
				       (Heaper**)&$(VAR));
$(	    ROF)
	} else {
$(	    FOR VARS kind: CheckedPtrVar)
		$(VAR).forwardTo (Heaplet::forward ($(VAR)));
$(	    ROF)
	}
}
$(  ELSE)
$(    IF CLASS ! | attr: MANUAL_GC attr: NO_GC)
$#error "$(CLASS) must be AUTO_GC or MANUAL_GC or NO_GC"
$(    FI CLASS ! | attr: MANUAL_GC attr: NO_GC)

$(  FI ** garbage ** )
$//
$(FI | attr: DEFERRED attr: CONCRETE)

/*----------------------- END $(CLASS) -----------------------*/

$(ROF)
