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

#ifndef TABLESX_HXX
#define TABLESX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef HASHTABX_OXX
#include "hashtabx.oxx"
#endif /* HASHTABX_OXX */

#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef INTTABX_OXX
#include "inttabx.oxx"
#endif /* INTTABX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/* This file declares the Table classes.  These are the basic X++ collection
classes.  They are designed to be purely collections, with no excess
protocol for ordering or enumeration.  A table is considered to be a collection
which maps from Positions to arbitrary objects (Heapers).  They are
defined as having a coordinate space for the domain.

mumble mumble, more explanation later. */




/* ************************************************************************ *
 * 
 *                    Class Pair 
 *
 * ************************************************************************ */




	/* Sometimes you just want to pass around two things where 
	the language only makes it convenient to pass around one.  I 
	know that the proper object-oriented (or even "structured") 
	thing to do would be to create a type specific to the 
	particular kind of pair which is being used for a particular 
	purpose.  However, sometimes it just seems like too much 
	trouble.  By using Pairs, we import the sins of Lisp.  At 
	least we don't have RPLACA and RPLACD.  Unlike Lisp's cons 
	cell's "car" and "cdr", we call our two parts the "left" part 
	and the "right" part.  "pair(a,b)->left()" yields a and 
	"pair(a,b)->right()" yields b.
		
		Give us feedback: Should Pairs be removed?  Do you know of 
	any justification for them other than a bad simulation of 
	"multiple-return-values" (as in Common Lisp, Forth, Postscript)?
		
		The Pair code is currently in a state of transition.  Old 
	code (which we have yet to fix) uses Pairs with NULLs in 
	their parts.  Pairs will be changed to outlaw this usage.  
	"fetchLeft" and "fetchRight" exist to support this obsolete 
	usage, but will be retired.  Don't use them. */

class Pair : public Heaper {

/* Attributes for class Pair */
	CONCRETE(Pair)
	COPY(Pair,XppCuisine)
	AUTO_GC(Pair)
  public: /* instance creation */

	/* Create a new pair. Since it used to be normal to allow 
	either left or right to be 
	        NULL (it is now obsolete but supported for the 
	moment), and it is impossible to 
	        do a static check, this (normal) pseudo-constructor 
	does a dynamic check. If 
	        you encounter this error, the quick fix is use the 
	obsolete pseudo-constructor 
	        (pairWithNulls). The better fix is to stop using NULLs. */
	
	static RPTR(Pair) make (APTR(Heaper) ARG(left), APTR(Heaper) ARG(right));
	
  public: /* obsolete: creation */

	/* Create a new pair. Either may be NULL in order to support 
	broken old code. */
	
	static RPTR(Pair) pairWithNulls (APTR(Heaper) ARG(left), APTR(Heaper) ARG(right));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* accessing */

	/* Returns the left part.  Lispers may think 'car'. */
	
	virtual RPTR(Heaper) left ();
	
	/* Returns a new pair which is the left-right reversal of me.
		pair(a,b)->reversed() is the same as pair(b,a).
		
		Only works on non-obsolete Pairs--those whose parts are non-NULL */
	
	INLINE RPTR(Pair) reversed ();
	
	/* Returns the right part.  Lispers may think 'cdr'. */
	
	virtual RPTR(Heaper) right ();
	
  public: /* instance creation */

	/* create a new pair */
	
	Pair (APTR(Heaper) ARG(a), APTR(Heaper) ARG(b));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* obsolete: access */

	/* Returns the left part which obsoletely may be NULL */
	
	INLINE RPTR(Heaper) OR(NULL) fetchLeft ();
	
	/* Returns the right part which obsoletely may be NULL */
	
	INLINE RPTR(Heaper) OR(NULL) fetchRight ();
	
  private:
	CHKPTR(Heaper) leftPart;
	CHKPTR(Heaper) rightPart;
};  /* end class Pair */



/* ************************************************************************ *
 * 
 *                    Class ScruTable 
 *
 * ************************************************************************ */


/* exceptions: exceptions */

