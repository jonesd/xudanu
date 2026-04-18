'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:06 pm'!

Environment subclass: #HierarchicalEnvironment
	instanceVariableNames: 'parent '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-Environments'!
HierarchicalEnvironment comment:
'An HierarchicalEnvironment is an Environment that can create hierarchical environments that know their parent. A parent bequeaths local variables to its descendents. Thus, an instance of this class is an Environment whose total set of local variables includes its own and any that it inherits from a chain of parents.
Instance Variables:
	parent	<Environment> 	the parent of the receiver'!


!HierarchicalEnvironment methodsFor: 'accessing'!

localScopes
	"Answer an OrderedCollection containing the receiver's local 
	variables. This is used by an EnvironmentCompiler for determining 
	the lexical scope of variables."

	| env scopes |
	scopes := OrderedCollection new.
	env := self.
	[env == nil]
		whileFalse: 
			[scopes addLast: env locals.
			env := env parent].
	^scopes!

parent
	"Answer the receiver's parent."

	^parent!

parent: aParent 
	"Set the receiver's parent to be aParent."

	parent := aParent! !