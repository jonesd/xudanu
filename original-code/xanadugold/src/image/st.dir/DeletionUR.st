'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:14 pm'!

UpdateRecord subclass: #DeletionUR
	instanceVariableNames: 'regInternal {XnRegion}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Update Mechanism'!
DeletionUR comment:
'For reporting the deletion or deflation of a region from out of the domain of a table-like XuModel.  See IntegerTableWaldo::deflate.'!

(DeletionUR getOrMakeCxxClassDescription)
	friends:
'/* friends for class DeletionUR */
friend SPTR(DeletionUR) deletionUR (XnRegion * withReg);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DeletionUR methodsFor: 'private: creation'!

create: regDeleted {XnRegion}

	super create.
	regInternal _ regDeleted! !

!DeletionUR methodsFor: 'accessing'!

{XnRegion INLINE} region
	"The region which was deleted or deflated out of the table-like XuModel."

	^ regInternal! !

!DeletionUR methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << regInternal << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DeletionUR class
	instanceVariableNames: ''!

(DeletionUR getOrMakeCxxClassDescription)
	friends:
'/* friends for class DeletionUR */
friend SPTR(DeletionUR) deletionUR (XnRegion * withReg);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!DeletionUR class methodsFor: 'pseudo constructors'!

make: withReg {XnRegion} 
	"An UpdateRecord for notifying dependents that 'withReg' was deleted or 
	deflated out of a table-like XuModel."

	^DeletionUR create: withReg! !