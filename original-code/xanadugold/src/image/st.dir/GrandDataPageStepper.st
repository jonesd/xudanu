'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:26 pm'!

Stepper subclass: #GrandDataPageStepper
	instanceVariableNames: '
		page {GrandDataPage}
		entryIndex {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-class-stuff'!

(GrandDataPageStepper getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!GrandDataPageStepper methodsFor: 'operations'!

{GrandEntry} entry
	^ (page entryAt: entryIndex) basicCast: GrandEntry!

{Heaper wimpy} fetch
	self shouldNotImplement.
	^ NULL!

{BooleanVar} hasValue
	^ entryIndex < page entryCount!

{void} step
	entryIndex _ entryIndex + 1.
	self verifyEntry! !

!GrandDataPageStepper methodsFor: 'private: create'!

create: aPage {GrandDataPage} with: index {IntegerVar}
	super create.
	page _ aPage.
	entryIndex _ index.
	self verifyEntry.! !

!GrandDataPageStepper methodsFor: 'private: private'!

{void} verifyEntry
	[entryIndex < page entryCount and: [(page entryAt: entryIndex) == NULL]]
		whileTrue:
			[entryIndex _ entryIndex + 1]! !

!GrandDataPageStepper methodsFor: 'create'!

{Stepper} copy
	^ GrandDataPageStepper create: page with: entryIndex!

create: aPage {GrandDataPage}
	super create.
	page _ aPage.
	entryIndex _ IntegerVar0.
	self verifyEntry! !