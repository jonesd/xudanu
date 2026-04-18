'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:43 pm'!

MethodFilter subclass: #InlineCandidateFilter
	instanceVariableNames: ''
	classVariableNames: 'MaxTally {Dictionary of: Class with: Integer} '
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!

(InlineCandidateFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InlineCandidateFilter methodsFor: 'accessing'!

{String} label
	
	^'Inline Candidate Methods'!

{BooleanVar} passes: cls {Behavior}
	
	^cls ~= Object and: [cls ~= Object class]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	| prot {String} 
	  meth {MthodNode} 
	  tally {Dictionary of: Class with: Integer} 
	  messages {Collection of: Symbol} |

	"Is it overridden? if so, then it's not an inline candidate"
	cls isMeta ifFalse:
		[cls allSubclasses do: [:c1 {Behavior} | 
			(c1 includesSelector: sel) ifTrue:
				[^false]]].
	
	"does it match a non-inlineish selector pattern?"
	#('*Time*Inherited' 'create*' 'destructor*' 'blast.*' 'main*' 'info.*') do: [:patt {String} |
		(patt match: sel) ifTrue:
			[^false]].
	
	"does it's protocol have a non-inlineish attribute?"
	prot := cls organization getCategoryOfElement: sel.
	#(smalltalk generated exceptions hooks extern macros) do: [:attr {Symbol} |
		(cls protocol: prot hasAttribute: attr) ifTrue:
			[^false]].
	
	"does it send too many messages, or does it send any non inlinish ones"
	messages := code messages.
	messages size > 2 ifTrue:
		[^false].
	#('create*' 'shouldImplement' 'unimplemented') do: [:patt2 {String} |
		messages do: [:msg {Symbol} |
			(patt2 match: msg) ifTrue:
				[^false]]].
		
	"Does the number of parsenodes of any type exceed the allowable max of that type?"
	meth := SmalltalkCompiler parse: (cls sourceCodeAt: sel) class: cls.
	tally := Dictionary new.
	meth properDo: [:node {ProgramNode} |
		| i {Integer} |
		i _ tally at: node class ifAbsent: [0].
		tally at: node class put: i + 1].
	tally keyValuesDo: [:k {Class} :v {Integer} |
		| j {Integer} |
		j _ MaxTally at: k ifAbsent: [0].
		v > j ifTrue: [^false]].
		
	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InlineCandidateFilter class
	instanceVariableNames: ''!

(InlineCandidateFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!InlineCandidateFilter class methodsFor: 'creation'!

{void} initialize
	"InlineCandidateFilter initialize"
	
	MaxTally := Dictionary new.
	MaxTally at: MethodNode put: 1.
	MaxTally at: SimpleMessageNode put: 1.
	MaxTally at: MessageNode put: 1.
	MaxTally at: ParameterNode put: 10.
	MaxTally at: ReturnNode put: 1.
	MaxTally at: AssignmentNode put: 1.
	MaxTally at: LiteralNode put: 5.
	MaxTally at: VariableNode put: 10.
	MaxTally at: BlockNode put: 1.
	MaxTally at: SequenceNode put: 1.!

make

	MaxTally == nil ifTrue:
		[self initialize].
	^self create! !

InlineCandidateFilter initialize!