PROBLEM_LIST(NotInTableFilter,1,(NotInTable));



	/* Please read class comment for ScruSet first.
		
		Like Sets, Tables represent collections of Heapers, and 
	provide protocol for storing, retrieving, and iterating over 
	the collection.  However, Tables in addition provide an 
	organization for the Heapers collected together in the range 
	of a Table:  A Table can also be seen as a collection of 
	associations between keys and values.  A particular Table 
	object has a particular domain coordinateSpace, and all keys 
	in that Table are positions in that coordinate space.  For 
	each position in a Table's coordinate space there is at most 
	one value which it maps to.  This value may be any arbitrary 
	Heaper.  The same Heaper may appear as value for several keys. 
		
		When iterating over the contents of a Table with a Stepper, 
	the normal elements enumerated by the Stepper are values 
	(i.e., range elements) of the Table.  However, 
	ScruTable::stepper returns a TableStepper (a subclass of 
	Stepper) which provides aditional protocol of accessing the 
	key corresponding to the current value.  (see 
	ScruTable::stepper and TableStepper.) */

class ScruTable : public Heaper {

/* Attributes for class ScruTable */
	DEFERRED(ScruTable)
	NO_GC(ScruTable)
  public: /* accessing */

	/* The kind of elements used to index into the table are 
	Positions of this 
		coordinate space. Therefore, the domain of this table is an 
	XuRegion in this 
		coordinate space. */
	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	/* Return the number of domain elements, which is to say, the 
	number of associations.
		'table->count()' should be equivalent to 'table->domain()->count()'.
		
		Used to say: 'Return the number of range elements'.  This 
	seems clearly wrong. */
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	/* Return an XuRegion representing a snapshot of the current domain.  
		'table->domain()->hasMember(p)' iff 'table->fetch(p) != NULL'. */
	
	virtual RPTR(XnRegion) domain () DEFERRED_FUNC;
	
	/* Return the range element at the domain position key. The 
	routine will return 
		NULL if the position is not in the table. */
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	/* Return the range element at the domain position key. BLAST 
	if the position is 
		not in the table. */
	
	virtual RPTR(Heaper) get (APTR(Position) ARG(key));
	
	/* A snapshot of the current range elements of the table 
	collected together into 
		an ImmuSet. */
	
	virtual RPTR(ImmuSet) OF1(Heaper) range ();
	
	/* Return a table which contains only the intersection of 
	this table's domain and 
		the domain specified by 'region'. 
		table->subTable(r)->domain()->isEqual( table->domain()->inter
	sect(r) ). 
		
		It is unspecified whether the resulting table starts as a 
	snapshot of a subset of 
		me, after which we go our own ways; or whether the resulting 
	table is a view 
		onto a subset of me, such that changes to me are also 
	visible to him. Of 
		course, subclasses may specify more. If you want to ensure 
	snapshot behavior, 
		do 'table->subTable(r)->asImmuTable()'. 
		
		NOTE: In the future we may specify snapshot behavior or we 
	may specify view 
		behavior. As a client this shouldn't effect you. However, if 
	you implement a 
		new kind of ScruTable, please let us know. Also, if you have 
	an opinion as to 
		which way you'd like the specification tightened up, please 
	tell us. */
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	
	/* Return a ScruTable with the domain of the receiver 
	transformed by the Dsp. 
		'table->transformedBy(d)->fetch(p)' is equivalent to 
		'table->fetch(d->of(p))'. 
		
		See ScruTable::subTable for caveats regarding whether we 
	return a snapshot 
		or a view. All the same caveats apply. */
	
	virtual RPTR(ScruTable) transformedBy (APTR(Dsp) ARG(dsp));
	
  public: /* testing */

	/* See ScruTable::isEqual */
	
	virtual UInt32 actualHashForEqual ();
	
	/* Returns whether the two ScruTables have exactly the same 
	mapping from 
		keys to values at the moment. 'a->contentsEqual(b)' is equivalent to 
		'a->asImmuTable()->isEqual(b->asImmuTable())'. See 
	ScruTable::contentsEqual */
	
	virtual BooleanVar contentsEqual (APTR(ScruTable) ARG(other));
	
	/* Has the same relationship to contentsEqual that 
	hashForEqual has to isEqual. 
		I.e., if 'a->contentsEqual (b)', then 'a->contentsHash() == 
	b->contentsHash()'. 
		The same complex caveats apply as to the stability and 
	portability of the 
		hash values as apply for hashForEqual.  See ScruSet contentsHash. */
	
	virtual UInt32 contentsHash ();
	
