'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:38 pm'!

GenerateMethods subclass: #FromCategory
	instanceVariableNames: '
		myCat {Symbol}
		myOrg {SystemOrganizer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!FromCategory methodsFor: 'creation'!

create: cat {Symbol} with: org {SystemOrganizer}

	super create.
	myCat _ cat.
	myOrg _ org! !

!FromCategory methodsFor: 'accessing'!

{String} label
	
	^myCat!

{BooleanVar} passes: cls {Behavior}
	
	^(myOrg listAtCategoryNamed: myCat) includes: cls name!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^true! !

!FromCategory methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	(myOrg listAtCategoryNamed: myCat) do: [:cName {Symbol} |
		| c {Behavior} |
		c _ Smalltalk at: cName.
		aBlock value: c.
		aBlock value: c class]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FromCategory class
	instanceVariableNames: ''!



!FromCategory class methodsFor: 'creation'!

make: cat {Symbol}

	^self make: cat with: SystemOrganization!

make: cat {Symbol} with: org {SystemOrganizer}

	^self create: cat with: org! !

!FromCategory class methodsFor: 'prompting'!

{Symbol | nil} pickACategory
	"Choose a category with a menu."

	^self pickFromCategoryMenu: SystemOrganization categories.!

{Symbol | nil} pickFromCategoryMenu: cats {OrderedCollection of Symbol}
	"Pick a category from a menu"

	| menu {PopUpMenu} 
	  chosenSelector {Symbol} |
	(cats == nil or: [cats size = 0]) 
		ifTrue: [^nil].
	menu _ PopUpMenu hierarchyFrom: cats asSortedCollection sep: '-'.
	(chosenSelector _ menu startUp) = 0
		ifTrue: [^nil]
		ifFalse: [^chosenSelector asSymbol].! !