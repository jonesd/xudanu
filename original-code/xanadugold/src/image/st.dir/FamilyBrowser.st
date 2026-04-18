'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:58 pm'!

Browser subclass: #FamilyBrowser
	instanceVariableNames: 'myClass {Class}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser'!



!FamilyBrowser methodsFor: 'category list'!

{void} category: selection 

	^VOID!

{void} categoryRep: selection 

	^VOID!

classList

	^Browser computeClassOrdering:
		((myClass withAllSuperclasses reverse , (myClass allSubclasses select: [:cls | cls isGenerated not]))
			collect: [ :each | each name])! !

!FamilyBrowser methodsFor: 'creation'!

create: aBrowser {Browser}

	super create: aBrowser.
	myClass _ aBrowser nonMetaClass.
	myClass == nil
		ifTrue: [self class blast.MustHaveSelectedClass raise]! !

!FamilyBrowser methodsFor: 'accessing'!

{Class} familyCenter

	^myClass! !