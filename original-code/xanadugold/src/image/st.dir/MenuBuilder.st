'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:50 pm'!

Object subclass: #MenuBuilder
	instanceVariableNames: 'myString myContents subTrees '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Menus'!
MenuBuilder comment:
'A MenuBuilder is a builder of HierarchicalMenu''s.  It parses a simple language for building menus.

The language syntax is roughly:

	<menu> ::= menuItem*

	<menuItem> ::= singleItem  |  linedItems

	<singleItem> ::= labelString  |  labelString namedSelector | labelString subMenu

	<labelString> ::= <nondelimiter character>+ delimiter

	<delimiter> ::= :  |  (  |  [  |  )  |  <cr>

	<linedItems> ::= ( menu )

	<namedSelector> ::= [ selectorString ]

	<selectorString> ::= <valid Smalltalk literal Symbol>

	<subMenu> ::=  : menuItem

	See example

Instance Variables:
	myString <nil | String> item that shows in the menu
	myContents <nil | String | Symbol> message selector to be sent if the string myString is selected
	subTrees <OrderedCollection of: MenuBuilders> complete structure of the instance''s menu.'!


!MenuBuilder methodsFor: 'initialize-release'!

initialize
	"Set initial default valules for the reciever's instance variables."

	myString _ nil.
	myContents _ nil.
	subTrees _ OrderedCollection new! !

!MenuBuilder methodsFor: 'testing'!

hasString
	"Answer whether the receiver has a menu item string name."

	^myString notNil!

isLeaf
	"Answer whether the receiver is the last element of the tree structure."

	^subTrees isEmpty! !

!MenuBuilder methodsFor: 'converting'!

asString
	"Answer the menu name string for the receiver."

	^myString! !

!MenuBuilder methodsFor: 'inserting'!

add: subTree
	"Add subTree to the end of the receiver's list of menu structure."

	subTrees add: subTree.! !

!MenuBuilder methodsFor: 'accessing'!

contents
	"Answer with the receiver's message selector or nil."

	^myContents!

contents: item
	"Set the receiver's message selector to be item."

	myContents _ item!

string
	"Answer with the receiver's string representation of the menu item."

	^myString!

string: string
	"Set the argument string to be the receiveer's menu item."

	myString _ string!

treeNamed: string
	"Answer with the receiver's subtree structure whose initial menu item is string."

	| found |
	myString = string ifTrue: [^self].
	subTrees isNil ifTrue: [^nil].
	subTrees do:
		[:item |
		(found _ item treeNamed: string) notNil ifTrue: [^found]].
	^nil! !

!MenuBuilder methodsFor: 'printing'!

printOn: stream
	"Append to the argument aStream a sequence of characters that identifies the receiver."

	super printOn: stream.
	self printOn: stream level: 1!

printOn: aStream level: level 
	"Append at the level of the tree structure denoted by level, in the 
	argument aStream, a sequence of characters that identifies the 
	receiver."

	| delta |
	delta _ 0.
	self hasString ifFalse: [aStream nextPut: $(]
		ifTrue: 
			[aStream crtab: level.
			delta _ 1.
			aStream nextPutAll: myString.
			myContents == nil ifFalse: [aStream nextPut: $[; nextPutAll: myContents; nextPut: $]].
			self isLeaf ifFalse: [aStream nextPut: $:]].
	subTrees do: [:tree | tree printOn: aStream level: level + delta].
	self hasString ifFalse: [aStream nextPut: $)]! !

!MenuBuilder methodsFor: 'menus'!

menu
	"Answer with a HierarchicalMenu whose menu items are the string 
	names of the receiver and whose unary messages to be invoked are 
	the messages of the receiver."

	| menu labels items |
	labels _ self stringList.
	items _ self menuList.
	menu _ HierarchicalMenu labelList: labels.
	menu prefix: 'prefix not used' items: items.
	^menu!

menuList
	"Answer an Array containing all of the message selectors known to the receiver."

	| items |
	items _ WriteStream on: (Array new: 20).
	subTrees do:
		[:tree |
		tree isLeaf
			ifTrue: [items nextPut: tree contents]
			ifFalse: [tree hasString
				ifTrue: [items nextPut: tree menu]
				ifFalse: [items nextPutAll: tree menuList]]].
	^items contents!

stringList
	"Answer an OrderedCollection containing the receiver's menu string names."

	^self addStringListTo: (OrderedCollection with: OrderedCollection new)! !

!MenuBuilder methodsFor: 'private: private'!

addStringListTo: list
	"Add the receiver as a part of the structure list.  list is an OrderedCollection."

	subTrees do:
		[:tree |
		tree hasString
			ifTrue: [list last add: tree string]
			ifFalse: [list last isEmpty ifFalse:
						[list add: OrderedCollection new].
					tree addStringListTo: list]].
	^list! !

!MenuBuilder methodsFor: 'private: private-parsing'!

parseGroupFrom: stream

	[stream skipSeparators.
	stream atEnd or: [stream peekFor: $)]] whileFalse:
		[subTrees add: (self class new parseFrom: stream)]! !

