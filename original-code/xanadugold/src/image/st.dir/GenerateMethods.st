'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:41 pm'!

MethodFilter subclass: #GenerateMethods
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!GenerateMethods methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 
	"Enumerate exactly those classes for which self passes:"
	"Like subclassResponsibility, but subclasses are only obligated to override this if 
	they don't override the default methodReps:, which uses it."

	self hack.
	self subclassResponsibility! !

!GenerateMethods methodsFor: 'accessing'!

{NOWAIT} browse: initSel {MethodRep default: nil} 
	with: methods {(Collection of: MethodRep) default: nil}
	with: browserGen {BrowserGenerator default: nil}

	| aBrowser {MethodSetBrowser} 
	  meths {Collection of: MethodRep} |
	  
	Cursor execute showWhile:
		[methods == nil
			ifTrue: [meths _ self methodReps]
			ifFalse: [meths _ methods].
		meths isEmpty 
			ifTrue: [^Transcript cr; show: 'Nobody'].
		aBrowser _ MethodSetBrowser make: self with: initSel with: meths with: browserGen].
	BrowserView 
		openMethodSetBrowserOn: aBrowser 
		label: self label
		initialSelection: aBrowser fetchAction!

{MethodAction | nil} fetchAction
	
	^nil!

{MethodGenerator} filteredBy: filter {MethodFilter}
	
	^GenerateAndTest create: self with: filter!

{String} label
	
	self subclassResponsibility!

{Collection of: MethodRep} methodReps

	^self methodReps: (SourceMethods make)!

{Collection of: MethodRep} methodReps: filter {MethodFilter}
	"Note that we don't check (self passes: cls) below because we assume that
	behaviorsDo: will not enumerate such classes"
	
	| result {Collection of: MethodRep} |
	result _ OrderedCollection new.
	self behaviorsDo: [:cls {Behavior} |
		(filter passes: cls)
			ifTrue: [cls methodsDo: [:sel {Symbol} :code {CompiledMethod} |
					((self passes: cls with: sel with: code) 
					 and: [filter passes: cls with: sel with: code])
						ifTrue: [result add: (MethodRep make: cls with: sel)]]]].
	^result!

{BooleanVar} passes: cls {Behavior} 

	self subclassResponsibility!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	self subclassResponsibility!

{MethodFilter} unionWith: other {MethodFilter}

	((other isKindOf: GenerateMethods) and: [(other isKindOf: AllMethods) not])
		ifTrue: [self halt. ^OrMethodGenerator create: self with: other]
		ifFalse: [^super unionWith: other]! !