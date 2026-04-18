'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:35 pm'!

MethodFilter subclass: #ClassVisibilityFilter
	instanceVariableNames: 'myVisibility {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!ClassVisibilityFilter methodsFor: 'creation'!

create: vis {Symbol}

	super create.
	myVisibility _ vis! !

!ClassVisibilityFilter methodsFor: 'accessing'!

{String} label
	
	^'Classes of ', myVisibility, ' Visibility'!

{BooleanVar} passes: cls {Behavior} 

	| cxc {CxxClassDescription | nil} grp {CxxClassGroup | nil} |
	cxc _ cls fetchCxxClassDescription.
	(cxc == nil or: [(grp _ cxc fetchGroup) == nil])
		ifTrue: [^myVisibility == #unclassified]
		ifFalse: [^myVisibility == grp visibility]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClassVisibilityFilter class
	instanceVariableNames: ''!



!ClassVisibilityFilter class methodsFor: 'creation'!

make: vis {Symbol}

	^self create: vis! !