'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:15 pm'!

UpdateRecord subclass: #RearrangeUpdate
	instanceVariableNames: '
		myCut1 {IntegerVar}
		myCut2 {IntegerVar}
		myCut3 {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Update Mechanism'!
RearrangeUpdate comment:
'Despite the fact that this class is defined in module "twaldo", none of the TableWaldos have a rearrange operation, and none send this UpdateRecord.  However, it is used well by other table-like models.
	
	It notifies dependents that a "3-cut rearrange" (See Computer Lib) has been performed on the model.  A 3-cut rearrange is an operation whereby all the elements at indicies between cut1 inclusive and cut2 exclusive is swapped with the elements between cut2 inclusive and cut3 exclusive.  It is an error unless cut1 <= cut2 <= cut3.  One can think of this as a "text move" (even though it isn''t text specific, we will use the text example): the text between cut1 and cut2 is deflated out and then re-inserted at cut3 (rather, where cut3 ended up after the deflation).  An alternative but equivalent interpretation is that the text between cut2 and cut3 was deflated and then reinserted at cut1.'!

(RearrangeUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RearrangeUpdate methodsFor: 'create'!

create: cut1 {IntegerVar} with: cut2 {IntegerVar} with: cut3 {IntegerVar}
	super create.
	myCut1 _ cut1.
	myCut2 _ cut2.
	myCut3 _ cut3! !

!RearrangeUpdate methodsFor: 'accessing'!

{IntegerVar INLINE} cut1
	"The position of the first cut. Actually, the first cut is immediately to my 
	left--between 'this->cut1()' and 'this->cut1() -1'."

	^myCut1!

{IntegerVar INLINE} cut2
	"The position of the second cut. Actually, the second cut is immediately to my 
	left--between 'this->cut2()' and 'this->cut2() -1'."

	^myCut2!

{IntegerVar INLINE} cut3
	"The position of the third cut. Actually, the third cut is immediately to my 
	left--between 'this->cut3()' and 'this->cut3() -1'."

	^myCut3! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RearrangeUpdate class
	instanceVariableNames: ''!

(RearrangeUpdate getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RearrangeUpdate class methodsFor: 'make'!

make: cut1 {IntegerVar} with: cut2 {IntegerVar} with: cut3 {IntegerVar}
	"An UpdateRecord for notification of a 3-cut rearrange."
	
	^self create: cut1 with: cut2 with: cut3! !