'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:42 pm'!

Object subclass: #Link
	instanceVariableNames: 'nextLink '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Support'!
Link comment:
'Class Link represents a simple record of a pointer to another Link.

Instance Variables:
	nextLink	<Link> a pointer referencing the next Link in the chain'!


!Link methodsFor: 'accessing'!

{Link}nextLink
	"Answer the Link to which the receiver points."

	^nextLink!

{Link}nextLink: aLink{Link} 
	"Store the argument as the Link to which the receiver refers."

	^nextLink _ aLink! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Link class
	instanceVariableNames: ''!


!Link class methodsFor: 'smalltalk: smalltalk instance creation'!

{Link}nextLink: aLink{Link} 
	"Answer a new instance of the receiver referring to the argument, aLink."

	^self create
		nextLink: aLink;
		yourself! !