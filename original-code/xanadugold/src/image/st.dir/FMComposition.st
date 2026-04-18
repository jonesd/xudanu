'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:07 pm'!

Heaper subclass: #FMComposition
	instanceVariableNames: '
		myWidth {IntegerVar}
		myLayoutWidth {IntegerVar}
		myHeight {IntegerVar}
		myCount {IntegerVar}
		myTermination {CompositorEnum}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Compositors-Basic'!

(FMComposition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMComposition methodsFor: 'accessing'!

{IntegerVar} count
	^ myCount!

{IntegerVar} displayHeight
	^ myHeight!

{IntegerVar} displayWidth
	^ myWidth!

{IntegerVar} layoutWidth

	^ myLayoutWidth!

{CompositorEnum} reason
	^ myTermination! !

!FMComposition methodsFor: 'creation'!

create: wid {IntegerVar} with: layoutWidth {IntegerVar} with: hite {IntegerVar} with: count {IntegerVar} with: reason {CompositorEnum}

	super create.
	myWidth _ wid.
	myLayoutWidth _ layoutWidth.
	myHeight _ hite.
	myCount _ count.
	myTermination _ reason! !

!FMComposition methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '('.
	oo << myWidth << 'x' << myHeight << ', '.
	oo << myCount << ', ' << myTermination << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMComposition class
	instanceVariableNames: ''!

(FMComposition getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMComposition class methodsFor: 'pseudo constructors'!

make: width {IntegerVar} with: count {IntegerVar} with: reason {CompositorEnum} with: oldComp {FMComposition} 
	^self
		create: width
		with: oldComp layoutWidth
		with: oldComp displayHeight
		with: count
		with: reason!

make: width {IntegerVar} with: layoutWidth {IntegerVar} with: hite {IntegerVar} with: count {IntegerVar} with: reason {CompositorEnum}

	^ self create: width with: layoutWidth with: hite with: count with: reason! !