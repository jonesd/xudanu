'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:37 pm'!

Heaper subclass: #FlockLocation
	instanceVariableNames: '
		mySnarfID {SnarfID}
		myIndex {Int4}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Snarf'!
FlockLocation comment:
'Represent the location of a flock on disk.  This ID of the snarf in which the flock is contained, and the index of the flock within that snarf.  This information side-effect free, even in subclasses.'!

(FlockLocation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!FlockLocation methodsFor: 'protected: accessing'!

{void} index: anIndex {Int32}
	"This is used to set the index when a flock is bumped from its snarf and forwarded by
	way of the new flocks table"
	 myIndex := anIndex! !

!FlockLocation methodsFor: 'accessing'!

{Int32 INLINE} index
	 ^myIndex!

{SnarfID INLINE} snarfID
	 ^mySnarfID! !

!FlockLocation methodsFor: 'creation'!

create: snarfID {SnarfID} with: index {Int32}
	super create.
	mySnarfID _ snarfID.
	myIndex _ index! !

!FlockLocation methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << mySnarfID <<', ' << myIndex << ')'! !

!FlockLocation methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FlockLocation class
	instanceVariableNames: ''!

(FlockLocation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #EQ; yourself)!

!FlockLocation class methodsFor: 'creation'!

make: snarfID {SnarfID} with: index {Int32}
	^self create: snarfID with: index! !