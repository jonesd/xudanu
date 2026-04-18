'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:32 pm'!

MethodFilter subclass: #AndMethodFilter
	instanceVariableNames: '
		myFilterA {MethodFilter}
		myFilterB {MethodFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!AndMethodFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction

	^MethodAction combine: myFilterA fetchAction with: myFilterB fetchAction!

{String} label
	
	| labA {String} labB {String} |
	labA _ myFilterA label.
	labB _ myFilterB label.
	labA == nil
		ifTrue: [^labB].
	labB == nil
		ifTrue: [^labA].
	^labA, ' and ', labB!

{BooleanVar} passes: cls {Behavior} 

	^(myFilterA passes: cls) and: [myFilterB passes: cls]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^(myFilterA passes: cls with: sel with: code) 
	  and: [myFilterB passes: cls with: sel with: code]! !

!AndMethodFilter methodsFor: 'creation'!

create: filterA {MethodFilter} with: filterB {MethodFilter}

	super create.
	myFilterA _ filterA.
	myFilterB _ filterB! !