'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:30 pm'!

FMComposer subclass: #XViewFMComposer
	instanceVariableNames: '
		myAlphabet {FMAlphabet}
		myFont {FontObj}
		myAscent {IntegerVar}
		myDescent {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-XXView'!

(XViewFMComposer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewFMComposer methodsFor: 'creation'!

create: attributes {AttributeGroup}

	super create: attributes.
	myAlphabet _ attributes alphabet.
	myFont _ attributes font cast: FontObj.
	"myScanner _ XScanner create."
	myAscent _ myFont ascent.
	myDescent _ myFont descent! !

!XViewFMComposer methodsFor: 'composing'!

{IntegerVar} charIndexFor: pos {PointPos} with: model {MuWordArray} with: comp {FMComposition}
 
	| x {IntegerVar} runStop {IntegerVar} runLimit {IntegerVar} 
	 charWidth {IntegerVar} curChar {Sequence} runStart {IntegerVar}
	  widthLocal {IntegerVar} chars {MuWordArray}   
	  |
	x _ pos x.
	x > comp displayWidth ifTrue: [^-1].
	chars _ model.
	runStop _ runStart _ IntegerVar0.
	runLimit _ runStart + model count.
	widthLocal _ IntegerVar0.
	 
	[runStop < runLimit]
		whileTrue: 
			[curChar _ (chars intFetch: runStop) quickCast: Sequence.
			runStop _ runStop + 1.
			 
			 charWidth _ myFont widthOf: curChar.
			widthLocal _ widthLocal + charWidth.
			widthLocal > x ifTrue: [^runStop]].
	^ runStop - runStart!

{FMComposition} compose: model {MuWordArray} with: layout {AbstractLayout} 
	| runStop {IntegerVar} compLimit {IntegerVar} curChar {PrimIntValue} curCount {IntegerVar} curWidth {IntegerVar} lastScanIndex {IntegerVar} lastScanX {IntegerVar} exitFlag {BooleanVar} savedScanX {IntegerVar} font {FMFont} heightLocal {IntegerVar} runLimit{IntegerVar} |
	
	lastScanX _ IntegerVar0.
	lastScanIndex _ IntegerVar0.
	runLimit _ model count.
	compLimit _ layout extent x.
	font _ self attributes font.
	heightLocal _ font ascent + font descent.
	exitFlag _ false.
	[exitFlag]
		whileFalse: [lastScanIndex < runLimit ifFalse: [runStop _ lastScanIndex.
				exitFlag _ true]
				ifTrue: 
					[curChar _ (model intFetch: lastScanIndex)
								cast: PrimIntValue.
					savedScanX _ lastScanX.
					lastScanX _ lastScanX + (font widthOf: curChar).
					lastScanX <= compLimit
						ifFalse: 
							[lastScanX _ savedScanX.
							runStop _ lastScanIndex-1 .
							exitFlag _ true]].
			lastScanIndex _ lastScanIndex + 1].
	"runstop &  lastScanX should be devined vy here"
	curCount _ runStop.
	curWidth _ lastScanX.
	runStop < (runLimit)
		ifTrue: 
			[| composeStop {IntegerVar} |
			curChar _ (model intFetch: runStop - 1)
						cast: PrimIntValue.
			(myAlphabet isLinebreak: curChar)
				ifTrue: [^FMComposition
						make: curWidth
						with: compLimit
						with: (layout extent y)
						with: curCount
						with: #endOfLine].
			(myAlphabet isTab: curChar)
				ifTrue: [curWidth _ layout region width. self hack. "needs to be fixed later, as there are no tab layouts yet (anymore)"
					^FMComposition
						make: curWidth
						with: compLimit
						with: heightLocal
						with: curCount
						with: #endOfRun"self displayHeight"].
			"Try to eat separators. If successful, the run didn't overflow."
			composeStop _ runStop.
			[runStop < runLimit and: [myAlphabet isSeparator: (curChar _ (model intFetch: runStop)
								cast: PrimIntValue)]]
				whileTrue: 
					[runStop _ runStop + 1.
					curCount _ curCount + 1.
					(myAlphabet isLinebreak: curChar)
						ifTrue: [^FMComposition
								make: curWidth
								with: compLimit
								with: heightLocal
								with: curCount
								with: #endOfLine"self displayHeight"]].
			(runStop == composeStop or: [runStop < runLimit])
				ifTrue: [^FMComposition
						make: curWidth
						with: compLimit
						with: heightLocal
						with: curCount
						with: #lineOverflow"self displayHeight"]
				ifFalse: [^FMComposition
						make: curWidth
						with: compLimit
						with: heightLocal
						with: curCount
						with: #endOfRun"self displayHeight"]]
		ifFalse: [^FMComposition
				make: curWidth
				with: compLimit
				with: heightLocal
				with: curCount
				with: #endOfRun"self displayHeight"]!

{FMComposition} uncompose: model {MuWordArray} with: composition {FMComposition} 
	"The bug in this is that it subtracts the width of spaces that 
	didn't actually add to the width of the run (at the end of a 
	line)."

	| runStop {IntegerVar} newWidth {IntegerVar} runStart {IntegerVar} curChar {PrimIntValue} modelPos {IntegerVar}  loop {BooleanVar} |
	modelPos _ composition count.
	runStart _ IntegerVar0.
	runStop _ modelPos.
	newWidth _ composition displayWidth.
	loop _ false.
	[loop ] whileFalse: [ 
	runStop == runStart ifTrue: [^FMComposition
			make: composition displayWidth
			with: composition layoutWidth
			with: composition displayHeight
			with: composition count
			with: #lineOverflow].
	runStop _ runStop - 1.
	curChar _ (model intFetch: runStop) cast: PrimIntValue.
	(loop _ myAlphabet isSeparator: curChar) ifFalse: [newWidth _ newWidth - (myFont widthOf: curChar)].
	"Font takes Character"
	 ] .
	"Alphabet takes PrimInteger"
	runStop _ runStop + 1.
	^FMComposition
		make: newWidth
		with: composition layoutWidth
		with: composition displayHeight
		with: runStop - runStart
		with: #endOfRun! !

!XViewFMComposer methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name << '('
	
	<< 'myAlphabet = '  << myAlphabet  
	<< 	'myFont = '  << 	myFont  
	<< 	'myAscent = '  << 	myAscent  
	<< 	'myDescent = ' << 	myDescent << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XViewFMComposer class
	instanceVariableNames: ''!

(XViewFMComposer getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!XViewFMComposer class methodsFor: 'global: pseudo constructors'!

{FMComposer}fMComposer: attributes {AttributeGroup}
	 
	^ XViewFMComposer  create: attributes! !