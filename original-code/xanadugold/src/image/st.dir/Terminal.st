'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:18 pm'!

TextCollector subclass: #Terminal
	instanceVariableNames: 'displayProcess externalProcess dataStream localEcho characterLimit '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Terminal'!
Terminal comment:
'Class Terminal represents a collector of text that comes from an external resource, such as an external process or serial port.

Instance Variables:
	displayProcess		<Process>		Our background process
	externalProcess		<ExternalProcess | nil> The ExternalProcess currently being used--nil if on a serial port
	dataStream		<ExternalReadAppendStream> The data stream used to communicate with the external resource
	localEcho			<Boolean>		Perform local exho 
	characterLimit 		<SmallInteger>	Number of character to hold '!


!Terminal methodsFor: 'initialize-release'!

initialize
	"Initialize the receiver."

	super initialize.
	localEcho _ true.
	characterLimit _ 30000!

release
	"Release the receiver."

	displayProcess == nil
		ifFalse: [displayProcess terminate.
				displayProcess _ nil].
	self cleanUp.
	super release! !

!Terminal methodsFor: 'accessing'!

characterLimit
	"Answer the number of characters that the receiver will hold."

	^characterLimit!

reset
	"Reset the terminal's state to some sane value"

	displayProcess == nil
		ifFalse: [displayProcess terminate].
	self startReceiveProcess! !

!Terminal methodsFor: 'character writing'!

backspace
	"Remove the last character from the text."

	entryStream isEmpty
		ifTrue: [contents size = 0
					ifFalse: [contents _ contents copyFrom: 1 to: contents size-1.
							self changed: #backspace]]
		ifFalse: [entryStream skip: -1]! !

!Terminal methodsFor: 'updating'!

update: parameter
	"Process a dependency message."

	parameter == #returnFromSnapshot
		ifTrue: [displayProcess == nil
					ifFalse: [displayProcess terminate].
				dataStream == nil
					ifFalse: [dataStream _ nil.
							externalProcess _ nil]]! !

!Terminal methodsFor: 'private: private'!

cleanUp

	Smalltalk removeDependent: self.
	(dataStream notNil)
		ifTrue: [dataStream close.
				dataStream _ nil].
	externalProcess == nil
		ifFalse: [externalProcess release.
				externalProcess _ nil].!

externalProcess: anExternalProcess

	externalProcess _ anExternalProcess!

ignoreLF: aFlag
	"Set cr to lf swap flag."

	aFlag
		ifTrue:	[dataStream lineEndConvention: dataStream ioConnection lineEndConvention]
		ifFalse:	[dataStream lineEndTransparent]!

localEcho: aFlag
	"Set local echo flag."

	localEcho _ aFlag.!

processActive

	^externalProcess isNil
		ifTrue: [true]
		ifFalse: [externalProcess isActive]!

processBuffer: buffer amount: count 
	"Display characters in buffer."

	| aChar bs lf |
	bs _ Character backspace.
	lf _ Character lf.
	1 to: count do: 
		[:i | 
		aChar _ Character value: ((buffer at: i) asciiValue
bitAnd: 127).
		aChar == lf
			ifFalse: [aChar == bs
				ifTrue: [self backspace]
				ifFalse: [self nextPut: aChar]]].
	self endEntry!

sendAll: aString 
	"Send out some of the user's input, echoed locally if required. 
	Catches backspaces and swaps Cr and Lf."

	| bs |
	(dataStream notNil and: [dataStream ioConnection isActive and: [self processActive
						and: [aString size > 0]]])
		ifTrue: 
			[localEcho
				ifTrue: 
					[bs _ Character backspace.
					aString do: [:c | c == bs
							ifTrue: [self backspace]
							ifFalse: [self nextPut: c]].
					self endEntry].
			dataStream nextPutAll: aString.
			dataStream flush.
			^true]
		ifFalse: [^false]!

setDataStream: anExternalStream
	"Set the receiver to process anExternalStream.  Connect dependency to Smalltalk."

	dataStream _ anExternalStream.
	Smalltalk addDependent: self.!

startReceiveProcess
	"Start the display process."

	| buffer  |
	displayProcess _ [dataStream notNil
				ifTrue: 
					[[dataStream ~~ nil and: [self processActive]]
						whileTrue: 
							[OSErrorHolder transferFaultSignal
										handle: [:ex |
												buffer _ ''.
												ex return]
										do: [buffer _ dataStream nextHunk].
							self processBuffer: buffer amount: buffer size.
							Processor yield].
					self cr; endEntry].
					self cleanUp] newProcess.
	displayProcess priority: Processor userSchedulingPriority.
	displayProcess resume! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Terminal class
	instanceVariableNames: ''!


!Terminal class methodsFor: 'instance creation'!

openCsh
	"Answer an instance of the receiver connected to a c shell."
	"Terminal openCsh"

	TerminalView
		openOn: self getCshTerminal
		label: 'csh'!

openCshIn: aView
	"Open a c shell in aView."

	self
		openViewOn: self getCshTerminal
		label: 'csh'
		inView: aView!

openTty
	"Answer an instance of the receiver connected to a serial port."
	"Terminal openTty"
	^self openTty: IOAccessor defaultForSerial defaultPortName!

openTty: aString
	"Answer an instance of the receiver connected to a serial port."
	"Terminal openTty: '/dev/ttya'"

	TerminalView
		openOn: (self getTtyTerminal: aString)
		label: 'Terminal ', aString! !

!Terminal class methodsFor: 'private: private'!

getCshTerminal
	"Answer a csh terminal."
	
	| fdPair ptyMaster ptySlave processDescriptor externalConnection aTerminal |
	fdPair _ UnixPseudoTtyAccessor openPair.
	ptyMaster _ fdPair at: 1.
	ptySlave _ fdPair at: 2.
	[ptySlave setForCsh.
	processDescriptor _ UnixProcess
			forkJob: 'csh'
			arguments: nil
			descriptors: (Array
					with: ptySlave
					with: ptySlave
					with: ptySlave)]
		valueOnUnwindDo: [ptyMaster close. ptySlave close].
	ptySlave close.
	externalConnection _ ExternalConnection new.
	externalConnection input: ptyMaster.
	externalConnection output: ptyMaster.
	aTerminal _ self new.
	aTerminal externalProcess: processDescriptor.
	aTerminal setDataStream: externalConnection readAppendStream.
	aTerminal localEcho: false.
	aTerminal ignoreLF: false.
	^aTerminal!

getTtyTerminal: aString
	"Answer a terminal setup for tty."

	| aTerminal  connection |
	aTerminal _ self new.
	connection _ ExternalConnection ioAccessor: (IOAccessor defaultForSerial open: aString).
	connection input setForTty.
	aTerminal setDataStream: connection readAppendStream.
	aTerminal localEcho: false.
	aTerminal ignoreLF: false.
	^aTerminal!

openViewOn: aTerminal label: aString inView: aView
	"Creates a StandardSystemView with a TextCollectorView as a subview,
 	both having aTerminal as their model. "

	| topView  style|
	topView _ StandardSystemView new.
	topView borderWidth: 1.
	topView model: aTerminal.
	topView label: aString.
	topView minimumSize: 160@120.
	aView model: aTerminal.
	topView addSubView: aView in: (0@0 extent: 1@1) borderWidth: 1.
	style _ TextStyle styleNamed: #fixed ifAbsent: [nil].
	style == nil ifTrue: [style _ TextStyle default].
	aView displayContents textStyle: style.
	topView controller openNoTerminate.
	topView icon: (Icon constantNamed: #default).
	aTerminal startReceiveProcess.
	Cursor normal show.! !