'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:59 pm'!

Object subclass: #TreeAccessor
	instanceVariableNames: 'isLeafTranslation childrenTranslation nameTranslation '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Tree'!
TreeAccessor comment:
'An instance of TreeAccessor represents a protocol translator for using the tree protocol to access objects that do not understand tree protocol directly.  The replacement protocol is saved as properties of the instance.  TreeAccessors are used to translate messages children and name, and sometimes isLeaf.
Instance Variables:
	isLeafTranslation		<nil | Symbol> 	nil means that there is no direct translation for the message isLeaf;
											otherwise, the Symbol is the appropriate translation.
	childrenTranslation		<Symbol> 		the translation for children
	nameTranslation		<Symbol> 		the translation for name

'!


!TreeAccessor methodsFor: 'accessing'!

childrenFor: aChild
	"Answer the children for aChild."

	^aChild perform: childrenTranslation!

isLeaf: aChild
	"Answer true or false as to whether aChild has children."

	isLeafTranslation == nil
		ifTrue: [^(self childrenFor: aChild) size = 0].
	^aChild perform: isLeafTranslation!

nameFor: aChild
	"Answer a printable name for aChild."

	^aChild perform: nameTranslation! !

!TreeAccessor methodsFor: 'private: private'!

setIsLeaf: leafSelector children: childSelector name: nameSelector
	"Set the adaptor messages for the receiver."

	isLeafTranslation := leafSelector.
	childrenTranslation := childSelector.
	nameTranslation := nameSelector! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TreeAccessor class
	instanceVariableNames: ''!


!TreeAccessor class methodsFor: 'instance creation'!

children: childSelector name: nameSelector
	"Create a new instance of the receiver with appropriate adaptor messages."

	^self new setIsLeaf: nil children: childSelector name: nameSelector!

isLeaf: leafSelector children: childSelector name: nameSelector
	"Create a new instance of the receiver with appropriate adaptor messages."

	^self new setIsLeaf: leafSelector children: childSelector name: nameSelector! !