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

#ifndef TABLESX_CXX
#define TABLESX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef TABLESX_IXX
#include "tablesx.ixx"
#endif /* TABLESX_IXX */

#ifndef TABLESP_HXX
#include "tablesp.hxx"
#endif /* TABLESP_HXX */

#ifndef TABLESP_IXX
#include "tablesp.ixx"
#endif /* TABLESP_IXX */


#ifndef ARRAYX_HXX
#include "arrayx.hxx"
#endif /* ARRAYX_HXX */

#ifndef HASHTABX_HXX
#include "hashtabx.hxx"
#endif /* HASHTABX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Pair 
 *
 * ************************************************************************ */


/* instance creation */


RPTR(Pair) Pair::make (APTR(Heaper) left, APTR(Heaper) right){
	/* Create a new pair. Since it used to be normal to allow 
	either left or right to be 
	        NULL (it is now obsolete but supported for the 
	moment), and it is impossible to 
	        do a static check, this (normal) pseudo-constructor 
	does a dynamic check. If 
	        you encounter this error, the quick fix is use the 
	obsolete pseudo-constructor 
	        (pairWithNulls). The better fix is to stop using NULLs. */
	
	{	BooleanVar crutch_Flag;
		/* left == NULL || right == NULL */
		
		crutch_Flag = left == NULL;
		if(!crutch_Flag) {
			crutch_Flag = right == NULL;
		}
		if (crutch_Flag) {
			BLAST(ObsoleteUsageMustUsePairWithNulls);
		}
	}
	RETURN_CONSTRUCT(Pair,(left, right));
}
/* obsolete: creation */


RPTR(Pair) Pair::pairWithNulls (APTR(Heaper) left, APTR(Heaper) right){
	/* Create a new pair. Either may be NULL in order to support 
	broken old code. */
	
	RETURN_CONSTRUCT(Pair,(left, right));
}
/* Sometimes you just want to pass around two things where the 
language only makes it convenient to pass around one.  I know that 
the proper object-oriented (or even "structured") thing to do would 
be to create a type specific to the particular kind of pair which is 
being used for a particular purpose.  However, sometimes it just 
seems like too much trouble.  By using Pairs, we import the sins of 
Lisp.  At least we don't have RPLACA and RPLACD.  Unlike Lisp's cons 
cell's "car" and "cdr", we call our two parts the "left" part and the 
"right" part.  "pair(a,b)->left()" yields a and "pair(a,b)->right()" yields b.
	
	Give us feedback: Should Pairs be removed?  Do you know of any 
justification for them other than a bad simulation of 
"multiple-return-values" (as in Common Lisp, Forth, Postscript)?
	
	The Pair code is currently in a state of transition.  Old code 
(which we have yet to fix) uses Pairs with NULLs in their parts.  
Pairs will be changed to outlaw this usage.  "fetchLeft" and 
"fetchRight" exist to support this obsolete usage, but will be 
retired.  Don't use them. */


/* testing */


UInt32 Pair::actualHashForEqual (){
	UInt32 result;
	
	if (leftPart != NULL) {
		result = leftPart->hashForEqual();
	} else {
		result = 37;
	}
	if (rightPart != NULL) {
		return result + rightPart->hashForEqual();
	} else {
		return result + 73;
	}
}


