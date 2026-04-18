'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:17 pm'!

Heaper subclass: #XnDependent
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Update Mechanism'!
XnDependent comment:
'Only kinds of XuDependents can register themselves as dependents of XuModels.  When a model changes it behavior, it should inform all its dependents by sending them (in an "updateFrom" message) an UpdateRecord describing the nature of the state change.  Dependents override this method so they can react to updates from their model.  UpdateRecords themselves come in a type hierarchy.  If a dependent gets an UpdateRecord which is a kind of a type it knows, then it can assume that only that aspect of the model changed.  I.e., subclasses of a particular UpdateRecord type represent (not necessarily strict) subsets of aspects of a model (with corresponding new protocol to inquire about that aspect).
	
	Note that this allows the protocol by which a model informs its dependents to be enhanced over time to allow finer discrimination while still providing upwards compatability.  Old dependents can type-discriminate UpdateRecords to a more limited degree and therefore may overestimate how much has changed.  This is safe, merely inefficient.  What would be unsafe is for the protocol to evolve in a way that appears upwards compatable (i.e., no type checking errors), but results in old dependents underestimating what has changed about a model.  This is an error in the Smalltalk-80 update mechanism that we avoid.
	
	An important special case of the above rule:  If a dependent does not recognize a particular kind of UpdateRecord type (which is equivalent to saying: it cannot discriminate it to a type any more specific that UpdateRecord) then it must assume that any aspect of the model may have changed, and re-inquire about all of the model''s changeable state about which it cares.
	
	BUG BUG BUG:  Most of our actual updateFrom methods do not actually obey the above paragraph.  Instead many of them engage in the EXTREMELY DANGEROUS habit of ignoring "updateFrom"s with UpdateRecords whose more specific type they don''t recognize.  We will fix this somehow.  What we''d like to do is find a programming idiom which doesn''t tempt us into writing code which is broken in this fashion.  In fact we are thinking of replacing the entire dependents/update mechanism with "Effectors" (see "Effectors").  However, if we switch we will probably take pains to support the old mechanism for awhile afterwards.
	
	Since the updateFrom message also includes the sender (the XuModel which changed), a single XuDependent can register itself with several models and still distinguish betwen them.'!

(XnDependent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XnDependent methodsFor: 'updating'!

{void} update: updateRecord {UpdateRecord} from: sender {XnModel} 
	"Since abstract classes have no state to change, do nothing. Concrete classes 
	should default to changing everything if they do not have a special handler for 
	a particular type of update.
	
	See bug notice in class comment of XuDependent."! !

!XnDependent methodsFor: 'smalltalk:'!

inspectPieces
	"Return pieces to be used in a tree browser."

	^#()!

treeInspect
	| seen  |
	seen _ Set new.
	EntView openOn: (TreeBarnacle new
			buildOn: self
			gettingChildren: 
				[:handle | 
				(seen includes: handle)
					ifTrue: [#()]
					ifFalse: [seen add: handle.
							handle inspectPieces]]
			gettingImage: [:handle | handle displayString asDisplayText]
			at: 0 @ 0
			vertical: true
			separation: 10 @ 10)! !

!XnDependent methodsFor: 'testing'!

{UInt32} hashForEqual
	^self asOop!

{BooleanVar} isEqual: other {Heaper}
	^self == other! !

!XnDependent methodsFor: 'smalltalk: protection'!

addDependent: something
	self error: 'Cannot add a dependent to XuDependent'!

changed: ur
	self error: 'XuDependent cannot change!!'!

hasDependents
	self error: 'Cannot ask for dependents from XuDependent'!

removeDependent: something
	self error: 'Cannot remove dependents from XuDependent'! !