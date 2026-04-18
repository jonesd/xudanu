'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:49 pm'!

FMTextModel subclass: #FMSuperTextModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!
FMSuperTextModel comment:
'The FMSuperTextModel is an abstract class that adds protocol for maintaining and accessing sub models.'!

(FMSuperTextModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMSuperTextModel methodsFor: 'protected: creation'!

create: withParent {FMSuperTextModel}

	super create: withParent! !

!FMSuperTextModel methodsFor: 'deferred: accessing'!

{IntegerVar} charCount
	"This methods returns the number of characters in the model."
	
	self subclassResponsibility!

{IntegerVar} charLimit
	"This method returns the maximum number of characters that this 
	model can return."

	self subclassResponsibility!

{MuWordArray} chars

	"This method returns all of the characters in the model"
	
	self subclassResponsibility!

{void} setMaxOf: index {IntegerVar} with: aMax {IntegerVar} 
	"This method is used by a line composer to set the maximum length 
	of a line split to the specified value. This information is used to 
	determine which lines are of interest when a specific position is 
	modified."

	self subclassResponsibility! !

!FMSuperTextModel methodsFor: 'subclass accessing'!

{AttributeGroup} attributesAt: charPos {IntegerVar} with: index {IntegerVar}

	"This method returns the character attributes for the specified position
	relative to the start of the specified child (index)"
	
	self subclassResponsibility!

{IntegerVar} charLimitOf: index {IntegerVar} 
	"This method is a request from a child to a parent to return the 
	number of characters that the child could possibly be concerned 
	with."

	self subclassResponsibility!

{MuWordArray} charsFor: index {IntegerVar} with: limit {IntegerVar}

	"This method returns the characters specifically for the specified child"
	
	self subclassResponsibility!

{void} deltaCount: index {IntegerVar} with: delta {IntegerVar} 
	"This method is used by kids of split models (runs or other splitmodels) 
	to update the origin information in the splitModel."

	self subclassResponsibility!

{IntegerVar} indexOf: child {FMTextModel}

	"This method returns the parents index for the specified child"
	
	self subclassResponsibility!

{IntegerRegion} runAt: pos {IntegerVar} with: index {IntegerVar}

	"This method returns the domain of the attribute run containing the position pos"
	
	self subclassResponsibility! !