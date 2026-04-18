'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:18 pm'!

XnDependent subclass: #XnModel
	instanceVariableNames: '
		myReactors {XuReactor smalltalk}
		dependents {ImmuSet}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Update Mechanism'!
XnModel comment:
'This class provides the protocol for registering (addDependent), deregistering (removeDependent), and informing (changed) dependents about changes in the external behavior of aspects of the model.  It also provides an implementation of this protocol.  Unchangeable subclasses are free to change addDependent to do nothing.  Since the model can''t change, there''s nothing to inform dependents about.  As far as the dependents are concerned, they are still registering and deregistering themselves normally.  In order to ensure that the above is a semantics free optimization "hasDependents" is protected (since it will say FALSE if someone has engaged in the illusory adding of themselves).
	
	If the model changes its internals in a way which isn''t visible through its public external behavior, such as updating an internal cache, then it should not update its dependents.  A given class of model will probably be defined along with a set classes of UpdateRecord, one for each aspect of its external behavior which it wants to separately report.  The meaning of "aspect" is in the eye of the designer of the particular model class.
	
	BUG BUG BUG:  Not all subclasses of XuModel in fact inform their dependents of changes to themselves.  In particular, ScruSets do not.  See ScruSet.'!

(XnModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #REACTOR.MATRIARCH; add: #EQ; add: #(REACTOR XuReactor ); yourself)!

!XnModel methodsFor: 'accessing'!

{void} addDependent: dependent {XnDependent} 
	"How a dependent becomes registered with the model. The model must now 
	provide it with updates when the model changes. Redundant calls (adding a 
	dependent which is already registered) has no effect."

	dependents == NULL
		ifTrue: [dependents _ ImmuSet make with: dependent]
		ifFalse: [dependents _ dependents with: dependent]!

{void} changed: updateRecord {UpdateRecord} 
	"Send the updateRecord to all the dependents."

	dependents ~~ NULL ifTrue:
		[dependents stepper forEach: 
			[:dep {XnDependent} | 
			dep update: updateRecord from: self]].
	"This cannot delete the updateRecord because
	 dependents might hold onto it (queue it up). "!

{void} removeDependent: dependent {XnDependent} 
	"Unregister this dependent as a dependent of the model. Note that afterwards 
	it is no longer registered independently of how many times it was registered 
	using addDependent."
	
	dependents ~~ NULL
		ifTrue: 
			[dependents _ dependents without: dependent.
			dependents isEmpty
				ifTrue: 
					[dependents destroy.
					dependents _ NULL]]! !

!XnModel methodsFor: 'instance creation'!

create
	super create.
	dependents _ NULL! !

!XnModel methodsFor: 'protected: testing'!

{BooleanVar} hasDependents
	"Do I actually have any dependents. I.e., if I do a 'this->changed(treeFall)', will 
	anybody actually hear it? Note that this is not the same as the question: 
	""Have any dependents been registered with addDependent which haven't been 
	removed?"" See class comment."

	^dependents ~~ NULL! !

!XnModel methodsFor: 'smalltalk: private: smalltalk private'!

fixup
	dependents == nil ifTrue:[Transcript show: 'n'; endEntry.
		dependents _ NULL].
	dependents ~~ NULL ifTrue: [dependents _ NULL. Transcript
show: 'cleaned'; cr; endEntry]! !

!XnModel methodsFor: 'private: smalltalk: private'!

clean
	dependents == nil ifTrue: [dependents _ NULL].
	dependents ~~ NULL ifTrue: [dependents _ NULL]! !

!XnModel methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XnModel class
	instanceVariableNames: ''!

(XnModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #REACTOR.MATRIARCH; add: #EQ; add: #(REACTOR XuReactor ); yourself)!

!XnModel class methodsFor: 'smalltalk: group think'!

{Collection of: XnModel} modelInstances

	^ self modelInstances: OrderedCollection new!

{Collection of: XnModel} modelInstances: startCollection

	| tCollection |
	tCollection _ startCollection copy.
	tCollection addAll: self allInstances.
	self subclasses do: [:sc | tCollection addAll: (sc
modelInstances)].
	^ tCollection! !