	/* includesKey is used to test for the presence of a 
	key->value pair in the
		table.  This routine returns true if there is a value 
	present at the specified
		key, and false otherwise.
		'table->includesKey(p)' iff 'table->domain()->hasMember(p)'. */
	
	virtual BooleanVar includesKey (APTR(Position) ARG(key));
	
	/* Is there anything in the table? 
		'table->isEmpty()' iff 'table->domain()->isEmpty()'. */
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
	/* All MuTable subclasses have equality based on identity 
		(now and forever equal. Many ScruTable subclasses will 
		represent an aspect of another table. Therefore they have 
		hashForEqual and isEqual: based on both their contained 
		table, and the aspect that they represent. Thus, two similar 
		views onto the same MuTable are now (and forever) equal. 
		The hashForEqual: must use exactly the same aspects for 
		the hash as get used for isEqual:. ImmuTables all use 
		contentBased comparison operations. */
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
  public: /* enumerating */

	/* Return a TableStepper which will enumerate my key->value 
	mappings. The 
		Stepper component of the TableStepper protocol will just 
	enumerate my values 
		(as that is what I'm a container *of*--the keys are simply 
	how I organize my 
		contents). TableStepper provides additional protocol to 
	ascetain the current 
		key. See TableStepper and XuRegion::stepper. The 
	TableStepper I produce given 
		an order must enumerate keys according to the same rules 
	which specify how 
		XuRegion::stepper must enumerate positions. I am not 
	asserting that the actual 
		orders are the same, only that the correctness criteria on 
	the allowable orders 
		are the same. 
		
		Keeping in mind that we are talking about equivalence of 
	specification 
		and not equivalence of particular behavior, the following 
	two statements 
		are equivalent: 
	
		{
			SPTR(TableStepper) stomp = table->stepper(o);
			SPTR(Position) key;
			FOR_EACH(Heaper,val,stomp, {
				key = stomp->key();
				doSomethingWith(key, val);
			});
		}
		
		and
		
		{
			SPTR(Heaper) val;
			SPTR(ImmuTable) snapShot = table->asImmuTable();
			FOR_EACH(Position,key,(snapShot->domain()->stepper(o)), {
				val = snapShot->get (key);
				doSomethingWith(key, val);
			});
		}
				
		 */
	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL) DEFERRED_FUNC;
	
	/* Iff I contain exactly one range element, return it.  
	Otherwise BLAST.
		The idea for this message is taken from the THE function of ONTIC
		(reference McAllester) */
	
	virtual RPTR(Heaper) theOne ();
	
  public: /* conversion */

	/* Return a side-effect-free snapshot of my current contents.
		See ScruSet::asImmuSet. */
	
	virtual RPTR(ImmuTable) asImmuTable () DEFERRED_FUNC;
	
	/* Return a side-effectable version of the same table.
		See ScruSet::asMuSet. */
	
	virtual RPTR(MuTable) asMuTable () DEFERRED_FUNC;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(stream));
	
	/* Print the contents of the table as
		<open> key1 "->" value1 <sep> key2 "->" value2 <sep> ... 
	<sep> keyN "->" valueN <close>.
		For example, 'table->printOnWithSyntax(oo, "{", ", ", "}");' 
	may result in
		'{3->Foo(), 5->Bar()}'.
		
		One wierd but convenient special case: if the domain space 
	is an IntegerSpace, 
		we print the keys according to the way IntegerVars print, not the way 
		XuIntegers print.
		
		For yet more fine-grained control over printing, see the 
	ScruTable::printOnWithSyntax 
		with 5 arguments. */
	
	virtual void printOnWithSimpleSyntax (
			ostream& ARG(oo), 
			char * ARG(open), 
			char * ARG(sep), 
			char * ARG(close))
	;
	
	/* Print the contents of the table as 
		<open> key1 <map> value1 <sep> key2 <map> value2 
		<sep> ... <sep> keyN <map> valueN <close>. 
		For example, 'table->printOnWithSyntax(oo, "{", 
		"=>", ", ", "}");' may result in 
		'{3=>Foo(), 5=>Bar()}'. 
		
		One wierd but convenient special case: if the 
		domain space is an IntegerSpace, 
		we print the keys according to the way IntegerVars 
		print, not the way 
		XuIntegers print. */
	
	virtual void printOnWithSyntax (
			ostream& ARG(stream), 
			char * ARG(open), 
			char * ARG(map), 
			char * ARG(sep), 
			char * ARG(close))
	;
	
  public: /* runs */

	/* Return the length of the run starting at position key. A 
	run is defined as a 
		contiguous (charming) sequence of domain positions mapping 
	to equal (isEqual) 
		objects. Charming is defined as: Given a charming region R, 
	for all a,c which 
		are elements of R and a >= b >= c, b is an element of R. 
	Where '>=' is 
		according to the 'isGE' message. 
		
		NOTE: We may retire the above definition of charming. The 
	possible changes 
		will only effect spaces which aren't fully ordered. OrderedRegions, 
		TreeRegions, and IntegerRegions will be unaffected, as any 
	future definition of 
		'runAt' will be equivalent for them. */
	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
  public: /* creation */

	/* A new one whose initial state is my current state, but 
	that doesn't track 
		changes. Note that there is no implication that these can be 
	'destroy'ed 
		separately, because (for example) an ImmuTable just returns itself */
	
	virtual RPTR(ScruTable) copy () DEFERRED_FUNC;
	
	/* Return an empty table just like the current one. The 
	'size' argument is a hint 
		about how big the count of the table will probably become 
	(so that the new 
		table can be prepared to grow to that size efficiently). */
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size)) DEFERRED_FUNC;
	
  protected: /* protected: creation */

	
	ScruTable ();
	
  public: /* overloads */

	/* Unboxed version.  See class comment for XuInteger */
	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	/* Unboxed version.  See class comment for XuInteger */
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(key));
	
	/* Unboxed version.  See class comment for XuInteger */
	
	virtual RPTR(Heaper) intGet (IntegerVar ARG(key));
	
	/* Unboxed version.  See class comment for XuInteger */
	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(key));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	
	
};  /* end class ScruTable */



