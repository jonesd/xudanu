'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:08 pm'!

XnDependent subclass: #RangeToItemSchnert
	instanceVariableNames: '
		selectionInternal {SelectionObject}
		booleanModelsInternal {ScruTable of: BooleanModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Selection'!

(RangeToItemSchnert getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!RangeToItemSchnert methodsFor: 'updating'!

{void} update: ur {UpdateRecord unused} from: selection
{XnModel} 
	"This is the most brute force routine!! The update will
eventually 
	have delta information in it."

	selection == selectionInternal
		ifTrue: 
			[| range {IntegerRegion} start {IntegerVar} stop
{IntegerVar} i {IntegerVar} |
			range _ selectionInternal selection cast: IntegerRegion.
			start _ range start.
			stop _ range stop.
			i _ 1.
			booleanModelsInternal stepper forEach: [:bm
{BooleanModel} | 
				bm setValue: (start <= i and: [i <= stop]).
				i _ i + 1]]! !

!RangeToItemSchnert methodsFor: 'create/delete'!

create: selection{SelectionObject} with: booleanModels{ScruTable of: BooleanModel}
	self create.
	selectionInternal _ selection.
	selection addDependent: self.
	booleanModelsInternal _ booleanModels! !

!RangeToItemSchnert methodsFor: 'protected: creation'!

{void} destruct
	selectionInternal removeDependent: self.
	selectionInternal _ NULL.
	booleanModelsInternal _ NULL.
	super destruct! !