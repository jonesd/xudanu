'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:20 pm'!

Heaper subclass: #Category
	instanceVariableNames: 'myClass {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Basic'!



!Category methodsFor: 'accessing'!

brotherClass
	^myClass!

create: cat 
	super create.
	myClass _ cat!

getCategory
	^Category create: Category!

inheritsFrom: cat
	cat class == Category ifTrue: [^myClass == cat brotherClass or: [myClass inheritsFrom: cat brotherClass]]
		ifFalse: [^myClass == cat or: [myClass inheritsFrom: cat]]!

name
	^myClass name!

preorderNumber
	^myClass preorderNumber! !

!Category methodsFor: 'stubble'!

sendSelfTo: xmtr
	xmtr sendString: self name! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Category class
	instanceVariableNames: ''!



!Category class methodsFor: 'stubble'!

create.Rcvr: rcvr
	| catName |
	catName _ rcvr receiveString.
	^Heaper findCategory: catName! !

!Category class methodsFor: 'accessing'!

{Class} find: catName {UInt8Array}
	"translate a category name into a class"
	"Warning:  smalltalk wizardy."
	| oldCat result |
	catName isSymbol 
		ifTrue: [^Smalltalk at: catName
			ifAbsent: [Heaper BLAST: #'CATEGORY_NOT_FOUND']].
	oldCat _ catName class.
	catName changeClassToThatOf: ''.
	result _ Smalltalk at: catName asSymbol 
		ifAbsent: [Heaper BLAST: #'CATEGORY_NOT_FOUND'].
	catName changeClassToThatOf: oldCat basicNew.
	^result! !