BooleanVar Pair::isEqual (APTR(Heaper) other){
	BooleanVar res;
	
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(Pair,pair) {
			if (leftPart == NULL) {
				res = pair->fetchLeft() == NULL;
			} else {
				res = leftPart->isEqual(pair->left());
			}
			if (res) {
				if (rightPart == NULL) {
					return pair->fetchRight() == NULL;
				} else {
					return rightPart->isEqual(pair->right());
				}
			} else {
				return FALSE;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* accessing */


RPTR(Heaper) Pair::left (){
	/* Returns the left part.  Lispers may think 'car'. */
	
	if (leftPart == NULL) {
		BLAST(ObsoleteUsageMustUseFetchLeft);
	}
	return (Heaper*) leftPart;
}


RPTR(Heaper) Pair::right (){
	/* Returns the right part.  Lispers may think 'cdr'. */
	
	if (rightPart == NULL) {
		BLAST(ObsoleteUsageMustUseFetchRight);
	}
	return (Heaper*) rightPart;
}
/* instance creation */


Pair::Pair (APTR(Heaper) a, APTR(Heaper) b) {
	/* create a new pair */
	
	leftPart = a;
	rightPart = b;
}
/* printing */


void Pair::printOn (ostream& oo){
	oo << "<" << leftPart << " , " << rightPart << ">";
}
/* obsolete: access */



/* ************************************************************************ *
 * 
 *                    Class ScruTable 
 *
 * ************************************************************************ */


/* exceptions: exceptions */


/* Please read class comment for ScruSet first.
	
	Like Sets, Tables represent collections of Heapers, and provide 
protocol for storing, retrieving, and iterating over the collection.  
However, Tables in addition provide an organization for the Heapers 
collected together in the range of a Table:  A Table can also be seen 
as a collection of associations between keys and values.  A 
particular Table object has a particular domain coordinateSpace, and 
all keys in that Table are positions in that coordinate space.  For 
each position in a Table's coordinate space there is at most one 
value which it maps to.  This value may be any arbitrary Heaper.  The 
same Heaper may appear as value for several keys. 
	
	When iterating over the contents of a Table with a Stepper, the 
normal elements enumerated by the Stepper are values (i.e., range 
elements) of the Table.  However, ScruTable::stepper returns a 
TableStepper (a subclass of Stepper) which provides aditional 
protocol of accessing the key corresponding to the current value.  
(see ScruTable::stepper and TableStepper.) */


/* accessing */


RPTR(Heaper) ScruTable::get (APTR(Position) key){
	/* Return the range element at the domain position key. BLAST 
	if the position is 
		not in the table. */
	
	WPTR(Heaper) tmp;
	
	tmp = this->fetch(key);
	if (tmp == NULL) {
		BLAST(NotInTable);
		return NULL;
	}
	WPTR(Heaper) 	returnValue;
	returnValue = tmp;
	return returnValue;
}


RPTR(ImmuSet) OF1(Heaper) ScruTable::range (){
	/* A snapshot of the current range elements of the table 
	collected together into 
		an ImmuSet. */
	
	SPTR(SetAccumulator) acc;
	
	acc = SetAccumulator::make ();
	BEGIN_FOR_EACH(Heaper,obj,(this->stepper())) {
		acc->step(obj);
	} END_FOR_EACH;
	return CAST(ImmuSet,acc->value());
}


RPTR(ScruTable) ScruTable::transformedBy (APTR(Dsp) dsp){
	/* Return a ScruTable with the domain of the receiver 
	transformed by the Dsp. 
		'table->transformedBy(d)->fetch(p)' is equivalent to 
		'table->fetch(d->of(p))'. 
		
		See ScruTable::subTable for caveats regarding whether we 
	return a snapshot 
		or a view. All the same caveats apply. */
	
	RETURN_CONSTRUCT(OffsetScruTable,(this, dsp));
}
/* testing */


UInt32 ScruTable::actualHashForEqual (){
	/* See ScruTable::isEqual */
	
	return Heaper::takeOop();
}


BooleanVar ScruTable::contentsEqual (APTR(ScruTable) other){
	/* Returns whether the two ScruTables have exactly the same 
	mapping from 
		keys to values at the moment. 'a->contentsEqual(b)' is equivalent to 
		'a->asImmuTable()->isEqual(b->asImmuTable())'. See 
	ScruTable::contentsEqual */
	
	SPTR(TableStepper) myStepper;
	SPTR(Heaper) otherValue;
	
	if (other->count() != this->count()) {
		return FALSE;
	}
	if (!other->coordinateSpace()->isEqual(this->coordinateSpace())) {
		return FALSE;
	}
	myStepper = this->stepper();
	while (myStepper->hasValue()) {
		otherValue = other->fetch(myStepper->position());
		if (otherValue == NULL) {
			return FALSE;
		}
		if (!otherValue->isEqual(myStepper->fetch())) {
			return FALSE;
		}
		myStepper->step();
	}
	return TRUE;
}


UInt32 ScruTable::contentsHash (){
	/* Has the same relationship to contentsEqual that 
	hashForEqual has to isEqual. 
		I.e., if 'a->contentsEqual (b)', then 'a->contentsHash() == 
	b->contentsHash()'. 
		The same complex caveats apply as to the stability and 
	portability of the 
		hash values as apply for hashForEqual.  See ScruSet contentsHash. */
	
	SPTR(XnRegion) dom;
	
	dom = this->domain();
	if (dom->isEmpty()) {
		return this->coordinateSpace()->hashForEqual() * 17;
	} else {
		BEGIN_CHOOSE(dom) {
			BEGIN_KIND(IntegerRegion,ints) {
				return ints->start().asLong() + ints->stop().asLong() + this->count().asLong() + this->coordinateSpace()->hashForEqual();
			} END_KIND;
			BEGIN_OTHERS {
				return this->count().asLong() + this->coordinateSpace()->hashForEqual();
			} END_OTHERS;
		} END_CHOOSE;
	}
	/* fodder */
	return UInt32Zero;
}


BooleanVar ScruTable::includesKey (APTR(Position) key){
	/* includesKey is used to test for the presence of a 
	key->value pair in the
		table.  This routine returns true if there is a value 
	present at the specified
		key, and false otherwise.
		'table->includesKey(p)' iff 'table->domain()->hasMember(p)'. */
	
	return this->fetch(key) != NULL;
}
/* enumerating */


RPTR(Heaper) ScruTable::theOne (){
	/* Iff I contain exactly one range element, return it.  
	Otherwise BLAST.
		The idea for this message is taken from the THE function of ONTIC
		(reference McAllester) */
	
	SPTR(TableStepper) stepper;
	SPTR(Heaper) result;
	
	if (this->count() != 1) {
		BLAST(NotOneElement);
	}
	stepper = this->stepper();
	result = stepper->fetch();
	{stepper->destroy();  stepper = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(Heaper) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* conversion */
/* printing */


void ScruTable::printOn (ostream& stream){
	stream << this->getCategory()->name();
	this->printOnWithSimpleSyntax(stream, "(", ", ", ")");
}


void ScruTable::printOnWithSimpleSyntax (
		ostream& oo, 
		char * open, 
		char * sep, 
		char * close)
{
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
	
	this->printOnWithSyntax(oo, open, "->", sep, close);
}


void ScruTable::printOnWithSyntax (
		ostream& stream, 
		char * open, 
		char * map, 
		char * sep, 
		char * close)
{
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
	
	SPTR(TableStepper) stomp;
	
	stream << open;
	if (!this->isEmpty()) {
		stomp = this->stepper();
		while (stomp->hasValue()) {
			BEGIN_CHOOSE(stomp->position()) {
				BEGIN_KIND(IntegerPos,xui) {
					stream << xui->asIntegerVar();
				} END_KIND;
				BEGIN_OTHERS {
					stream << stomp->position();
				} END_OTHERS;
			} END_CHOOSE;
			stream << map << stomp->fetch();
			stomp->step();
			if (stomp->hasValue()) {
				stream << sep;
			}
		}
		{stomp->destroy();  stomp = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	stream << close;
}
/* runs */
/* creation */
/* protected: creation */


ScruTable::ScruTable () {
	
}
/* overloads */


BooleanVar ScruTable::includesIntKey (IntegerVar aKey){
	/* Unboxed version.  See class comment for XuInteger */
	
	return this->includesKey(IntegerPos::make (aKey));
}


RPTR(Heaper) ScruTable::intFetch (IntegerVar key){
	/* Unboxed version.  See class comment for XuInteger */
	
	WPTR(Heaper) 	returnValue;
	returnValue = this->fetch(IntegerPos::make (key));
	return returnValue;
}


RPTR(Heaper) ScruTable::intGet (IntegerVar key){
	/* Unboxed version.  See class comment for XuInteger */
	
	WPTR(Heaper) tmp;
	
	tmp = this->intFetch(key);
	if (tmp == NULL) {
		BLAST(NotInTable);
		return NULL;
	}
	WPTR(Heaper) 	returnValue;
	returnValue = tmp;
	return returnValue;
}


RPTR(XnRegion) ScruTable::runAtInt (IntegerVar key){
	/* Unboxed version.  See class comment for XuInteger */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = this->runAt(IntegerPos::make (key));
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class   ImmuTable 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(ImmuTable) ImmuTable::make (APTR(CoordinateSpace) cs){
	/* An empty ImmuTable whose domain space is 'cs'. */
	
	RETURN_CONSTRUCT(ImmuTableOnMu,(MuTable::make (cs), tcsj));
}


RPTR(ImmuTable) ImmuTable::offsetImmuTable (APTR(ImmuTable) aTable, APTR(Dsp) aDsp){
	RETURN_CONSTRUCT(OffsetImmuTable,(aTable, aDsp));
}
/* ImmuTable are to ScruTables much like ImmuSets are to ScruSets.  
See ImmuSet.
	
	The ImmuTable subclass of tables represents all tables which CANNOT 
be side-effected during operations on them.  They are intended to 
represent mathematical abstractions (such as vectors) and are 
intended to be used in a functional-programming style.  Operations 
are provided for building new ImmuTables out of old ones. */


/* accessing */


RPTR(Heaper) ImmuTable::intFetch (IntegerVar key){
	WPTR(Heaper) 	returnValue;
	returnValue = this->ScruTable::intFetch(key);
	return returnValue;
}


RPTR(XnRegion) ImmuTable::runAtInt (IntegerVar key){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->ScruTable::runAtInt(key);
	return returnValue;
}


RPTR(ScruTable) ImmuTable::transformedBy (APTR(Dsp) dsp){
	/* Return a ScruTable with the domain of the receiver 
	transformed by the Dsp. 
		'table->transformedBy(d)->fetch(p)' is equivalent to 
		'table->fetch(d->of(p))'. 
		
		See ScruTable::subTable for caveats regarding whether we 
	return a snapshot 
		or a view. All the same caveats apply.
		
		In this case of transforming an ImmuTable, it makes sense to 
	return an ImmuTable. */
	
	RETURN_CONSTRUCT(OffsetImmuTable,(this, dsp));
}
/* creation */


RPTR(ScruTable) ImmuTable::copy (){
	/* don't need to actually make a copy, as this is immutable */
	
	return this;
}
/* SEF manipulation */
/* testing */


UInt32 ImmuTable::actualHashForEqual (){
	return cat_ImmuTable->hashForEqual() + this->contentsHash();
}


BooleanVar ImmuTable::includesIntKey (IntegerVar aKey){
	return this->ScruTable::includesIntKey(aKey);
}


BooleanVar ImmuTable::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(ImmuTable,o) {
			return this->contentsEqual(o);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* enumerating */
/* conversion */


RPTR(ImmuTable) ImmuTable::asImmuTable (){
	return this;
}

	/* automatic 0-argument constructor */
ImmuTable::ImmuTable() {}



/* ************************************************************************ *
 * 
 *                    Class   MuTable 
 *
 * ************************************************************************ */



/* Initializers for MuTable */


BEGIN_INIT_TIME(MuTable,initTimeNonInherited) {
	REQUIRES (IntegerSpace);
	/* Used in pseudoconstructor */
	REQUIRES (IntegerTable);
	REQUIRES (HashTable);
} END_INIT_TIME(MuTable,initTimeNonInherited);


/* exceptions: */





/* Initializers for MuTable */



/* pseudo constructors */


RPTR(MuTable) MuTable::make (APTR(CoordinateSpace) cs){
	/* A new empty MuTable whose domain space is 'cs'. */
	
	if (cs->isEqual(IntegerSpace::make ())) {
		WPTR(MuTable) 	returnValue;
		returnValue = IntegerTable::make (10);
		return returnValue;
	} else {
		WPTR(MuTable) 	returnValue;
		returnValue = HashTable::make (cs);
		return returnValue;
	}
}


RPTR(MuTable) MuTable::make (APTR(CoordinateSpace) cs, APTR(XnRegion) reg){
	/* Semantically identical to 'muTable(cs)'.  'reg' just 
	provides a hint as to what
		part of the domain space the new table should expect to be 
	occupied. */
	
	if (cs->isEqual(IntegerSpace::make ())) {
		WPTR(MuTable) 	returnValue;
		returnValue = IntegerTable::make (CAST(IntegerRegion,reg));
		return returnValue;
	} else {
		WPTR(MuTable) 	returnValue;
		returnValue = HashTable::make (cs);
		return returnValue;
	}
}
/* MuTable represents the base class for all side-effectable tables.  
It provides the basic change protocol for tables.  See MuSet. */


/* accessing */


void MuTable::introduce (APTR(Position) key, APTR(Heaper) value){
	/* Associate key with value unless key is already associated 
	with another value.  If so, blast. */
	
	SPTR(Heaper) old;
	
	if ((old = this->store(key, value)) != NULL) {
		this->store(key, old);
		BLAST(AlreadyInTable);
	}
}


void MuTable::replace (APTR(Position) key, APTR(Heaper) value){
	/* Associate key with value only if key is already associated 
	with a value.  Otherwise blast. */
	
	if (this->store(key, value) == NULL) {
		this->wipe(key);
		/* restore table before blast */
		BLAST(NotInTable);
	}
}


void MuTable::remove (APTR(Position) anIdx){
	/* Remove a key->value association from the table.
		 Blast if the key is not present. */
	
	if (!this->wipe(anIdx)) {
		BLAST(NotInTable);
	}
}
/* bulk operations */


void MuTable::introduceAll (
		APTR(ScruTable) table, 
		APTR(Dsp) dsp/* = NULL*/, 
		APTR(XnRegion) region/* = NULL*/)
{
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
	
	if (!table->coordinateSpace()->isEqual(this->coordinateSpace())) {
		BLAST(WrongCoordSpace);
	}
	if (dsp == NULL) {
		if (this->domain()->intersects(table->domain())) {
			BLAST(AlreadyInTable);
		}
	} else {
		if (region == NULL) {
			if (this->domain()->intersects(dsp->ofAll(table->domain()))) {
				BLAST(AlreadyInTable);
			}
		} else {
			if (this->domain()->intersects(dsp->ofAll(table->domain()->intersect(region)))) {
				BLAST(AlreadyInTable);
			}
		}
	}
	this->storeAll(table, dsp, region);
}


void MuTable::replaceAll (
		APTR(ScruTable) table, 
		APTR(Dsp) dsp/* = NULL*/, 
		APTR(XnRegion) region/* = NULL*/)
{
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
	
	SPTR(TableStepper) stepper;
	
	if (!table->coordinateSpace()->isEqual(this->coordinateSpace())) {
		BLAST(WrongCoordSpace);
	}
	if (dsp == NULL) {
		if (!table->domain()->isSubsetOf(this->domain())) {
			BLAST(AlreadyInTable);
		}
		BEGIN_FOR_EACH(Heaper,e,(stepper = table->stepper())) {
			this->store(stepper->position(), e);
		} END_FOR_EACH;
	} else {
		if (region == NULL) {
			if (!dsp->ofAll(table->domain())->isSubsetOf(this->domain())) {
				BLAST(AlreadyInTable);
			}
			BEGIN_FOR_EACH(Heaper,x,(stepper = table->stepper())) {
				this->store(dsp->of(stepper->position()), x);
			} END_FOR_EACH;
		} else {
			if (!dsp->ofAll(table->domain()->intersect(region))->isSubsetOf(this->domain())) {
				BLAST(AlreadyInTable);
			}
			BEGIN_FOR_EACH(Heaper,y,(stepper = table->subTable(region)->stepper())) {
				this->store(dsp->of(stepper->position()), y);
			} END_FOR_EACH;
		}
	}
}


void MuTable::storeAll (
		APTR(ScruTable) table, 
		APTR(Dsp) dsp/* = NULL*/, 
		APTR(XnRegion) region/* = NULL*/)
{
	/* I 'store' into myself (see MuTable::store) all the 
	associations from 'table'.
		If 'region' is provided, then I only store those 
	associations from 'table' whose
		key is inside 'region'.  If 'dsp' is provided, then I 
	transform the keys (from 
		the remaining associations) by dsp before storing into myself. */
	
	SPTR(TableStepper) stepper;
	
	if (!table->coordinateSpace()->isEqual(this->coordinateSpace())) {
		BLAST(WrongCoordSpace);
	}
	if (dsp == NULL) {
		BEGIN_FOR_EACH(Heaper,e,(stepper = table->stepper())) {
			this->store(stepper->position(), e);
		} END_FOR_EACH;
	} else {
		SPTR(ScruTable) localTable;
		
		if (region != NULL) {
			localTable = table->subTable(region);
		} else {
			localTable = table;
		}
		BEGIN_FOR_EACH(Heaper,x,(stepper = localTable->stepper())) {
			this->store(dsp->of(stepper->position()), x);
		} END_FOR_EACH;
	}
}


void MuTable::wipeAll (APTR(XnRegion) region){
	/* I 'wipe' from myself all associations whose key is in 
	'region'.  See MuTable::wipe */
	
	if (!region->coordinateSpace()->isEqual(this->coordinateSpace())) {
		BLAST(WrongCoordSpace);
	}
	BEGIN_FOR_EACH(Position,p,(region->stepper())) {
		this->wipe(p);
	} END_FOR_EACH;
}
/* testing */
/* enumerating */
/* conversion */


RPTR(ImmuTable) MuTable::asImmuTable (){
	RETURN_CONSTRUCT(ImmuTableOnMu,(CAST(MuTable,this->copy()), tcsj));
}


RPTR(MuTable) MuTable::asMuTable (){
	/* Note that muTable->asMuTable() returns a copy of the 
	original.  The two
		are now free to change independently. */
	
	return CAST(MuTable,this->copy());
}
/* runs */
/* creation */
/* protected: creation */


MuTable::MuTable () {
	/* Create a new table with an unspecified number of initial 
	domain positions. */
	
	
}
/* overloads */


void MuTable::atIntIntroduce (IntegerVar key, APTR(Heaper) value){
	/* Unboxed version.  See class comment for XuInteger */
	
	this->introduce(IntegerPos::make (key), value);
}


void MuTable::atIntReplace (IntegerVar key, APTR(Heaper) value){
	/* Unboxed version.  See class comment for XuInteger */
	
	this->replace(IntegerPos::make (key), value);
}


RPTR(Heaper) MuTable::atIntStore (IntegerVar aKey, APTR(Heaper) anObject){
	/* Unboxed version.  See class comment for XuInteger */
	
	WPTR(Heaper) 	returnValue;
	returnValue = this->store(IntegerPos::make (aKey), anObject);
	return returnValue;
}


BooleanVar MuTable::includesIntKey (IntegerVar aKey){
	return this->includesKey(IntegerPos::make (aKey));
}


RPTR(Heaper) MuTable::intFetch (IntegerVar key){
	WPTR(Heaper) 	returnValue;
	returnValue = this->ScruTable::intFetch(key);
	return returnValue;
}


void MuTable::intRemove (IntegerVar anIdx){
	/* Unboxed version.  See class comment for XuInteger */
	
	this->remove(IntegerPos::make (anIdx));
}


BooleanVar MuTable::intWipe (IntegerVar anIdx){
	/* Unboxed version.  See class comment for XuInteger */
	
	return this->wipe(IntegerPos::make (anIdx));
}


RPTR(XnRegion) MuTable::runAtInt (IntegerVar index){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->runAt(IntegerPos::make (index));
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class TableAccumulator 
 *
 * ************************************************************************ */


/* pseudoConstructors */


RPTR(TableAccumulator) TableAccumulator::make (){
	/* Returns an Accumulator which will produce an MuArray of 
	the elements 
		accumulated into it in order of accumulation. See MuArray. 
	Equivalent to 
		'arrayAccumulator()'. Eventually either he or I should be 
	declared obsolete. INLINE */
	
	WPTR(TableAccumulator) 	returnValue;
	returnValue = MuArray::arrayAccumulator();
	return returnValue;
}
/* Consider this class's public status as obsolete.  Eventually This 
class will either be private of get retired. */


/* deferred operations */
/* deferred create */
/* printing */


void TableAccumulator::printOn (ostream& oo){
	oo << this->getCategory()->name() << " on " << this->value();
}

	/* automatic 0-argument constructor */
TableAccumulator::TableAccumulator() {}



/* ************************************************************************ *
 * 
 *                    Class ImmuTableOnMu 
 *
 * ************************************************************************ */


/* private: instance creation */


ImmuTableOnMu::ImmuTableOnMu (APTR(MuTable) aMuTable, TCSJ) {
	/* use the given Mu to store current value */
	/* it should be a copy for my exclusive use */
	/* this should only be called from the pseudo constructor or 
	from class methods */
	
	myMuTable = aMuTable;
}
/* accessing */


RPTR(CoordinateSpace) ImmuTableOnMu::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myMuTable->coordinateSpace();
	return returnValue;
}


IntegerVar ImmuTableOnMu::count (){
	return myMuTable->count();
}


RPTR(XnRegion) ImmuTableOnMu::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myMuTable->domain();
	return returnValue;
}


RPTR(Heaper) ImmuTableOnMu::fetch (APTR(Position) key){
	WPTR(Heaper) 	returnValue;
	returnValue = myMuTable->fetch(key);
	return returnValue;
}


RPTR(Heaper) ImmuTableOnMu::intFetch (IntegerVar key){
	WPTR(Heaper) 	returnValue;
	returnValue = myMuTable->intFetch(key);
	return returnValue;
}


RPTR(ScruTable) ImmuTableOnMu::subTable (APTR(XnRegion) region){
	RETURN_CONSTRUCT(ImmuTableOnMu,(CAST(MuTable,myMuTable->subTable(region)), tcsj));
}
/* SEF manipulation */


RPTR(ImmuTable) ImmuTableOnMu::combineWith (APTR(ImmuTable) other){
	SPTR(MuTable) newMuTable;
	SPTR(TableStepper) others;
	
	newMuTable = CAST(MuTable,myMuTable->copy());
	others = other->stepper();
	while (others->hasValue()) {
		newMuTable->store(others->position(), others->fetch());
		others->step();
	}
	{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
	RETURN_CONSTRUCT(ImmuTableOnMu,(newMuTable, tcsj));
}


RPTR(ImmuTable) ImmuTableOnMu::without (APTR(Position) index){
	SPTR(MuTable) newMuTable;
	
	newMuTable = CAST(MuTable,myMuTable->copy());
	newMuTable->wipe(index);
	RETURN_CONSTRUCT(ImmuTableOnMu,(newMuTable, tcsj));
}
/* conversion */


RPTR(MuTable) ImmuTableOnMu::asMuTable (){
	return CAST(MuTable,myMuTable->copy());
}
/* testing */


BooleanVar ImmuTableOnMu::includesIntKey (IntegerVar aKey){
	return myMuTable->includesIntKey(aKey);
}


BooleanVar ImmuTableOnMu::includesKey (APTR(Position) aKey){
	return myMuTable->includesKey(aKey);
}


BooleanVar ImmuTableOnMu::isEmpty (){
	return myMuTable->isEmpty();
}
/* enumerating */


RPTR(TableStepper) ImmuTableOnMu::stepper (APTR(OrderSpec) order/* = NULL*/){
	/* making the copy prevents anyone from getting access to the 
	array through TableStepper array */
	WPTR(TableStepper) 	returnValue;
	returnValue = myMuTable->copy()->stepper(order);
	return returnValue;
}


RPTR(Heaper) ImmuTableOnMu::theOne (){
	WPTR(Heaper) 	returnValue;
	returnValue = myMuTable->theOne();
	return returnValue;
}
/* private: accessing */


RPTR(MuTable) ImmuTableOnMu::getMuTable (){
	return (MuTable*) myMuTable;
}
/* creation */


RPTR(ScruTable) ImmuTableOnMu::emptySize (IntegerVar size){
	RETURN_CONSTRUCT(ImmuTableOnMu,(CAST(MuTable,myMuTable->emptySize(size)), tcsj));
}
/* runs */


RPTR(XnRegion) ImmuTableOnMu::runAt (APTR(Position) key){
	WPTR(XnRegion) 	returnValue;
	returnValue = myMuTable->runAt(key);
	return returnValue;
}


RPTR(XnRegion) ImmuTableOnMu::runAtInt (IntegerVar key){
	WPTR(XnRegion) 	returnValue;
	returnValue = myMuTable->runAtInt(key);
	return returnValue;
}
/* printing */


void ImmuTableOnMu::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myMuTable << ")";
}



/* ************************************************************************ *
 * 
 *                    Class IntegerScruTable 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(ScruTable) IntegerScruTable::make (APTR(IntegerTable) fromTable){
	RETURN_CONSTRUCT(IntegerScruTable,(fromTable, tcsj));
}
/* accessing */


RPTR(CoordinateSpace) IntegerScruTable::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}


IntegerVar IntegerScruTable::count (){
	return tableToScru->count();
}


RPTR(XnRegion) IntegerScruTable::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = tableToScru->domain();
	return returnValue;
}


RPTR(Heaper) IntegerScruTable::fetch (APTR(Position) key){
	WPTR(Heaper) 	returnValue;
	returnValue = tableToScru->fetch(key);
	return returnValue;
}


RPTR(Heaper) IntegerScruTable::intFetch (IntegerVar key){
	WPTR(Heaper) 	returnValue;
	returnValue = tableToScru->intFetch(key);
	return returnValue;
}


RPTR(ScruTable) IntegerScruTable::subTable (APTR(XnRegion) reg){
	WPTR(ScruTable) 	returnValue;
	returnValue = tableToScru->subTable(reg);
	return returnValue;
}


RPTR(ScruTable) IntegerScruTable::subTableBetween (IntegerVar start, IntegerVar stop){
	/* Return a table which contains the intersection of this 
	table's domain and the 
		domain specified by the enclosure. */
	
	WPTR(ScruTable) 	returnValue;
	returnValue = tableToScru->offsetSubTableBetween(start, stop, start);
	return returnValue;
}
/* creation */


RPTR(ScruTable) IntegerScruTable::copy (){
	RETURN_CONSTRUCT(IntegerScruTable,(CAST(IntegerTable,tableToScru->copy()), tcsj));
}


IntegerScruTable::IntegerScruTable (APTR(IntegerTable) fromTable, TCSJ) {
	tableToScru = fromTable;
}


RPTR(ScruTable) IntegerScruTable::emptySize (IntegerVar size){
	RETURN_CONSTRUCT(IntegerScruTable,(CAST(IntegerTable,tableToScru->emptySize(size)), tcsj));
}
/* runs */


RPTR(XnRegion) IntegerScruTable::runAt (APTR(Position) key){
	WPTR(XnRegion) 	returnValue;
	returnValue = tableToScru->runAt(key);
	return returnValue;
}


RPTR(XnRegion) IntegerScruTable::runAtInt (IntegerVar key){
	WPTR(XnRegion) 	returnValue;
	returnValue = tableToScru->runAtInt(key);
	return returnValue;
}
/* testing */


UInt32 IntegerScruTable::actualHashForEqual (){
	return cat_IntegerScruTable->hashForEqual() + tableToScru->hashForEqual();
}


BooleanVar IntegerScruTable::includesIntKey (IntegerVar aKey){
	return tableToScru->includesIntKey(aKey);
}


BooleanVar IntegerScruTable::includesKey (APTR(Position) aKey){
	return tableToScru->includesKey(aKey);
}


BooleanVar IntegerScruTable::isEmpty (){
	return tableToScru->isEmpty();
}


BooleanVar IntegerScruTable::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(IntegerScruTable,ist) {
			return ist->innerTable()->isEqual(tableToScru);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* enumerating */


RPTR(TableStepper) IntegerScruTable::stepper (APTR(OrderSpec) order/* = NULL*/){
	WPTR(TableStepper) 	returnValue;
	returnValue = tableToScru->stepper(order);
	return returnValue;
}
/* conversion */


RPTR(ImmuTable) IntegerScruTable::asImmuTable (){
	WPTR(ImmuTable) 	returnValue;
	returnValue = tableToScru->asImmuTable();
	return returnValue;
}


RPTR(MuTable) IntegerScruTable::asMuTable (){
	WPTR(MuTable) 	returnValue;
	returnValue = tableToScru->copy()->asMuTable();
	return returnValue;
}
/* private: private */


RPTR(ScruTable) IntegerScruTable::innerTable (){
	return (IntegerTable*) tableToScru;
}



/* ************************************************************************ *
 * 
 *                    Class OffsetImmuTable 
 *
 * ************************************************************************ */


/* accessing */


RPTR(CoordinateSpace) OffsetImmuTable::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myTable->coordinateSpace();
	return returnValue;
}


IntegerVar OffsetImmuTable::count (){
	return myTable->count();
}


RPTR(XnRegion) OffsetImmuTable::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myDsp->ofAll(myTable->domain());
	return returnValue;
}


RPTR(Heaper) OffsetImmuTable::fetch (APTR(Position) anIndex){
	WPTR(Heaper) 	returnValue;
	returnValue = myTable->intFetch(myDsp->inverseOfInt(CAST(IntegerPos,anIndex)->asIntegerVar()));
	return returnValue;
}


RPTR(Heaper) OffsetImmuTable::intFetch (IntegerVar idx){
	WPTR(Heaper) 	returnValue;
	returnValue = myTable->intFetch(myDsp->inverseOfInt(idx));
	return returnValue;
}


RPTR(ScruTable) OffsetImmuTable::subTable (APTR(XnRegion) encl){
	RETURN_CONSTRUCT(OffsetScruTable,(myTable->subTable(myDsp->inverseOfAll(encl)), myDsp));
}


RPTR(ScruTable) OffsetImmuTable::transformedBy (APTR(Dsp) dsp){
	if (myDsp->inverse()->isEqual(dsp)) {
		return (ImmuTable*) myTable;
	} else {
		RETURN_CONSTRUCT(OffsetScruTable,(myTable, dsp->compose(myDsp)));
	}
}
/* runs */


RPTR(XnRegion) OffsetImmuTable::runAt (APTR(Position) key){
	if (this->includesKey(myDsp->inverseOf(key))) {
		WPTR(XnRegion) 	returnValue;
		returnValue = key->asRegion();
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = myTable->coordinateSpace()->emptyRegion();
		return returnValue;
	}
}


RPTR(XnRegion) OffsetImmuTable::runAtInt (IntegerVar anIdx){
	WPTR(XnRegion) 	returnValue;
	returnValue = myDsp->ofAll(myTable->runAtInt(myDsp->inverseOfInt(anIdx)));
	return returnValue;
}
/* testing */


UInt32 OffsetImmuTable::actualHashForEqual (){
	return cat_OffsetImmuTable->hashForEqual() + myTable->hashForEqual() + myDsp->hashForEqual();
}


BooleanVar OffsetImmuTable::includesIntKey (IntegerVar aKey){
	return myTable->includesIntKey(myDsp->inverseOfInt(aKey));
}


BooleanVar OffsetImmuTable::includesKey (APTR(Position) aKey){
	return myTable->includesKey(myDsp->inverseOf(aKey));
}


BooleanVar OffsetImmuTable::isEmpty (){
	return myTable->isEmpty();
}
/* printing */


void OffsetImmuTable::printOn (ostream& aStream){
	aStream << this->getCategory()->name() << "(" << myDsp << ", " << myTable << ")";
}
/* creation */


OffsetImmuTable::OffsetImmuTable (APTR(ImmuTable) table, APTR(Dsp) dsp) {
	myTable = table;
	myDsp = dsp;
}


RPTR(ScruTable) OffsetImmuTable::emptySize (IntegerVar size){
	WPTR(ScruTable) 	returnValue;
	returnValue = myTable->emptySize(size);
	return returnValue;
}
/* conversion */


RPTR(MuTable) OffsetImmuTable::asMuTable (){
	SPTR(MuTable) newTab;
	SPTR(TableStepper) s;
	
	newTab = myTable->emptySize(myTable->count())->asMuTable();
	BEGIN_FOR_EACH(Heaper,e,(s = myTable->stepper())) {
		newTab->store(myDsp->of(s->position()), e);
	} END_FOR_EACH;
	WPTR(MuTable) 	returnValue;
	returnValue = newTab;
	return returnValue;
}
/* enumerating */


RPTR(TableStepper) OffsetImmuTable::stepper (APTR(OrderSpec) order/* = NULL*/){
	RETURN_CONSTRUCT(OffsetScruTableStepper,(myTable->stepper(order), myDsp));
}
/* private: private */


RPTR(Dsp) OffsetImmuTable::innerDsp (){
	return (Dsp*) myDsp;
}


RPTR(ScruTable) OffsetImmuTable::innerTable (){
	return (ImmuTable*) myTable;
}
/* SEF manipulation */


RPTR(ImmuTable) OffsetImmuTable::combineWith (APTR(ImmuTable) other){
	SPTR(MuTable) newTable;
	SPTR(TableStepper) others;
	
	newTable = myTable->copy()->asMuTable();
	others = other->stepper();
	while (others->hasValue()) {
		newTable->store(myDsp->inverseOf(others->position()), others->fetch());
		others->step();
	}
	{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
	RETURN_CONSTRUCT(OffsetImmuTable,(newTable->asImmuTable(), myDsp));
}


RPTR(ImmuTable) OffsetImmuTable::without (APTR(Position) index){
	RETURN_CONSTRUCT(OffsetImmuTable,(myTable->without(myDsp->inverseOf(index)), myDsp));
}



/* ************************************************************************ *
 * 
 *                    Class OffsetScruTable 
 *
 * ************************************************************************ */


/* accessing */


RPTR(CoordinateSpace) OffsetScruTable::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myTable->coordinateSpace();
	return returnValue;
}


IntegerVar OffsetScruTable::count (){
	return myTable->count();
}


RPTR(XnRegion) OffsetScruTable::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myDsp->ofAll(myTable->domain());
	return returnValue;
}


RPTR(Heaper) OffsetScruTable::fetch (APTR(Position) anIndex){
	WPTR(Heaper) 	returnValue;
	returnValue = myTable->intFetch(myDsp->inverseOfInt(CAST(IntegerPos,anIndex)->asIntegerVar()));
	return returnValue;
}


RPTR(Heaper) OffsetScruTable::intFetch (IntegerVar idx){
	WPTR(Heaper) 	returnValue;
	returnValue = myTable->intFetch(myDsp->inverseOfInt(idx));
	return returnValue;
}


RPTR(ScruTable) OffsetScruTable::subTable (APTR(XnRegion) encl){
	RETURN_CONSTRUCT(OffsetScruTable,(myTable->subTable(myDsp->inverseOfAll(encl)), myDsp));
}


RPTR(ScruTable) OffsetScruTable::transformedBy (APTR(Dsp) dsp){
	if (myDsp->inverse()->isEqual(dsp)) {
		return (ScruTable*) myTable;
	} else {
		RETURN_CONSTRUCT(OffsetScruTable,(myTable, dsp->compose(myDsp)));
	}
}
/* runs */


RPTR(XnRegion) OffsetScruTable::runAt (APTR(Position) key){
	if (this->includesKey(myDsp->inverseOf(key))) {
		WPTR(XnRegion) 	returnValue;
		returnValue = key->asRegion();
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = myTable->coordinateSpace()->emptyRegion();
		return returnValue;
	}
}


RPTR(XnRegion) OffsetScruTable::runAtInt (IntegerVar anIdx){
	WPTR(XnRegion) 	returnValue;
	returnValue = myDsp->ofAll(myTable->runAtInt(myDsp->inverseOfInt(anIdx)));
	return returnValue;
}
/* testing */


UInt32 OffsetScruTable::actualHashForEqual (){
	return cat_OffsetScruTable->hashForEqual() + myTable->hashForEqual() + myDsp->hashForEqual();
}


BooleanVar OffsetScruTable::includesIntKey (IntegerVar aKey){
	return myTable->includesIntKey(myDsp->inverseOfInt(aKey));
}


BooleanVar OffsetScruTable::includesKey (APTR(Position) aKey){
	return myTable->includesKey(myDsp->inverseOf(aKey));
}


BooleanVar OffsetScruTable::isEmpty (){
	return myTable->isEmpty();
}


BooleanVar OffsetScruTable::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(OffsetScruTable,ost) {
			{	BooleanVar crutch_Flag;
				/* ost->innerTable()->isEqual(myTable) && ost->innerTable()->isEqual(myTable) */
				
				crutch_Flag = ost->innerTable()->isEqual(myTable);
				if(crutch_Flag) {
					crutch_Flag = ost->innerTable()->isEqual(myTable);
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* printing */


void OffsetScruTable::printOn (ostream& aStream){
	aStream << this->getCategory()->name() << "(" << myDsp << ", " << myTable << ")";
}
/* creation */


RPTR(ScruTable) OffsetScruTable::copy (){
	RETURN_CONSTRUCT(OffsetScruTable,(myTable->copy(), myDsp));
}


OffsetScruTable::OffsetScruTable (APTR(ScruTable) table, APTR(Dsp) dsp) {
	myTable = table;
	myDsp = dsp;
}


RPTR(ScruTable) OffsetScruTable::emptySize (IntegerVar size){
	WPTR(ScruTable) 	returnValue;
	returnValue = myTable->emptySize(size);
	return returnValue;
}
/* conversion */


RPTR(ImmuTable) OffsetScruTable::asImmuTable (){
	RETURN_CONSTRUCT(OffsetImmuTable,(myTable->asImmuTable(), myDsp));
}


RPTR(MuTable) OffsetScruTable::asMuTable (){
	SPTR(MuTable) newTab;
	SPTR(TableStepper) s;
	
	newTab = myTable->emptySize(myTable->count())->asMuTable();
	BEGIN_FOR_EACH(Heaper,e,(s = myTable->stepper())) {
		newTab->store(myDsp->of(s->position()), e);
	} END_FOR_EACH;
	WPTR(MuTable) 	returnValue;
	returnValue = newTab;
	return returnValue;
}
/* enumerating */


RPTR(TableStepper) OffsetScruTable::stepper (APTR(OrderSpec) order/* = NULL*/){
	RETURN_CONSTRUCT(OffsetScruTableStepper,(myTable->stepper(order), myDsp));
}
/* private: */


RPTR(Dsp) OffsetScruTable::innerDsp (){
	return (Dsp*) myDsp;
}


RPTR(ScruTable) OffsetScruTable::innerTable (){
	return (ScruTable*) myTable;
}



/* ************************************************************************ *
 * 
 *                    Class OffsetScruTableStepper 
 *
 * ************************************************************************ */


/* operations */


WPTR(Heaper) OffsetScruTableStepper::fetch (){
	WPTR(Heaper) 	returnValue;
	returnValue = myTableStepper->fetch();
	return returnValue;
}


WPTR(Heaper) OffsetScruTableStepper::get (){
	WPTR(Heaper) 	returnValue;
	returnValue = myTableStepper->get();
	return returnValue;
}


BooleanVar OffsetScruTableStepper::hasValue (){
	return myTableStepper->hasValue();
}


void OffsetScruTableStepper::step (){
	myTableStepper->step();
}
/* special */


IntegerVar OffsetScruTableStepper::index (){
	return myDsp->ofInt(myTableStepper->index());
}


RPTR(Position) OffsetScruTableStepper::position (){
	WPTR(Position) 	returnValue;
	returnValue = myDsp->of(myTableStepper->position());
	return returnValue;
}
/* create */


RPTR(Stepper) OffsetScruTableStepper::copy (){
	RETURN_CONSTRUCT(OffsetScruTableStepper,(CAST(TableStepper,myTableStepper->copy()), myDsp));
}


OffsetScruTableStepper::OffsetScruTableStepper (APTR(TableStepper) onStepper, APTR(Dsp) aDsp) {
	myTableStepper = onStepper;
	myDsp = aDsp;
}

#ifndef TABLESX_SXX
#include "tablesx.sxx"
#endif /* TABLESX_SXX */


#ifndef TABLESP_SXX
#include "tablesp.sxx"
#endif /* TABLESP_SXX */



#endif /* TABLESX_CXX */

