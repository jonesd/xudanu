'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:54:43 pm'!

IndentedTreeSelection subclass: #IndentedCxxTreeRep
	instanceVariableNames: 'changedSet {IdentitySet}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Browser'!



!IndentedCxxTreeRep methodsFor: 'private: private'!

changedOpenedSet

	"self checkChanged."
	currentSelection ~= nil
		ifTrue: [self checkChanged: currentSelection]
		ifFalse: [self checkChanged].
	super changedOpenedSet.!

checkChanged
	changedSet _ IdentitySet new.
	self checkChanged: tree!

{BooleanVar} checkChanged: child {AssociationTreeWithParent} 
	| dFile |
	child isLeaf not
		ifTrue: [(openedSet includes: child)
				ifTrue: [| anyChanged {BooleanVar} |
					anyChanged _ false.
					child children do: 
						[:grandChild | (self checkChanged: grandChild)
							ifTrue: [changedSet add: child.
								anyChanged _ true]].
					^ anyChanged]
				ifFalse: [(self isChanged: child)
						ifTrue: [changedSet add: child. ^ true]
						ifFalse: [^ false]]]
		ifFalse: [child value == #file
				ifTrue: [
					(dFile _ CxxSystemOrganization fetchModuleNamed: child key) ~~ nil
						ifTrue: [dFile isChanged ifTrue: [changedSet add: child. ^ true]]
						ifFalse: [self halt. changedSet add: child. ^ true]]].
	^ false!

isChanged: child {AssociationTreeWithParent} 
	| dFile |
	child isLeaf ifFalse: [child children do: [:grandChild | (self isChanged: grandChild)
				ifTrue: [^true]]].
	child value == #file
		ifTrue: [^(dFile _ CxxSystemOrganization fetchModuleNamed: child key) ~~ nil
				ifTrue: [dFile isChanged]
				ifFalse: [true]]
		ifFalse: [^false]!

nameFor: child indentLevel: num 
	"Answer a string for child with the proper level of indenting."

	| aStream |
	aStream := TextStream on: (String new: 25).
	num timesRepeat: 
			[aStream nextPut: Character space; space; space; space].
	(nonTerminalBolding == true and: 
		[(openedSet includes: child) not and: [(self isLeaf: child) not]])
		ifTrue: [aStream emphasis: ((changedSet includes: child)
					ifTrue: [14] ifFalse: [13])]
		ifFalse: [aStream emphasis: ((changedSet includes: child)
					ifTrue: [2] ifFalse: [1])].
	aStream nextPutAll: (self nameFor: child) asString.
	^aStream contents! !

!IndentedCxxTreeRep methodsFor: 'creation'!

create: aTreeAccessor
	self treeAccessor: aTreeAccessor.
	changedSet _ IdentitySet new.! !

!IndentedCxxTreeRep methodsFor: 'setting'!

tree: aTree {CxxTreeAssociation}

	super tree: aTree.
	self checkChanged! !

!IndentedCxxTreeRep methodsFor: 'changes'!

updateChange
	self checkChanged! !

!IndentedCxxTreeRep methodsFor: 'accessing'!

openAndSelect: aChild 
	"Signal that a new list is necessary. Set the receiver's current 
	selection to be aChild."

	super openAndSelect: aChild.
	self checkChanged! !