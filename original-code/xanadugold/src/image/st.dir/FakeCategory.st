'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:22 pm'!

Heaper subclass: #FakeCategory
	instanceVariableNames: '
		myName {String}
		myOriginalClass {Class}
		mySuperCategory {Category}
		myPackageClasses {OrderedCollection of: Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Packages'!



!FakeCategory methodsFor: 'create'!

create: name {String} with: original {Class} with: parent {Category}
	super create.
	myName := name.
	myOriginalClass := original.
	mySuperCategory := parent.
	myPackageClasses := OrderedCollection new.! !

!FakeCategory methodsFor: 'packages'!

{void} addPackageCategory: pCat {Category}
	myPackageClasses add: pCat!

{Heaper} makeHooked
	"make a hooked 'instance' of this class"
	^(myOriginalClass new create) packagingCategory: self; yourself!

{OrderedCollection of: PackageCategory} packageClasses
	^myPackageClasses!

{Category} registerPackageCategory: packageCat {PackageCategory}
	self error: 'Attempted to add a package to a hook-generated category'! !

!FakeCategory methodsFor: 'accessing'!

{Symbol} fetchAttribute: attr
	"get information attached to the given attribute, or NULL if none"
	^myOriginalClass fetchAttribute: attr!

getSuperCategory
	^mySuperCategory!

{BooleanVar} hasAttribute: attr
	"check if the attributes information includes this"
	^myOriginalClass hasAttribute: attr!

isEqualOrSubclassOf: cat {Category}
	^myOriginalClass isEqualOrSubclassOf: cat originalClass!

{String} name
	^myName!

originalClass
	^myOriginalClass!

withAllSuperclasses
	^self getSuperCategory withAllSuperclasses
		addFirst: self;
		yourself! !

!FakeCategory methodsFor: 'printing'!

printOn: oo
	oo << self getCategory name << $( << self name << $)! !