/* ************************************************************************ *
 * 
 *                    Class   ImmuTable 
 *
 * ************************************************************************ */




	/* ImmuTable are to ScruTables much like ImmuSets are to 
	ScruSets.  See ImmuSet.
		
		The ImmuTable subclass of tables represents all tables which 
	CANNOT be side-effected during operations on them.  They are 
	intended to represent mathematical abstractions (such as 
	vectors) and are intended to be used in a 
	functional-programming style.  Operations are provided for 
	building new ImmuTables out of old ones. */

class ImmuTable : public ScruTable {

/* Attributes for class ImmuTable */
	DEFERRED(ImmuTable)
	NO_GC(ImmuTable)
  public: /* pseudo constructors */

	/* An empty ImmuTable whose domain space is 'cs'. */
	
	static RPTR(ImmuTable) make (APTR(CoordinateSpace) ARG(cs));
	
	
	static RPTR(ImmuTable) offsetImmuTable (APTR(ImmuTable) ARG(aTable), APTR(Dsp) ARG(aDsp));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) domain () DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(key));
	
	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(key));
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(reg)) DEFERRED_FUNC;
	
	/* Return a ScruTable with the domain of the receiver 
	transformed by the Dsp. 
		'table->transformedBy(d)->fetch(p)' is equivalent to 
		'table->fetch(d->of(p))'. 
		
		See ScruTable::subTable for caveats regarding whether we 
	return a snapshot 
		or a view. All the same caveats apply.
		
		In this case of transforming an ImmuTable, it makes sense to 
	return an ImmuTable. */
	
	virtual RPTR(ScruTable) transformedBy (APTR(Dsp) ARG(dsp));
	
  public: /* creation */

	/* don't need to actually make a copy, as this is immutable */
	
	virtual RPTR(ScruTable) copy ();
	
	/* The idea of a 'size' argument would seem kind of 
	ridiculous here as the resulting empty table can't be changed. */
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size)) DEFERRED_FUNC;
	
  public: /* SEF manipulation */

	/* Similar to unionWith.  In particular, if 'a = 
	b->combineWith(c);', then:
		'a->domain()->isEqual(b->domain()->unionWith(c->domain())' and
		'a->range()->isSubsetOf(b->range()->unionWith(c->range())'.
		(Note that the domain case uses XuRegion::unionWith, while 
	the range case
		uses ImmuSet::unionWith.)
		
		Despite this correspondence, unionWith is symmetrical while 
	combineWith is not.
		Given that the two input tables have different associations 
	for a given key,
		one gets to dominate.  I need to specify which one here, but 
	the code seems
		inconsistent on this question.  Until this is resolved, 
	console youself with the
		thought that if the tables don't conflict we have a simple 
	unionWith of the two
		sets of associations (and the 'isSubsetOf' above can be 
	replaced with 'isEqual'). */
	
	virtual RPTR(ImmuTable) combineWith (APTR(ImmuTable) ARG(other)) DEFERRED_FUNC;
	
	/* Return a new table just like the current one except with 
	the association whose 
		key is 'index'. */
	
	virtual RPTR(ImmuTable) without (APTR(Position) ARG(index)) DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL) DEFERRED_FUNC;
	
  public: /* conversion */

	
	virtual RPTR(ImmuTable) asImmuTable ();
	
	
	virtual RPTR(MuTable) asMuTable () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	ImmuTable();

};  /* end class ImmuTable */