!MenuBuilder methodsFor: 'parsing'!

parseFrom: stream
	"Create the subtree structure from the ReadStream stream.  If the right square bracket is doubled in the specification of the receiver's string, then treat it like a normal character.
	
	MSM: Treat a '$' in the stream as an escape in the label section
	resulting in the next character being taken literally"

	| delimiters  next newStream  |
	delimiters _ ':([)\' withCRs.
	stream skipSeparators.
	(stream peekFor: $( )
	  ifTrue:	"unlabeled subTree, group separated by lines"
		[self parseGroupFrom: stream]
	  ifFalse:	"labeled me or labeled subMenu"
		[newStream _ WriteStream on: (String new: 64).
		[next _ stream next.
		next = $$ 
			ifTrue: [next _ stream next.
				     next isNil ifTrue: [self error: 'stream terminated after $'].
				     newStream nextPut: next.
				     next _ stream next].
		next isNil or: [delimiters includes: next]] 
			whileFalse: [newStream nextPut: next].
		next isNil ifFalse: [stream skip: -1].
		myString _ newStream contents.	"myString _ my label"
		(stream peekFor: $[ )
			ifTrue: [myContents _ (stream upTo: $])]	"selector specified"
			ifFalse: [myContents _ myString].	"no selector specified, use label"		
		stream skipSeparators.
		(stream peekFor: $:)
			ifFalse: 	"just creating me; test to be sure selector is ok"
				[(Scanner isLiteralSymbol: myContents)
					ifTrue: [myContents _ myContents asSymbol]
					ifFalse: ["self error: '[', myContents, 
									'] is an illegal message selector'"
							"MSM - the above is commented out so that
							I can have strings with spaces be returned by
							selection in hierarchical menus"]]
			ifTrue:		"creating labeled subtree"
				[stream skipSeparators.
				(stream peekFor: $( )
					ifTrue: [self parseGroupFrom: stream]
					ifFalse: [self add: (self class new parseFrom: stream)]]].
	^self! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MenuBuilder class
	instanceVariableNames: ''!


!MenuBuilder class methodsFor: 'instance creation'!

new
	^super new initialize!

parseFrom: stream
	"Create a new instance of the receive, obtaining informating from the argument stream about the contents of the menu to be built.  The argument should be a ReadStream on a string containing a sequence of items that are either of the form:
	menu-item-name [unary-message-selector]
or
	menu-tem-name: ( sequence of items ).

For example,

	MenuBuilder parseFrom: (ReadStream on:
'restore display[restoreDisplay]
open window:
	(project[openProject]
	browser[openBrowser]
	clock:
		(ascii[openAClock]
		graphical [openGClock]))
exit project[exitProject]') 

See HierarchicalMenu menuSampler for an example to try.
"

	^self new parseGroupFrom: stream! !

!MenuBuilder class methodsFor: 'examples'!

example
	"MenuBuilder example"

	^(PopUpMenu fromString:
		'restore display[restoreDisplay]
		open window:
			(project[openProject]
			(browser[openBrowser]
			workspace
			system workspace[openSystemWorkspace]
			transcript[openTranscript]
			file list[openFileList])
			(document editor[openWYSIWYGView]
			clock:
				(ascii[openAClock]
				graphical [openGClock])))
		(save/quit:
			(save[save]
			save then quit[saveThenQuit]
			quit: confirm[quit])
		exit project[exitProject])') startUp! !