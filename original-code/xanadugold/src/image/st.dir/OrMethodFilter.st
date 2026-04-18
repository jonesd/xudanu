'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:48 pm'!

MethodFilter subclass: #OrMethodFilter
	instanceVariableNames: '
		myFilterA {MethodFilter}
		myFilterB {MethodFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!OrMethodFilter methodsFor: 'accessing'!

{MethodAction | nil} fetchAction

	^MethodAction combine: myFilterA fetchAction with: myFilterB fetchAction!

{String} label
	
	^'(', myFilterA label, ') or (', myFilterB label, ')'!

{BooleanVar} passes: cls {Behavior} 

	^(myFilterA passes: cls) or: [myFilterB passes: cls]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^((myFilterA passes: cls) and: [myFilterA passes: cls with: sel with: code]) 
	 or: [(myFilterB passes: cls) and: [myFilterB passes: cls with: sel with: code]]! !

!OrMethodFilter methodsFor: 'creation'!

create: filterA {MethodFilter} with: filterB {MethodFilter}

	super create.
	myFilterA _ filterA.
	myFilterB _ filterB! !