/* ************************************************************************ *
 * 
 *                    Class   MuTable 
 *
 * ************************************************************************ */



/* Initializers for MuTable */


/* exceptions: */

PROBLEM_LIST(AlreadyInTableFilter,1,(AlreadyInTable));

PROBLEM_LIST(NullInsertionFilter,1,(NullInsertion));



	/* MuTable represents the base class for all side-effectable 
	tables.  It provides the basic change protocol for tables.  
	See MuSet. */

class MuTable : public ScruTable {

/* Attributes for class MuTable */
	DEFERRED(MuTable)
	EQ(MuTable)
	COPY(MuTable,XppCuisine)
	NO_GC(MuTable)

/* Initializers for MuTable */
friend class INIT_TIME_NAME(MuTable,initTimeNonInherited);

  public: /* pseudo constructors */

	/* A new empty MuTable whose domain space is 'cs'. */
	
	static RPTR(MuTable) make (APTR(CoordinateSpace) ARG(cs));
	
	/* Semantically identical to 'muTable(cs)'.  'reg' just 
	provides a hint as to what
		part of the domain space the new table should expect to be 
	occupied. */
	
	static RPTR(MuTable) make (APTR(CoordinateSpace) ARG(cs), APTR(XnRegion) ARG(reg));
	
  public: /* accessing */

	/* Associate key with value unless key is already associated 
	with another value.  If so, blast. */
	
	virtual void introduce (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	/* Associate key with value only if key is already associated 
	with a value.  Otherwise blast. */
	
	virtual void replace (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	/* Associate value with key, whether or not there is a 
	previous association.
		  Return the old range element if the position was 
	previously occupied, NULL otherwise */
	
	virtual RPTR(Heaper) store (APTR(Position) ARG(key), APTR(Heaper) ARG(value)) DEFERRED_FUNC;
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) domain () DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	/* Remove a key->value association from the table.
		 Blast if the key is not present. */
	
	virtual void remove (APTR(Position) ARG(anIdx));
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(reg)) DEFERRED_FUNC;
	
	/* Remove a key->value association from the table.
		 Do not blast (or do anything else) if the key is not in my 
	current domain.
		 Return TRUE if the association was present and removed,
		 Return FALSE if the association was not there */
	
	virtual BooleanVar wipe (APTR(Position) ARG(anIdx)) DEFERRED_FUNC;
	
  public: /* bulk operations */

	/* 'MuTable::introduceAll is to 'MuTable::introduce' as 
	'MuTable::storeAll' is to 
		'MuTable::store'.  See MuTable::storeAll.  In addition to 
	the functionality 
		provided by MuTable::storeAll, I BLAST *if* all the 
	associations I'm being
		asked to store override existing associations of mine.  If I 
	BLAST for this
		reason, then I guarantee that I haven't changed myself at all. */
	/* Since this function checks the relavent regions, it can 
	call the potentially 
		more efficient store: */
	
	virtual void introduceAll (
			APTR(ScruTable) ARG(table), 
			APTR(Dsp) ARG(dsp) = NULL, 
			APTR(XnRegion) ARG(region) = NULL)
	;
	
