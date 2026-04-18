'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:45 pm'!

FMSuperTextModel subclass: #FMATMModel
	instanceVariableNames: 'myATM {AttributedTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!
FMATMModel comment:
'This model holds on to an ATM and provides an interface from a splitModel to the ATM.  This is done to keep the split models from knowing when they have a higher level split model above them.
	This model is also a good location to limit the amount of the ATM actually being composed.  It can provide a restricted portion of the ATM to the text composition routines.'!

(FMATMModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMATMModel */
friend SPTR(FMATMModel) fMATMModel (AttributedTextModel * onATM);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMATMModel methodsFor: 'accessing'!

{IntegerVar} charCount
	"This methods returns the number of characters in the model."
	
	^ myATM count!

{IntegerVar} charLimit
	"This method returns the maximum number of characters that this 
	model can return." 

	^ myATM count!

{MuWordArray} chars

	"This method returns all of the characters in the model"
	
	^ myATM asDataTable!

{void} setMaxOf: index {IntegerVar unused} with: aMax
{IntegerVar unused} 
	"This method is used by a line composer to set the
maximum length 
	of a line split to the specified value. This information
is used to 
	determine which lines are of interest when a specific
position is 
	modified"

	^ VOID! !

!FMATMModel methodsFor: 'protected: creation'!

create: atm {AttributedTextModel}

	super create: NULL.
	myATM _ atm! !

!FMATMModel methodsFor: 'subclass accessing'!

{AttributeGroup} attributesAt: charPos {IntegerVar} with:
index {IntegerVar unused}

	"This method returns the character attributes for the
specified position
	relative to the start of the child at index, which for
atm is always 0."
	
	^ myATM attributesAtInt: charPos!

{IntegerVar} charLimitOf: index {IntegerVar unused} 
	"This method is a request from a child to a parent to
return the 
	number of characters that the child could possibly be
concerned 
	with." 

	^ self charLimit!

{MuWordArray} charsFor: index {IntegerVar unused} with:
limit {IntegerVar}

	"This method returns the characters specifically for the
child at index.  Since
	this model has no children, per se, it returns the whole
enchilada (unless limit
	aint zero).  limit is the max number of chars to return."
	
	limit == IntegerVar0
		ifTrue: [^ self chars]
		ifFalse: [^ (self chars subTableBetween: IntegerVar0 with:
limit  ) cast: MuWordArray ]!

{void} deltaCount: index {IntegerVar unused} with: delta
{IntegerVar unused} 
	"This method is used by kids of split models (runs or
other splitmodels) 
	to update the origin information in the splitModel."

	"an atm model just doesn't care..."
	
	^ VOID!

{IntegerVar} indexOf: child {FMTextModel unused}

	"This method returns the parents index for the specified
child"
	
	^ IntegerVar0!

{IntegerRegion} runAt: pos {IntegerVar} with: index
{IntegerVar unused}

	"This method returns the domain of the attribute run
containing the position pos"
	
	^ (myATM runAtInt: pos) quickCast: IntegerRegion! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMATMModel class
	instanceVariableNames: ''!

(FMATMModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMATMModel */
friend SPTR(FMATMModel) fMATMModel (AttributedTextModel * onATM);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMATMModel class methodsFor: 'pseudoconstructors'!

make: onATM {AttributedTextModel}

	^ self create: onATM! !