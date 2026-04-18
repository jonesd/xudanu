'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:30 pm'!

IdentityDictionary variableSubclass: #MethodDictionary
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Support'!
MethodDictionary comment:
'MethodDictionaries behave just the same as IdentityDictionaries, except that removal is implemented as an atomic operation.  This allows the interpreter to access methodDictionaries removal without getting confused.

Instance Variables: *indexed*'!


!MethodDictionary methodsFor: 'dictionary removing'!

methodArray
	^valueArray!

removeKey: key ifAbsent: errorBlock
	"Remove the key from a copy and then use become: to effect and atomic update."

	| value |
	value _ self at: key ifAbsent: [^errorBlock value].
	self become: (self copy removeDangerouslyKey: key ifAbsent: []).
	^value! !

!MethodDictionary methodsFor: 'testing'!

selector: sel refersTo: literal
	"Answer a collection of selectors whose methods
	access the argument directly as a literal."

	| special method |
	special _ Smalltalk specialSelectorIndexOf: literal.
	^(method _ self at: sel) == nil and: 
			[(method refersToLiteral: literal) or:
				[special > 0 and: [method sendsSpecialSelector: special]]]!

selector: sel refersTowards: literal
	"Answer a collection of selectors whose methods
	access the argument directly or indirectly as a literal."

	| special method |
	special _ Smalltalk specialSelectorIndexOf: literal.
	^(method _ self at: sel) == nil and: 
			[(method refersTowardsLiteral: literal) or:
				[special > 0 and: [method sendsSpecialSelector: special]]]!

{Collection of: Symbol} whichSelectorsReferTo: literal
	"Answer a collection of selectors whose methods
	access the argument directly as a literal."

	| result {Collection of: Symbol} special |
	special _ Smalltalk specialSelectorIndexOf: literal.
	result _ OrderedCollection new.
	special > 0
		ifTrue: [self keyValuesDo: [:sel {Symbol} :method {CompiledMethod} |
				((method refersToLiteral: literal) 
				 or: [method sendsSpecialSelector: special])
				 	ifTrue: [result add: sel]]]
		ifFalse: [self keyValuesDo: [:sel {Symbol} :method {CompiledMethod} |
				(method refersToLiteral: literal)
					ifTrue: [result add: sel]]].
	^result!

{Collection of: Symbol} whichSelectorsReferTowards: literal
	"Answer a collection of selectors whose methods
	access the argument directly or indirectly as a literal."

	| result {Collection of: Symbol} special |
	special _ Smalltalk specialSelectorIndexOf: literal.
	result _ OrderedCollection new.
	special > 0
		ifTrue: [
			self keyValuesDo: [:sel {Symbol} :method {CompiledMethod} |
				((method refersTowardsLiteral: literal) 
				 or: [method sendsSpecialSelector: special])
				 	ifTrue: [result add: sel]]]
		ifFalse: [
			self keyValuesDo: [:sel {Symbol} :method {CompiledMethod} |
				(method refersTowardsLiteral: literal)
					ifTrue: [result add: sel]]].
	^result! !