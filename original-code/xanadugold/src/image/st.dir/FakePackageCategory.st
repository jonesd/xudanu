'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:23 pm'!

FakeCategory subclass: #FakePackageCategory
	instanceVariableNames: '
		myContentsCategory {Category}
		myOriginalContentsCategory {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Packages'!



!FakePackageCategory methodsFor: 'create'!

create: name {String} with: original {Class} with: parent {Category}
	with: originalContents {Category}
	
	super create: name with: original with: parent.
	myContentsCategory _ NULL.
	myOriginalContentsCategory _ originalContents.! !

!FakePackageCategory methodsFor: 'packages'!

contentsCategory
	^myContentsCategory!

isConcretePackage
	^myOriginalClass isConcretePackage!

{Package} makeHooked
	"make a hooked 'instance' of this class"
	^self contentsCategory makeHooked getOrMakePackage: self!

{Package} makePackage: contents {Heaper}
	"make a new package with the specified contents"
	^myOriginalClass new create: contents;
		packagingCategory: self;
		constructPackage;
		yourself!

originalContentsCategory
	^myOriginalContentsCategory!

{void} registerWithContents
	myContentsCategory == NULL ifTrue:
		[myContentsCategory := myOriginalContentsCategory registerPackageCategory: self]! !

!FakePackageCategory methodsFor: 'inspecting'!

showOn: oo
	oo << self name << ' [' << self contentsCategory inspectString << ']'! !