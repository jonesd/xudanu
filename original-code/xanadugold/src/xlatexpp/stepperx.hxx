/* Copyright Xanadu Operating Company.  All Rights Reserved. */

/******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
***************************************************************************
Output from Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989
*/

#ifndef STEPPERX_HXX
#define STEPPERX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERP_OXX
#include "stepperp.oxx"
#endif /* STEPPERP_OXX */


/*  */
/*  */
#ifdef MANUAL_CRUTCH
#	define BEGIN_FOR_EACH(TYPE,VAR,EXPR) {						\
		SPTR(Stepper) OF(TYPE) loop_Stepper = (EXPR);			\
		SPTR(TYPE) VAR;												\
		while ((VAR = CAST(TYPE,loop_Stepper->fetch())) != NULL ) {


#define END_FOR_EACH											\
			loop_Stepper->step();									\
		}															\
		loop_Stepper->destroy();									\
	}
#else /* MANUAL_CRUTCH */

#	define BEGIN_FOR_EACH(TYPE,VAR,EXPR) {					\
		SPTR(TYPE) VAR;											\
		for(SPTR(Stepper) OF(TYPE) loop_Stepper = (EXPR);		\
				loop_Stepper->hasValue();							\
				loop_Stepper->step()) {							\
			VAR = CAST(TYPE,loop_Stepper->fetch());	


#define END_FOR_EACH											\
		}															\
		loop_Stepper->destroy();									\
	}
#endif /* MANUAL_CRUTCH */

#ifdef MANUAL_CRUTCH

#	define BEGIN_FOR_POSITIONS(TYPE1,POSITION,TYPE2,VALUE,EXPR) {						\
		SPTR(TableStepper) OF(TYPE1) loop_Stepper = CAST(TableStepper,(EXPR));		\
		SPTR(TYPE1) POSITION;											\
		SPTR(TYPE2) VALUE;										\
		while ( loop_Stepper->hasValue() ) {						\
			POSITION = CAST(TYPE1,loop_Stepper->position());				\
			VALUE = CAST(TYPE2,loop_Stepper->fetch());	
			
#define END_FOR_POSITIONS				\
			loop_Stepper->step();				\
		}										\
		loop_Stepper->destroy();				\
	}

#	define BEGIN_FOR_INDICES(INDEX,TYPE2,VALUE,EXPR) {						\
		SPTR(TableStepper) OF(TYPE1) loop_Stepper = CAST(TableStepper,(EXPR));		\
		IntegerVar INDEX;											\
		SPTR(TYPE2) VALUE;										\
		while ( loop_Stepper->hasValue() ) {						\
			INDEX = loop_Stepper->index();				\
			VALUE = CAST(TYPE2,loop_Stepper->fetch());	
			
#define END_FOR_INDICES				\
			loop_Stepper->step();				\
		}										\
		loop_Stepper->destroy();				\
	}

#else /* MANUAL_CRUTCH */

#	define BEGIN_FOR_POSITIONS(TYPE1,POSITION,TYPE2,VALUE,EXPR) {			\
		SPTR(TYPE1) POSITION;											\
		SPTR(TYPE2) VALUE;										\
		for(	 SPTR(TableStepper) OF(TYPE1) loop_Stepper = CAST(TableStepper,(EXPR));		\
				loop_Stepper->hasValue();							\
				loop_Stepper->step()) {							\
			POSITION = CAST(TYPE1,loop_Stepper->position());				\
			VALUE = CAST(TYPE2,loop_Stepper->fetch());

#define END_FOR_POSITIONS				\
		}										\
		loop_Stepper->destroy();				\
	}

#	define BEGIN_FOR_INDICES(INDEX,TYPE2,VALUE,EXPR) {			\
		IntegerVar INDEX;											\
		SPTR(TYPE2) VALUE;										\
		for(	 SPTR(TableStepper) OF(TYPE1) loop_Stepper = CAST(TableStepper,(EXPR));		\
				loop_Stepper->hasValue();							\
				loop_Stepper->step()) {							\
			INDEX = loop_Stepper->index();				\
			VALUE = CAST(TYPE2,loop_Stepper->fetch());

#define END_FOR_INDICES				\
		}										\
		loop_Stepper->destroy();				\
	}

#endif /* MANUAL_CRUTCH */




