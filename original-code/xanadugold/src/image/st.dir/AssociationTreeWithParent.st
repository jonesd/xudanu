'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:59 pm'!

AssociationTree subclass: #AssociationTreeWithParent
	instanceVariableNames: 'parent '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Tree'!
AssociationTreeWithParent comment:
'An instance of this class represents an AssociationTree with a parent. 
Instance Variables:
		parent		<Object> 	the receiver''s parent'!


!AssociationTreeWithParent methodsFor: 'accessing'!

parent
	"Answer the parent of the receiver."

	^parent!

parent: anObject
	"Set the parent of the receiver to be anObject."

	parent := anObject! !

!AssociationTreeWithParent methodsFor: 'copying'!

deepCopy
	"Answer a copy of the receiver with its own deepCopy of each instance variable."

	| tmpParent cpy |
	tmpParent := parent.
	parent := nil.
	cpy := super deepCopy.
	parent := tmpParent.
	^cpy! !

!AssociationTreeWithParent methodsFor: 'adding'!

addChild: someChild
	"Add aChild as a child of the receiver, and set someChild's 
	parent to be the receiver."

	super addChild: someChild. 
	someChild parent: self!

addChild: aChild after: someChild 
	"Add aChild to the receiver's list of children after someChild. Also, 
	make aChild's parent be the receiver."

	super addChild: aChild after: someChild.
	aChild parent: self.!

addChild: aChild before: someChild 
	"Add aChild to the receiver's list of children before someChild. Also, 
	make aChild's parent be the receiver."

	super addChild: aChild before: someChild.
	aChild parent: self! !

!AssociationTreeWithParent methodsFor: 'removing'!

removeChild: aChild 
	"Remove the aChild from the receiver's list of children. Also, set 
	aChild's parent to be nil."

	super removeChild: aChild.
	aChild parent: nil.! !