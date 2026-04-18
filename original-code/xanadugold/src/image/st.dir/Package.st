'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:23 pm'!

Heaper subclass: #Package
	instanceVariableNames: 'myContents {Heaper smalltalk}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Packages'!



!Package methodsFor: 'create'!

{void} constructPackage
	"a construct message that gets sent when each package object is created
	should always call super constructPackage at the beginning"!

create: contents {Heaper}
	super create.
	myContents _ contents.
	myPackagingCategory _ self class! !

!Package methodsFor: 'accessing'!

{Heaper} contents
	^myContents!

{Heaper} getContents
	^myContents! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Package class
	instanceVariableNames: 'myContentsCategory {Category star smalltalk} myOriginalContentsCategory {Category star smalltalk} '!



!Package class methodsFor: 'smalltalk: init'!

linkTimeInherited

	"this is a hack so that this happens before any actual code gets run"
	[myOriginalContentsCategory _ NULL. "access method will pull from attributes"
	myContentsCategory _ NULL] smalltalkOnly!

suppressLinkTimeInherited! !

!Package class methodsFor: 'packages'!

{Category} contentsCategory
	self registerWithContents.
	^myContentsCategory!

{BooleanVar} isConcretePackage
	"whether this package should be instantiated"
	^self hasAttribute: #CONCRETE!

{Package} MAKE.U.HOOKED: packageName {Symbol}
	^(Smalltalk at: packageName) makeHooked!

{Package} makeHooked
	"make a hooked instance of this class with the given packaging category"
	^self contentsCategory makeHooked getOrMakePackage: self!

{Package} makePackage: contents {Heaper}
	"make a new package with the specified contents"
	| result {Heaper} |
	result _ self create: contents.
	result constructPackage.
	^result!

originalClass
	^self!

{Category} originalContentsCategory
	(myOriginalContentsCategory == NULL or: [myOriginalContentsCategory == nil]) ifTrue:
		[ | original {Symbol} |
		original := self fetchAttribute: #PACKAGE.
		original == NULL ifTrue:
			[original := self fetchAttribute: #PACKAGE.HOOK].
		myOriginalContentsCategory := Smalltalk at: original].
	^myOriginalContentsCategory!

{Category} registerPackageCategory: packageCat {PackageCategory}
	"a package category can be added; remember it and return what its contents class should be"
	(self hasAttribute: #PACKAGE.HOOK)
		ifTrue: [^(FakePackageCategory create: packageCat name , '_' , self name
				with: self
				with: (packageCat getSuperCategory == Package
					ifTrue: [self getSuperCategory]
					ifFalse: [packageCat getSuperCategory contentsCategory])
				with: self originalContentsCategory)
			addPackageCategory: packageCat;
			registerWithContents;
			yourself]
		ifFalse: [self addPackageCategory: packageCat.
			^self]!

{void} registerWithContents
	"tell my contents category that I am a package on it"
	myContentsCategory == NULL ifTrue:
		[myContentsCategory _ self originalContentsCategory registerPackageCategory: self]!

showOn: oo
	oo << self name << ' [' << self contentsCategory name << ']'! !