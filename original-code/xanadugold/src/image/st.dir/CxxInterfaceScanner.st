'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:24 pm'!

CxxTypeScanner subclass: #CxxInterfaceScanner
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Cxx-Translators'!



!CxxInterfaceScanner methodsFor: 'translating'!

{void} beginSelector: cxc {CxxClassDescription}	
	with: cls {Behavior}
	sel: sel {Symbol}
	source: source {String}

	| parser {Parser} head {String} |
	super beginSelector: cxc with: cls sel: sel source: source.
	parser _ cls parserClass new.
	parser
		initPattern: source
		notifying: nil
		saveComments: false
		return: [:pattern {Array 
							of: Symbol 
							with: (Array of: ParameterNode)
							with: ValueNode} |
					((pattern at: 1) == sel) assert].
	head _ source copyFrom: 1 to: (parser endOfLastToken min: source size).
	self computeReferences: head! !