/* ************************************************************************ *
 * 
 *                    Class Accumulator 
 *
 * ************************************************************************ */




	/* An Accumulator is a thing which collects a sequence of 
	objects one at a time for some purpose.  Typically, this 
	purpose is to construct a new object out of all the collected 
	objects.  When used in this way, one can think of the 
	Accumulator as being sort of like a pseudo-constructor which 
	is spread out in time, and whose arguments are identified by 
	the sequence they occur in.  Accumulators are typically used in loops.
		
		A (future) example of an Accumulator which is not like "a 
	pseudo-constructor spread out in time" is a communications 
	stream between two threads (or even coroutines) managed by an 
	Accumulator / Stepper pair.  The producer process produces by 
	putting objects into his Accumulator, and the consuming 
	process consumes by pulling values out of his Stepper.  If 
	you want to stretch the analogy, I suppose you can see the 
	Accumulator of the pair as a pseudo-constructor which 
	constructs the Stepper, but *overlapped* in time.
		
		It is normally considered bad style for two 
	methods/functions to be pointing at the same Acumulator.  As 
	long as Accumulators are used locally and without aliasing 
	(i.e., as if they were pass-by-value Vars), these 
	implementationally side-effecty objects can be understood 
	applicatively.  If a copy of an Accumulator can be passed 
	instead of a pointer to the same one, this is to be prefered. 
	 This same comment applies even more so for Steppers.
		
		Example:  To build a set consisting of some transform of the 
	elements of an existing set (what Smalltalk would naturally 
	do with "collect:"), a natural form for the loop would be:
		
		SPTR(Accumulator) acc = setAccumulator();
		FOR_EACH(Heaper,each,oldSet->stepper(), {
			acc->step (transform (each));
		});
		return CAST(ImmuSet,acc->value());
		
		See class Stepper for documentation of FOR_EACH. */

class Accumulator : public Heaper {

/* Attributes for class Accumulator */
	DEFERRED(Accumulator)
	EQ(Accumulator)
	NO_GC(Accumulator)
  public: /* creation */

	/* An accumulator that returns a PtrArray of the object put 
	into it, in sequence */
	
	static INLINE RPTR(Accumulator) ptrArray ();
	
  public: /* deferred operations */

	/* Accumulate a new object into the Accumulator */
	
	virtual void step (APTR(Heaper) ARG(someObj)) DEFERRED_SUBR;
	
	/* Return the object that results from accumulating all those 
	objects */
	
	virtual RPTR(Heaper) value () DEFERRED_FUNC;
	
  public: /* deferred creation */

	/* Return a new Accumulator just like the current one, except that 
		from now on they accumulate separately */
	
	virtual RPTR(Accumulator) copy () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	Accumulator();

};  /* end class Accumulator */



/* ************************************************************************ *
 * 
 *                    Class Stepper 
 *
 * ************************************************************************ */



/* Initializers for Stepper */







	/* Steppers provide a common way to enumerate the elements of 
	any abstraction which acts as a collection.  This simplifies 
	the protocols of the various collection classes, as they now 
	merely have to provide messages to create the appropriate 
	steppers, which then handle the rest of the job.  Also, the 
	Stepper steps over the set of elements which existed *at the 
	time* the stepper was returned.  If you're stepping over the 
	elements of a changable collection, and the elements are 
	changing while you are stepping, any other rule could lead to 
	confusion.
		
		Smalltalk's collections provide the protocol to enumerate 
	their elements directly.  Having the collection change during 
	stepping is the source of a famous Smalltalk bug. Clu and 
	Alphard both have "Iterators" which are much like our 
	Steppers, but these other languages both specify (as a 
	pre-condition) that the collection not be changed while the 
	Iterator is active.  This burdens the programmer with 
	ensuring a non-local property that we know of know way of 
	robustly checking for in real programs.
		
		Steppers and Accumulators are sort of duals.  Steppers are 
	typically used in loops as a source of values to be consumed 
	by the loop body.  Accumulators are typically used as a sink 
	for values which are produced in the loop body.  One can (and 
	sometimes does) interact with a Stepper explicitly through 
	its protocol.  However, for the typical case of just 
	executing a loop body in turn for each successive element 
	should be written using the FOR_EACH macro.  The syntax of 
	the macro is:
		
		FOR_EACH(ElementType,varName, (stepperValuedExpr), {
			Loop body (varName is in scope)
			});
		
		For example:
		
		FOR_EACH(Position,each,(reg->stepper()), {
			doSomethingWith (each);
			});
			
		is roughly equivalent to (see macro definition for exact equivalence):
		
		for(SPTR(Stepper) stomp = reg->stepper(); stomp->hasValue(); 
	stomp->step()) {
			SPTR(Position) each = CAST(Position,stomp->fetch());
			doSomethingWith (each);
		}
		stomp->destroy();
		
		Since the Stepper is necessarily exhausted if we fall out 
	the end of a FOR_EACH, and there isn't anything useful we can 
	do with an exhausted stepper, it's no great loss for FOR_EACH 
	to destroy it.  Doing so substantially unburdens the garbage 
	collector.  In addition, the means we are planning to use to 
	lower the overhead of having the Stepper step over a snapshot 
	of the collection depends on (for its efficiency) the Stepper 
	being destroyed promptly if it is dropped without stepping it 
	to exhaustion.
		
		Not all Steppers will eventually terminate.  For example, a 
	Stepper which enumerates all the primes is perfectly 
	reasonable.  When using Steppers (and especially FOR_EACH), 
	you should be confident that you haven't just introduced an 
	infinite loop into your program.  See Stepper::hasValue().
		
		It is normally considered bad style for two 
	methods/functions to be pointing at the same Stepper.  As 
	long as Steppers are used locally and without aliasing (i.e., 
	as if they were pass-by-value Vars), these implementationally 
	side-effecty objects can be understood applicatively.  If a 
	copy of an Stepper can be passed instead of a pointer to the 
	same one, this is to be prefered.  See Accumulator.
		
		Subclasses of Stepper can provide more protocol.  See TableStepper. */

