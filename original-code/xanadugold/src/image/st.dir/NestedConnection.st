'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:00 pm'!

Connection subclass: #NestedConnection
	instanceVariableNames: '
		myCategory {Category}
		myHeaper {Heaper}
		mySub {Connection}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
NestedConnection comment:
'We just made an object that wraps another object, so the connection needs to wrap the connection by which that other object was obtained.'!

(NestedConnection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!NestedConnection methodsFor: 'accessing'!

{Category} bootCategory
	^myCategory!

{Heaper} bootHeaper
	^myHeaper! !

!NestedConnection methodsFor: 'creation'!

create: cat {Category} with: heaper {Heaper} with: sub {Connection}
	super create.
	myCategory _ cat.
	myHeaper _ heaper.
	mySub _ sub!

{void} destruct
	mySub destroy.
	myHeaper destroy.
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NestedConnection class
	instanceVariableNames: ''!

(NestedConnection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!NestedConnection class methodsFor: 'creation'!

{Connection} make: cat {Category} with: heaper {Heaper} with: sub {Connection}
	^self create: cat with: heaper with: sub! !