'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:02 pm'!

FMBuilder subclass: #TwoLineReferenceBuilder
	instanceVariableNames: ''
	classVariableNames: 'TwoLineReferencePortions {ListModel of: Portion} '
	poolDictionaries: ''
	category: 'Xanadu-winmod'!
TwoLineReferenceBuilder comment:
'Builds a view onto a reference.
*Eventually, will be a director that has a model
describing the format of the view'!

(TwoLineReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class TwoLineReferenceBuilder */
friend SPTR(TwoLineReferenceBuilder) 
twoLineReferenceBuilder ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TwoLineReferenceBuilder methodsFor: 'private: creation'!

create
	super create! !

!TwoLineReferenceBuilder methodsFor: 'build'!

{FMBuilding} build: something {Heaper as: Reference} 
	| reference {Reference} kind {FMBuilding} label {FMBuilding} descriptor {FMBuilding}
	  style {ListStyle} txtBuilder {FMTextBuilder} sumText {AttributedTextModel}
	  author {FMBuilding} furstlyne {Viewer} | 
	reference _ something cast: Reference.
	sumText _ (MuWordArray make.charVector: 'marcs')
				convert: AttributedTextModel.
	txtBuilder _ FMTextBuilder make: (ExtentLayout make: (PointPos make: 2000 with: 12)).
	Scaffold fluidBind: (FMScaffold
			make: AttributedTextModel
			with: txtBuilder
			with: Scaffold fluidGet)
		during: 
			[kind _ Scaffold fluidGet build: reference kind.
			label _ Scaffold fluidGet build: reference label.
			author _ Scaffold fluidGet build: sumText.
			descriptor _ Scaffold fluidGet build: reference descriptor].
	style _ ListStyle defaultHorizontal.
	style setSpacing: 4.
	furstlyne _ ListMultiViewer make: (ListModel make: (MuArray
						array: kind view
						with: label view
						with: author view))
				with: (PortionListComp make: style with: TwoLineReferencePortions).
	^FMBuilding make: (ListMultiViewer make: (ListModel make: (MuArray
				array: furstlyne with: descriptor view))
			with: (BoundingListComp make: ListStyle defaultVertical))
		with: NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TwoLineReferenceBuilder class
	instanceVariableNames: ''!

(TwoLineReferenceBuilder getOrMakeCxxClassDescription)
	friends:
'/* friends for class TwoLineReferenceBuilder */
friend SPTR(TwoLineReferenceBuilder) 
twoLineReferenceBuilder ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TwoLineReferenceBuilder class methodsFor: 'smalltalk: initialization'!

cleanupGarbage

	self linkTimeNonInherited!

initTimeNonInherited
	self REQUIRES: IntegerRegion.
	self REQUIRES: MuArray.
	self REQUIRES: ListModel.
	self REQUIRES: Portion.
	TwoLineReferencePortions _ ListModel make: (MuArray
		array: (Portion make: (IntegerRegion after: 12) with: 0.25)
		with: (Portion make: (IntegerRegion after: 12) with: 0.5)
		with: (Portion make: (IntegerRegion after: 12) with: 0.25))!

linkTimeNonInherited
	TwoLineReferencePortions _ NULL! !

!TwoLineReferenceBuilder class methodsFor: 'make'!

make
	^self create! !