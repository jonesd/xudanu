'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:01 pm'!

FMBuilder subclass: #ShortReferenceBuilder
	instanceVariableNames: ''
	classVariableNames: 'ReferencePortions {ListModel of: Portion} '
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
ShortReferenceBuilder comment:
'Builds a view onto a reference.
*Eventually, will be a director that has a model describing the format of the view'!

(ShortReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class ShortReferenceBuilder */
friend SPTR(ShortReferenceBuilder)  shortReferenceBuilder
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ShortReferenceBuilder methodsFor: 'build'!

{FMBuilding} build: something {Heaper as: Reference} 
	| reference {Reference} kind {FMBuilding} label {FMBuilding} descriptor {FMBuilding}
	  style {ListStyle} txtBuilder {FMTextBuilder} | 
	reference _ something cast: Reference.
	txtBuilder _ FMTextBuilder make: (ExtentLayout make: (PointPos make: 2000 with: 12)).
	Scaffold fluidBind: (FMScaffold
			make: AttributedTextModel
			with: txtBuilder
			with: Scaffold fluidGet)
		during: 
			[kind _ Scaffold fluidGet build: reference kind.
			label _ Scaffold fluidGet build: reference label.
			descriptor _ Scaffold fluidGet build: reference descriptor].
	style _ ListStyle defaultHorizontal.
	style setSpacing: 4.
	^FMBuilding make: (ListMultiViewer make: (ListModel make: (MuArray
					array: kind view
					with: label view
					with: descriptor view))
			with: (PortionListComp make: style with: ReferencePortions))
		with: NULL! !

!ShortReferenceBuilder methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name
	<< 'ReferencePortions = ' << ReferencePortions! !

!ShortReferenceBuilder methodsFor: 'private: creation'!

create
	super create! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ShortReferenceBuilder class
	instanceVariableNames: ''!

(ShortReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class ShortReferenceBuilder */
friend SPTR(ShortReferenceBuilder)  shortReferenceBuilder
();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ShortReferenceBuilder class methodsFor: 'smalltalk: initialization'!

cleanupGarbage

	self linkTimeNonInherited!

initTimeNonInherited
	self REQUIRES: IntegerRegion.
	self REQUIRES: MuArray.
	self REQUIRES: ListModel.
	self REQUIRES: Portion.
	ReferencePortions _ ListModel make: (MuArray
		array: (Portion make: (IntegerRegion after: 12) with: 0.25)
		with: (Portion make: (IntegerRegion after: 12) with: 0.3)
		with: (Portion make: (IntegerRegion after: 12) with: 0.45))!

linkTimeNonInherited
	ReferencePortions _ NULL! !

!ShortReferenceBuilder class methodsFor: 'make'!

make
	^self create! !