'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:58 pm'!

Connection subclass: #DirectConnection
	instanceVariableNames: '
		myCategory {Category}
		myHeaper {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cobbler'!
DirectConnection comment:
'We just made the object, so the connection is just a reference to the object.'!

(DirectConnection getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DirectConnection methodsFor: 'accessing'!

{Category} bootCategory
	^myCategory!

{Heaper} bootHeaper
	^myHeaper! !

!DirectConnection methodsFor: 'creation'!

create: cat {Category} with: heaper {Heaper}
	super create.
	myCategory _ cat.
	myHeaper _ heaper!

{void} destruct
	"myHeaper destroy. There are bootHeapers that you REALLY don't want to destroy, such as the GrandMap"
	super destruct! !