'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:22 pm'!

Object subclass: #StaticFunctionPointer
	instanceVariableNames: '
		myClass {Class}
		mySelector {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xpp-Basic'!
StaticFunctionPointer comment:
'An object that represents in Smalltalk the equivalent of a pointer to a class static function in C++. When it gets the invokeFunction:with:... message, it sends mySelector to the class, with the arguments of the invokeFunction message. This does the same thing that the translated code would do if this were in fact a function pointer.'!



!StaticFunctionPointer methodsFor: 'create'!

create: class {Class} with: selector {Selector}
	myClass := class.
	mySelector := selector.! !

!StaticFunctionPointer methodsFor: 'invoking'!

invokeFunction

	^myClass perform: mySelector!

invokeFunction: arg1

	^myClass perform: mySelector
		with: arg1!

invokeFunction: arg1 with: arg2

	^myClass perform: mySelector
		with: arg1
		with: arg2!

invokeFunction: arg1 with: arg2 with: arg3

	^myClass perform: mySelector
		with: arg1
		with: arg2
		with: arg3!

invokeFunction: arg1 with: arg2 with: arg3 with: arg4

	^myClass perform: mySelector
		with: arg1
		with: arg2
		with: arg3
		with: arg4!

invokeFunction: arg1 with: arg2 with: arg3 with: arg4 with: arg5

	| args |
	args := Array new: 5.
	args basicAt: 1 put: arg1.
	args basicAt: 2 put: arg2.
	args basicAt: 3 put: arg3.
	args basicAt: 4 put: arg4.
	args basicAt: 5 put: arg5.
	^myClass perform: mySelector
		withArguments: args!

invokeFunction: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6

	| args |
	args := Array new: 6.
	args basicAt: 1 put: arg1.
	args basicAt: 2 put: arg2.
	args basicAt: 3 put: arg3.
	args basicAt: 4 put: arg4.
	args basicAt: 5 put: arg5.
	args basicAt: 6 put: arg6.
	^myClass perform: mySelector
		withArguments: args! !

!StaticFunctionPointer methodsFor: 'printing'!

printOn: oo
	oo << myClass name << '::' << mySelector! !

!StaticFunctionPointer methodsFor: 'accessing'!

selector
	^mySelector!

staticClass
	^myClass! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StaticFunctionPointer class
	instanceVariableNames: ''!



!StaticFunctionPointer class methodsFor: 'creation'!

make: class {Class} with: selector {Symbol}
	"You should only call this from Smalltalk code. For translatable code, use
		SomeClass pointerToStaticMember: #selector:with:"
	^self create: class with: selector! !