class Stepper : public Heaper {

/* Attributes for class Stepper */
	DEFERRED(Stepper)
	ON_CLIENT(Stepper)
	EQ(Stepper)
	NO_GC(Stepper)

/* Initializers for Stepper */



friend class INIT_TIME_NAME(Stepper,initTimeNonInherited);

  public: /* pseudo constructors */

	/* A Stepper which is born exhausted.  Useful for 
	implementing empty collections */
	
	static INLINE RPTR(Stepper) emptyStepper ();
	
	/* A Stepper which will enumerate only this one element. 
	Useful for implementing 
		singleton collections. */
	
	static RPTR(Stepper) itemStepper (APTR(Heaper) ARG(item));
	
  public: /* create */

	/* Return a new stepper which steps independently of me, but 
	whose current value is the same as mine, and which must 
	produce a future history of values which satisfies the same 
	obligation that my contract obligates me to produce now. 
	Typically, this will mean that he must produce the same 
	future history that I'm going to produce. However, let's say 
	that I am enumerating the elements of a partial order in some 
	full order which is consistent with the partial order. If a 
	copy of me is made after I'm part way through, then me and my 
	copy may produce any future history compatable both with the 
	partial order and the elements I've already produced by the 
	time of the copy. Of course, a subclass or a Stepper creating 
	message (like IntegerRegion::stepper()) may specify the more 
	stringent requirement (that a copy must produce the same sequence). 
		To prevent aliasing, Steppers should typically be passed by 
	copy. See class comment. */
	
	virtual CLIENT RPTR(Stepper) copy () DEFERRED_FUNC;
	
  public: /* operations */

	/* Iff I have a current value (i.e. this message returns 
	FALSE), then I am not exhasted. 'fetch' and 'get' will both 
	return this value, and I can be 'step'ped to my next state. 
	As I am stepped, eventually I may become exhausted (the 
	reverse of all the above), which is a permanent condition. 
		
		Note that not all steppers have to be exhaustable. A Stepper 
	which enumerates all primes is perfectly reasonable. Assuming 
	otherwise will create infinite loops.  See class comment. */
	
	virtual CLIENT BooleanVar atEnd ();
	
	/* If I am exhausted (i.e., if (! this->hasValue())), then 
	return NULL. Else return 
		current element.  I return wimpily since most items returned 
	are held by collections.
		If I create a new object, I should cache it. */
	
	virtual WPTR(Heaper) fetch () DEFERRED_FUNC;
	
	/* Essential.  BLAST if exhasted.  Else return current 
	element. I return wimpily since most items returned are held 
	by collections. If I create a new object, I should cache it. */
	
	virtual CLIENT WPTR(Heaper) get ();
	
	/* Iff I have a current value (i.e. this message returns 
	true), then I am not 
		exhasted. 'fetch' and 'get' will both return this value, and 
	I can be 'step'ped to 
		my next state. As I am stepped, eventually I may become 
	exhausted (the 
		reverse of all the above), which is a permanent condition. 
		
		Note that not all steppers have to be exhaustable. A Stepper which 
		enumerates all primes is perfectly reasonable. Assuming 
	otherwise will create 
		infinite loops.  See class comment. */
	
	virtual BooleanVar hasValue () DEFERRED_FUNC;
	