	/* 'MuTable::replaceAll is to 'MuTable::replace' as 
	'MuTable::storeAll' is to 
		'MuTable::store'.  See MuTable::storeAll.  In addition to 
	the functionality 
		provided by MuTable::storeAll, I BLAST *unless* all the 
	associations I'm being
		asked to store override existing associations of mine.  If I 
	BLAST for this
		reason, then I guarantee that I haven't changed myself at all. */
	/* Since this function checks the relavent regions, it can 
	call the potentially 
		more efficient store: */
	
	virtual void replaceAll (
			APTR(ScruTable) ARG(table), 
			APTR(Dsp) ARG(dsp) = NULL, 
			APTR(XnRegion) ARG(region) = NULL)
	;
	
	/* I 'store' into myself (see MuTable::store) all the 
	associations from 'table'.
		If 'region' is provided, then I only store those 
	associations from 'table' whose
		key is inside 'region'.  If 'dsp' is provided, then I 
	transform the keys (from 
		the remaining associations) by dsp before storing into myself. */
	
	virtual void storeAll (
			APTR(ScruTable) ARG(table), 
			APTR(Dsp) ARG(dsp) = NULL, 
			APTR(XnRegion) ARG(region) = NULL)
	;
	
	/* I 'wipe' from myself all associations whose key is in 
	'region'.  See MuTable::wipe */
	
	virtual void wipeAll (APTR(XnRegion) ARG(region));
	
  public: /* testing */

	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL) DEFERRED_FUNC;
	
  public: /* conversion */

	
	virtual RPTR(ImmuTable) asImmuTable ();
	
	/* Note that muTable->asMuTable() returns a copy of the 
	original.  The two
		are now free to change independently. */
	
	virtual RPTR(MuTable) asMuTable ();
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy () DEFERRED_FUNC;
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size)) DEFERRED_FUNC;
	
  protected: /* protected: creation */

	/* Create a new table with an unspecified number of initial 
	domain positions. */
	
	MuTable ();
	
  public: /* overloads */

	/* Unboxed version.  See class comment for XuInteger */
	
	virtual void atIntIntroduce (IntegerVar ARG(key), APTR(Heaper) ARG(value));
	
	/* Unboxed version.  See class comment for XuInteger */
	
	virtual void atIntReplace (IntegerVar ARG(key), APTR(Heaper) ARG(value));
	
	/* Unboxed version.  See class comment for XuInteger */
	
	virtual RPTR(Heaper) atIntStore (IntegerVar ARG(aKey), APTR(Heaper) ARG(anObject));
	
	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(key));
	
	/* Unboxed version.  See class comment for XuInteger */
	
	virtual void intRemove (IntegerVar ARG(anIdx));
	
	/* Unboxed version.  See class comment for XuInteger */
	
	virtual BooleanVar intWipe (IntegerVar ARG(anIdx));
	
	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(index));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	
	
	
/* Friends for class MuTable */
/* friends for class MuTable */
friend class COWMuTable;


};  /* end class MuTable */



/* ************************************************************************ *
 * 
 *                    Class TableAccumulator 
 *
 * ************************************************************************ */




	/* Consider this class's public status as obsolete.  
	Eventually This class will either be private of get retired. */

class TableAccumulator : public Accumulator {

/* Attributes for class TableAccumulator */
	DEFERRED(TableAccumulator)
	NO_GC(TableAccumulator)
  public: /* pseudoConstructors */

	/* Returns an Accumulator which will produce an MuArray of 
	the elements 
		accumulated into it in order of accumulation. See MuArray. 
	Equivalent to 
		'arrayAccumulator()'. Eventually either he or I should be 
	declared obsolete. INLINE */
	
	static RPTR(TableAccumulator) make ();
	
  public: /* deferred operations */

	/* Add elem to the internal table. */
	
	virtual void step (APTR(Heaper) ARG(elem)) DEFERRED_SUBR;
	
	/* Return the accumulated table. */
	
	virtual RPTR(Heaper) value () DEFERRED_FUNC;
	
  public: /* deferred create */

	/* Should this copy the array? */
	
	virtual RPTR(Accumulator) copy () DEFERRED_FUNC;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	

	/* automatic 0-argument constructor */
  public:
	TableAccumulator();

};  /* end class TableAccumulator */


#ifdef USE_INLINE
#ifndef TABLESX_IXX
#include "tablesx.ixx"
#endif /* TABLESX_IXX */


#endif /* USE_INLINE */


#endif /* TABLESX_HXX */

