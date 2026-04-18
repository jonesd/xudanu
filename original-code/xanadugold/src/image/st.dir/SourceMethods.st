'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:51 pm'!

GenerateMethods subclass: #SourceMethods
	instanceVariableNames: ''
	classVariableNames: 'TheSourceOnlyFlag {BooleanVar} '
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!SourceMethods methodsFor: 'accessing'!

{String} label
	
	^nil!

{Collection of: MethodRep} methodReps

	^self methodReps: (AllMethods make)!

{Collection of: MethodRep} methodReps: filter {MethodFilter}
	
	
	| result {Collection of: MethodRep} |
	result _ OrderedCollection new.
	self behaviorsDo: [:cls {Behavior} |
		(filter passes: cls)
			ifTrue: [
				| genSels {(IdentitySet of: Symbol) | nil} org {ClassOrganizer} |
				genSels _ nil.
				org _ cls organization.
				org categories do: [:prot {Symbol} |
					(cls protocol: prot hasAttribute: #generated)
						ifTrue: [
							| sels {Collection of: Symbol} |
							sels _ org listAtCategoryNamed: prot.
							genSels == nil
								ifTrue: [genSels _ sels asIdentitySet]
								ifFalse: [genSels addAll: sels]]].
				genSels == nil
					ifTrue: [
						cls methodsDo: [:sel {Symbol} :code {CompiledMethod} |
							(sel ~~ #DoIt
							 and: [sel ~~ #DoItIn:
							 and: [filter passes: cls with: sel with: code]])
								ifTrue: [result add: (MethodRep make: cls with: sel)]]]
					ifFalse: [
						genSels addAll: #(DoIt DoItIn:).
						cls methodsDo: [:sel {Symbol} :code {CompiledMethod} |
							((genSels includes: sel) not
							 and: [filter passes: cls with: sel with: code])
								ifTrue: [result add: (MethodRep make: cls with: sel)]]]]].
	^result!

{BooleanVar} passes: cls {Behavior}
	
	^cls isGenerated not!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^sel ~~ #DoIt and: [sel ~~ #DoItIn:
	  and: [(cls 
	  		protocol: (cls organization categoryOfElement: sel) 
	  		hasAttribute: #generated) not]]! !

!SourceMethods methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	Smalltalk allBehaviorsDo: [:cls {Behavior} |
		cls isGenerated not
			ifTrue: [aBlock value: cls]]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SourceMethods class
	instanceVariableNames: ''!



!SourceMethods class methodsFor: 'preferences'!

{BooleanVar} isSourceOnly

	TheSourceOnlyFlag == nil ifTrue:
		[TheSourceOnlyFlag := true].

	^TheSourceOnlyFlag!

sourceOnly: flag {BooleanVar}

	TheSourceOnlyFlag := flag! !

!SourceMethods class methodsFor: 'creation'!

make

	TheSourceOnlyFlag == nil ifTrue:
		[TheSourceOnlyFlag := true].
		
	TheSourceOnlyFlag ifTrue:
		[^self create]
	ifFalse:
		[^AllMethods make]! !