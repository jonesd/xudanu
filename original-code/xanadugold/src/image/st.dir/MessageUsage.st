'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:28 pm'!

Object subclass: #MessageUsage
	instanceVariableNames: '
		myUnimplemented {Set of: Symbol}
		myUnused {Set of: Symbol}
		myUsedAndImplemented {Set of: Symbol}'
	classVariableNames: 'TheStaleMessageUsageCache {MessageUsage} '
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!
MessageUsage comment:
'The three instance variables as necessarily mutually exclusive sets'!



!MessageUsage methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory << '(' << myUnused size << ' unused messages,
		' << myUnimplemented size << ' unimplemented messages,
		' << myUsedAndImplemented size << ' used and implemented messages)'! !

!MessageUsage methodsFor: 'accessing'!

{void} allImplementedDo: aBlock {BlockClosure of: Symbol}
	
	myUsedAndImplemented do: aBlock.
	myUnused do: aBlock!

{void} allMentionedDo: aBlock {BlockClosure of: Symbol}
	
	myUsedAndImplemented do: aBlock.
	myUnused do: aBlock.
	myUnimplemented do: aBlock!

{void} allUnimplementedDo: aBlock {BlockClosure of: Symbol}
	
	myUnimplemented do: aBlock!

{void} allUnusedDo: aBlock {BlockClosure of: Symbol}
	
	myUnused do: aBlock!

{void} allUsedAndImplementedDo: aBlock {BlockClosure of: Symbol}
	
	myUsedAndImplemented do: aBlock!

{void} allUsedDo: aBlock {BlockClosure of: Symbol}
	
	myUsedAndImplemented do: aBlock.
	myUnimplemented do: aBlock!

{BooleanVar} isImplemented: mess {Symbol}
	
	^(myUsedAndImplemented includes: mess) or: [myUnused includes: mess]!

{BooleanVar} isMentioned: mess {Symbol}
	"A selector is mentioned if it's used or implemented"
	
	^(myUsedAndImplemented includes: mess) 
	 or: [(myUnimplemented includes: mess)
	 or: [myUnused includes: mess]]!

{BooleanVar} isUnusedAndImplemented: mess {Symbol}
	
	^myUnused includes: mess!

{BooleanVar} isUsed: mess {Symbol}
	
	^(myUsedAndImplemented includes: mess) or: [myUnimplemented includes: mess]!

{BooleanVar} isUsedAndImplemented: mess {Symbol}
	
	^myUsedAndImplemented includes: mess!

{BooleanVar} isUsedAndUnimplemented: mess {Symbol}
	
	^myUnimplemented includes: mess!

{void} update
	
	| implemented {Set of: Symbol} |
	Cursor execute showWhile: 
		[implemented _ IdentitySet new.
		Smalltalk allBehaviorsDo: [:cl {Behavior} |
			implemented addAll: cl selectors].
		"implemented addAll: TypeDescription declaredAttributes."
	
		myUnimplemented _ IdentitySet new.
		myUsedAndImplemented _ IdentitySet new.
		Smalltalk allBehaviorsDo: [:class {Behavior} |
			class methodsDo: [:sel {Symbol} :code {CompiledMethod} |
				(sel ~~ #DoIt and: [sel ~~ #DoItIn:])
					ifTrue:
						[code literalSymbols do: [:mess {Symbol} |
							(implemented includes: mess)
								ifTrue: [myUsedAndImplemented add: mess]
								ifFalse: [mess == #alternatives ifTrue: [self halt].
										myUnimplemented add: mess]]]]].
		Smalltalk specialSelectorSet do: [:mess {Symbol} |
					(implemented includes: mess)
						ifTrue: [myUsedAndImplemented add: mess]
						ifFalse: [myUnimplemented add: mess]].
						
		myUnused _ implemented select: [:mess {Symbol} |
			(myUsedAndImplemented includes: mess) not]]! !

!MessageUsage methodsFor: 'creation'!

create

	super create.
	myUnimplemented _ IdentitySet new.
	myUnused _ IdentitySet new.
	myUsedAndImplemented _ IdentitySet new.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MessageUsage class
	instanceVariableNames: ''!



!MessageUsage class methodsFor: 'creation'!

fresh

	self stale update.
	^self stale!

stale

	TheStaleMessageUsageCache == nil
		ifTrue: [TheStaleMessageUsageCache _ self create].
	^TheStaleMessageUsageCache! !