	/* Essential.  If I am currently exhausted (see 
	Stepper::hasValue()), then it is an error to step me. The 
	result of doing so isn't currently specified (we probably 
	should specify it to BLAST, but I know that the 
	implementation doesn't currently live up to that spec). 
		
		If I am not exhausted, then this advances me to my next 
	state. If my current value (see Stepper::get()) was my final 
	value, then I am now exhausted, otherwise my new current 
	value is the next value. */
	
	virtual CLIENT void step () DEFERRED_SUBR;
	
	/* Collects the remaining elements in the stepper into an 
	array. Returns an array of no more than count elements (or 
	some arbitrary chunk if the count is negative). The fact that 
	you got fewer elements that you asked for does not mean that 
	the stepper is atEnd, since there may be some reason to break 
	the result up into smaller chunks; you should always check. */
	
	virtual CLIENT RPTR(PrimArray) stepMany (Int32 ARG(count) = -1);
	
	/* If there is precisely one element in the stepper return 
	it; if not, blast without changing the state of the Stepper */
	
	virtual CLIENT RPTR(Heaper) theOne ();
	

	/* automatic 0-argument constructor */
  public:
	Stepper();


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static WPTR(Stepper) TheEmptyStepper;
};  /* end class Stepper */



/* ************************************************************************ *
 * 
 *                    Class   TableStepper 
 *
 * ************************************************************************ */




	/* For enumerating the key->value associations of a table.  A 
	typical use (for a table whose range elements were all Foos) might be:
		
		SPTR(TableStepper) stomp = table->stepper();
		FOR_EACH(Foo,f,stomp, {
			doSomethingWith(stomp->key(), z);
		});
		
		Each iteration of the loop would correspond to an 
	association of the table (snapshotted at the time 
	"->stepper()" was sent).  For each association, "f" (a 
	pointer to Foo) points at the range element, while 
	"stomp->key()" provides the domain element.  See ScruTable::stepper. */

class TableStepper : public Stepper {

/* Attributes for class TableStepper */
	DEFERRED(TableStepper)
	ON_CLIENT(TableStepper)
	NO_GC(TableStepper)
  public: /* creation */

	/* Note: this being a low level operation, and there being no 
	lightweight form of immutable or lazily copied PtrArray, it 
	is my caller's responsibility to pass me a PtrArray which 
	will in fact not be changed during the life of this stepper.  
	This is an unchecked an uncheckable precondition on my clients. */
	
	static INLINE RPTR(TableStepper) ascending (APTR(PtrArray) ARG(array));
	
	/* Note: this being a low level operation, and there being no 
	lightweight form of immutable or lazily copied PtrArray, it 
	is my caller's responsibility to pass me a PtrArray which 
	will in fact not be changed during the life of this stepper.  
	This is an unchecked an uncheckable precondition on my clients. */
	
	static INLINE RPTR(TableStepper) descending (APTR(PtrArray) ARG(array));
	
  public: /* special */

	/* Unboxed version of TableStepper::key.  See class comment 
	in XuInteger. */
	
	virtual IntegerVar index ();
	
	/* A TableStepper actually enumerates the associations of a 
	table. Through the normal Stepper protocol, it makes 
	available the range element of the current association. 
	Through this additional protocol, it make accessible the key 
	of the current association.  This message returns the same 
	object as TwoStepper::other, the only difference being the 
	static knowledge that it's a Position. */
	
	virtual CLIENT RPTR(Position) position () DEFERRED_FUNC;
	
  public: /* create */

	
	virtual RPTR(Stepper) copy () DEFERRED_FUNC;
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch () DEFERRED_FUNC;
	
	
	virtual BooleanVar hasValue () DEFERRED_FUNC;
	
	
	virtual void step () DEFERRED_SUBR;
	
	/* An array of the remaining elements in alternating 
	positions in the array
			[k1, v1, k2, v2, k3, v3, ...]
		Returns an array of up to count * 2 elements (or some 
	arbitrary number if count is negative), and steps the stepper 
	the corresponding number of times. You should check whether 
	the stepper is atEnd, since it can stop before the number you 
	give it because of some internal limit or grouping issue. */
	
	virtual CLIENT RPTR(PrimArray) stepManyPairs (Int32 ARG(count) = -1);
	

	/* automatic 0-argument constructor */
  public:
	TableStepper();

};  /* end class TableStepper */


#ifdef USE_INLINE
#ifndef STEPPERX_IXX
#include "stepperx.ixx"
#endif /* STEPPERX_IXX */


#endif /* USE_INLINE */


#endif /* STEPPERX_HXX */

