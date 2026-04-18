'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:05 pm'!

Printer subclass: #PostScriptPrinter
	instanceVariableNames: '
		currentFontStyle {UNKNOWN}
		currentFont {UNKNOWN}
		currentSize {UNKNOWN}
		currentCharWidths {UNKNOWN}
		leftArrowWidth {UNKNOWN}
		leftArrowOffsetY {UNKNOWN}
		upArrowWidth {UNKNOWN}
		currentTabWidths {UNKNOWN}
		currentLineWidth {UNKNOWN}
		currentWords {UNKNOWN}
		chunks {UNKNOWN}
		underlining {UNKNOWN}
		pageHeight {UNKNOWN}
		pageWidth {UNKNOWN}
		leftMargin {UNKNOWN}
		rightMargin {UNKNOWN}
		topMargin {UNKNOWN}
		bottomMargin {UNKNOWN}
		currentY {UNKNOWN}
		leading {UNKNOWN}
		file {UNKNOWN}
		orientation {UNKNOWN}
		currentPageNumber {UNKNOWN}
		currentColumn {UNKNOWN}'
	classVariableNames: '
		Adjustment {UNKNOWN} 
		BreakScanner {UNKNOWN} 
		BreakScannerStops {UNKNOWN} 
		CharWidthTable {UNKNOWN} 
		KPointsPerInch {UNKNOWN} 
		TempFileName {UNKNOWN} '
	poolDictionaries: ''
	category: 'System-Printing'!
{String} pattern

	| result {String} |
	result _ myFilter pattern.
	(result == nil or: [result == NULL])
		ifTrue: [result _ myGen pattern].
	^result!



!PostScriptPrinter methodsFor: 'indexing'!

printIndex
	| index permutedIndex currentKey inClasses |
	"Don't bother for short printouts"
	(true or: (labelIndex size > 10 and: [currentPageNumber > 5])) ifTrue: [
		permutedIndex _ OrderedCollection new: 2 * labelIndex size.
		labelIndex do: [:item |
			((item key isKindOf: Association) and: [item key key ~= '']) ifTrue:
				[permutedIndex add: item.
				 item key value ~~ nil ifTrue:
					[permutedIndex add: (Association key: (Association key: item key value value: item key key) value: item value)]]].
		permutedIndex size = 0 ifTrue: [^self].
		self newPage.
		index _ permutedIndex asSortedCollection.
		index sortBlock: [:i :j | | tmp |
			tmp _ i key key trueCompare: j key key.
			tmp == 0
				ifTrue: [(i key value == nil and: [j key value ~~ nil])
							ifTrue: [true]
							ifFalse: [(i key value ~~ nil and: [j key value ~~ nil])
										ifTrue: [(i key value trueCompare: j key value) == -1]
										ifFalse: [false]]]
				ifFalse: [tmp == -1]].
		index _ index partialOrder.
		currentKey _ nil.
		self twoColumn.
		self string: 'By class:'; newLine; newLine.
		inClasses _ true.
		index do: [:item |
			(inClasses and: [item key key ~= currentKey and: [item key value ~~ nil and: [inClasses]]]) ifTrue:
				[inClasses _ false.
				self newLine; string: 'By method:'; newLine; newLine].
			item key value == nil
				ifTrue: [self string: (item value printString, '	', item key key asString)]
				ifFalse: [item key key ~= currentKey
							ifTrue: [self string: ('	', item key key asString); newLine].
						self string: (item value printString, '		', item key value asString)].
			self newLine.
			currentKey _ item key key]].
		self oneColumn.! !

!PostScriptPrinter methodsFor: 'initialize-release'!

close
	"Do any needed shutdowns."

	document _ nil!

drive
	"Take the list of 'entities' and transform them into a stream of  
	Postscript code."

	document render: [:entity | self perform: entity key with: entity value]!

initialize
	"Set up to begin to render to a Postscript file."

	currentLineWidth _ 0.
	currentWords _ WriteStream on: (String new: 255).
	topMargin _ bottomMargin _ leftMargin _ rightMargin _ 0.
	leading _ 16 * Adjustment.
	chunks _ OrderedCollection new: 10.
	underlining _ false.
	orientation _ #portrait.
	currentPageNumber _ 1.
	twoColumn _ false.
	labelIndex _ OrderedCollection new: 255.
	self setPrinterResolutionToApple!

printer: aString print: aDocument onFileNamed: fileName
	"Send the named document to the named printer."
	document _ aDocument.
	file _ fileName asFilename writeStream.
	self drive.!

setPrinterResolutionToApple
	"Set an instance variable which specifies the resolution in pixels per 
	point of the output printer for imaging tasks which need to know
	this to that of the Apple LaserWriter."

	self setPrinterResolution: 300 / 72! !

!PostScriptPrinter methodsFor: 'rendering'!

doFooter: values 
	"Set the page footer."

	| str |
	str _ WriteStream on: (String new: 255).
	(values at: 1)
		= false
		ifTrue: [chunks add: (Array with: #misc with: '/doFooter false def
')]
		ifFalse: 
			[chunks add: (Array with: #misc with: '/doFooter true def
').
			str nextPutAll: '/footerString ('.
			str nextPutAll: (values at: 2).
			str nextPutAll: ') def'; cr.
			chunks add: (Array with: #misc with: str contents).
			(values at: 3)
				= true
				ifTrue: [chunks add: (Array with: #misc with: '/doPageNumbers true def
')]
				ifFalse: [chunks add: (Array with: #misc with: '/doPageNumbers false def
')]]!

end: aNil 
	"Put out a termination for the PostScript document,  doing any      
	needed cleanup."
	self outputChunks.
	self printIndex.
	file nextPutAll: '
finalPage
state restore
'.
	file close.
	Cursor wait showWhile: [self class sendToPrinter].
"		file nextPutAll: '
finalPage
end
state restore
'.
"!

fontStyle: aFontStyle 
	"Set various style entities from a passed style packet."

	| newSize newFace newFont |
	self flushBuffer.
	newSize _ aFontStyle currentSize.
	newFace _ aFontStyle currentFace.
	newFont _ self
				mapFamily: aFontStyle currentFamily
				size: newSize
				face: newFace.
	(currentFont == nil or: [currentFont fullName ~= (newFont at: 1) or: [newSize ~= currentSize]])
		ifTrue: [self changeFont: newFont].
	currentFontStyle _ aFontStyle.!

image: aForm 
	"Print the form,  in a device independent way,  as closely to the 
	screen size as possible."

	| newWidth newY |
	self outputChunks.
	self deltaY: leading.
	newY _ currentY - (aForm height * Adjustment).
	newY < bottomMargin
		ifTrue: 
			[self newPage.
			newY _ currentY - (aForm height * Adjustment)].
	newWidth _ aForm width + 15 truncateTo: 16.
	file nextPutAll: ' /pix '.
	newWidth / 8 printOn: file.
	file nextPutAll: ' string def'; cr.
	self gsave.
	self translate: leftMargin @ newY.
	self gsave.
	self clipBox: aForm height width: aForm width.
	self scale: newWidth @ aForm height.
	self
		imageWidth: newWidth
		height: aForm height
		bits: aForm bits.
	self grestore.
	self box: aForm height width: aForm width.
	self grestore.
	self moveto: leftMargin @ (currentY _ newY)!

imageOneToN: aFormandScale 
	"Print the form,  scaled one pixel in the form to n pixels on the printer."

	| newWidth newY aForm scale |
	aForm _ aFormandScale at: 1.
	scale _ aFormandScale at: 2.
	self outputChunks.
	self deltaY: leading.
	newY _ currentY - (aForm height / PrinterResolution * scale * Adjustment).
	newY < bottomMargin
		ifTrue: 
			[self newPage.
			newY _ currentY - (aForm height / PrinterResolution * scale * Adjustment)].
	newWidth _ aForm width + 15 truncateTo: 16.
	file nextPutAll: ' /pix '.
	newWidth / 8 printOn: file.
	file nextPutAll: ' string def'; cr.
	self gsave.
	self translate: leftMargin @ newY.
	self gsave.
	self clipBox: (aForm height / PrinterResolution * scale) asFloat width: (aForm width / PrinterResolution * scale) asFloat.
	self scale: (newWidth / PrinterResolution * scale) asFloat @ (aForm height / PrinterResolution * scale) asFloat.
	self
		imageWidth: newWidth
		height: aForm height
		bits: aForm bits.
	self grestore.
	self box: (aForm height / PrinterResolution * scale) asFloat width: (aForm width / PrinterResolution * scale) asFloat.
	self grestore.
	self moveto: leftMargin @ (currentY _ newY)!

label: aLabel
	aLabel ~= nil ifTrue:
		[labelIndex add: (Association key: aLabel value: currentPageNumber)]!

landscape: Nil 
	"Rotate the page 90 degrees."

	orientation _ #landscape.
	chunks add: (Array with: #misc with: '/orientation landscape def
').
	chunks add: (Array with: #misc with: 'setOrientation
').
	"self rotate: -90. 
	self translate: 0 - pageWidth @ 0"!

mapFamily: family size: size face: face
	"Map a Strike font family onto a PostScript face, and set the type size."

	| newFamily newFace |
	newFace _ face.
	family == #Serif
		ifTrue: 
			[newFamily _ #Times.
			"face == #Default ifTrue: [newFace _ #Roman]]"
			face == #Default ifTrue: [newFace _ '']]
		ifFalse: [family == #SanSerif
				ifTrue: 
					[newFamily _ #Helvetica.
					face == #Default ifTrue: [newFace _ '']]
				ifFalse: [family == #FixedPitch
						ifTrue: 
							[newFamily _ #Courier.
							face == #Default ifTrue: [newFace _ '']]]].
	^Array with: (newFamily , newFace) asSymbol with: size!

margins: anArray 
	"Set margins from a passed array of displacements from the page    
	edges."

	| str |
	str _ WriteStream on: (String new: 255).
	topMargin _ pageHeight - ((anArray at: 1)
					* KPointsPerInch).
	bottomMargin _ (anArray at: 2)
				* KPointsPerInch.
	leftMargin _ (anArray at: 3)
				* KPointsPerInch.
	rightMargin _ pageWidth - ((anArray at: 4)
					* KPointsPerInch).
	str nextPutAll: '/leftMargin '.
	(anArray at: 3)
		* 72 printOn: str.
	str nextPutAll: ' def'; cr.
	str nextPutAll: '/topMargin '.
	(anArray at: 1)
		* 72 printOn: str.
	str nextPutAll: ' def'; cr.
	str nextPutAll: '/rightMargin '.
	(anArray at: 4)
		* 72 printOn: str.
	str nextPutAll: ' def'; cr.
	str nextPutAll: '/bottomMargin '.
	(anArray at: 2)
		* 72 printOn: str.
	str nextPutAll: ' def'; cr.
	chunks add: (Array with: #misc with: str contents)!

newPage
	"Print the current page,  and get ready to print another."
	| isNew |
	isNew _ false.
	twoColumn
	ifTrue:
		[currentColumn = 1
		ifTrue:
			[currentColumn _ 2.
			leftMargin _ 324.
			self margins: #(1 1 4.5 1)]
		ifFalse:
			[currentColumn _ 1.
			leftMargin _ 72.
			self margins: #(1 1 1 4).
			isNew _ true.
			file nextPutAll: '/leftMargin 72 def'; cr]]
	ifFalse:
		[isNew _ true].
	isNew ifTrue:
		[self showPage.
		currentPageNumber _ currentPageNumber + 1].
	currentY _ topMargin.
	self moveto: leftMargin @ currentY.!

newPage: Nil 
	"Print the current page,  and get ready to print another."

	self newPage.!

oneColumn
	twoColumn ifFalse: [^ self].
	twoColumn _ false.
	self margins: #(1 1 1 1).!

pageHeight: inches 
	"Set the height of the printed page."

	| str |
	pageHeight _ inches * KPointsPerInch.
	str _ WriteStream on: (String new: 255).
	str nextPutAll: '/pageHeight '.
	inches * 72 printOn: str.
	str nextPutAll: ' def'; cr.
	chunks add: (Array with: #misc with: str contents)!

pageWidth: inches 
	"Set the width of the printed page."

	| str |
	pageWidth _ inches * KPointsPerInch.
	str _ WriteStream on: (String new: 255).
	str nextPutAll: '/pageWidth '.
	inches * 72 printOn: str.
	str nextPutAll: ' def'; cr.
	chunks add: (Array with: #misc with: str contents)!

start: aNil 
	"Put a preample for the Postscript document,  defining a dictionary  
	and any needed support."
	
	file nextPutAll: '%!!

% start of setup.
save /state exch def
initgraphics
/PPS 255 dict def PPS begin
/leftMargin 72 def
/yDelta 16 def
/portrait 0 def
/landscape 1 def
/orientation portrait def
/doFooter false def
/doPageNumbers true def
/doLogo false def
/F  %  Fast font setup.
{
  findfont exch scalefont setfont
} bind def
/ArrowDim % Pop the dimensions of the arrows off the stack.
{
/upArrowThickness exch def
/upArrowHeight exch def
/upArrowWidth exch def
/leftArrowThickness exch def
/leftArrowheadHeight exch def
/leftArrowWidth exch def
} bind def
/upArrow %  Draw an up arrow.
{ 
	gsave
	0 setlinecap
	0 setlinejoin
	/upArrowY exch def
	/upArrowX exch def
	upArrowThickness setlinewidth
	/upArrowX upArrowX upArrowWidth 2 div add def
	/upArrowSpace upArrowWidth 10 div def
	/upArrowRenderWidth upArrowWidth upArrowSpace upArrowSpace add sub 3 div def
	newpath
	upArrowX upArrowY moveto
	0 upArrowHeight rlineto 
	stroke
	newpath
	upArrowX upArrowRenderWidth sub upArrowY upArrowHeight add upArrowHeight 3 div sub moveto
	upArrowX upArrowY upArrowHeight add lineto
	upArrowX upArrowRenderWidth add upArrowY upArrowHeight add upArrowHeight 3 div sub lineto
	stroke
	grestore
} bind def
/leftArrow  %  Draw a left arrow.
{ 
	gsave
	0 setlinecap
	0 setlinejoin
	/leftArrowY exch def
	/leftArrowX exch def
	leftArrowThickness setlinewidth
	/leftArrowSpace leftArrowWidth 10 div def
	/leftArrowX leftArrowX leftArrowSpace add def
	/leftArrowRenderWidth leftArrowWidth leftArrowSpace leftArrowSpace add sub def
	/leftArrowheadWidth leftArrowRenderWidth 3 div def
	newpath
	leftArrowX leftArrowY moveto
	leftArrowRenderWidth 0 rlineto 
	stroke
	newpath
	leftArrowX leftArrowheadWidth add leftArrowY leftArrowheadHeight 2 div add moveto
	leftArrowX leftArrowY lineto
	leftArrowX leftArrowheadWidth add leftArrowY leftArrowheadHeight 2 div sub lineto
	stroke
	grestore
} bind def
/CR			%stack: -- --> --
{	
 currentpoint exch pop leftMargin exch yDelta sub moveto 
} bind def
/Ustart		%stack: -- --> --
{
	/ULstart currentpoint pop def
} bind def
/UStop		% stack: underlineThickness underlineYDelta --> --
{
	currentpoint
	/ULY exch def
	/ULX exch def
	gsave newpath
	ULY add ULstart exch moveto
	ULX ULstart sub 0 rlineto
	setlinewidth stroke grestore
} bind def
/pageNum 1 def
/pageString 4 string def
/pageNumFont 
{
  /Times-Roman findfont 10 scalefont
} bind def
/footerStringFont 
{
  /Times-Italic findfont 10 scalefont
} def

/footerString () def
/footer
{
   leftMargin bottomMargin 2 div moveto
  doPageNumbers true eq 
  {
    pageNumFont setfont
    pageNum pageString cvs show
    (  ) show
  } if
  footerStringFont setfont
  footerString show
} bind def
/newPage 
{  
  /savefont currentfont def
  doFooter true eq { footer } if
   showpage
  /pageNum 1 pageNum add def
  setOrientation
  savefont setfont
} bind def
',
	self finalPageDef,
'/setOrientation
{
  orientation landscape eq 
  {
    -90 rotate
    0 pageWidth sub 0 translate
  } if
} bind def

% end of setup.
'!

startParagraph: arg 
	"Start a new paragraph."

	self  outputChunks.
	self deltaY: leading.
	self moveto: leftMargin @ currentY!

string: aString 
	"Output this string in the current font.  Break into lines   
	based on character width info."

	self breakIntoLines: aString!

tabs: anArray 
	"Set tab stops from a passed array of x positions."

	| i len |
	currentTabWidths _ Array new: anArray size.
	i _ 0.
	len _ anArray size.
	[(i _ i + 1) <= len]
		whileTrue: [currentTabWidths at: i put: (anArray at: i)
					* KPointsPerInch]!

twoColumn
	twoColumn ifTrue: [^ self].
	twoColumn _ true.
	self margins: #(1 1 1 4).
	currentColumn _ 1.!

underline: boolean 
	"Set the state of underlining."

	underlining
		ifTrue: [self stopUnderlining]
		ifFalse: [self startUnderlining]! !

!PostScriptPrinter methodsFor: 'private:'!

advanceToNextTabstop: n 
	"Advance the current x position to the n'th next tab stop."

	| tabX count |
	count _ n.
	1 to: currentTabWidths size do: [:i | (tabX _ currentTabWidths at: i) > currentLineWidth
			ifTrue: 
				[currentLineWidth _ tabX.
				count _ count - 1.
				count > 0
					ifFalse: 
						[self moveto: currentLineWidth + leftMargin @ currentY.
						^nil]]]!

box: height width: width 
	"Draws a box at the current origin.  Assumes gsave and grestore are  
	done externally."

	file nextPutAll: 'newpath 0 0 moveto 0 '.
	height asFloat printOn: file.
	file nextPutAll: ' rlineto '.
	width asFloat printOn: file.
	file nextPutAll: ' 0 rlineto 0 '.
	height negated asFloat printOn: file.
	file nextPutAll: ' rlineto closepath 1 72 div setlinewidth stroke'; cr!

breakIntoLines: aString 
	"Return the word , the width and the breakChar."

	| newWord width i  index length spaceWidth loc result n tab sSize space rmargin |
	rmargin _ rightMargin - leftMargin.
	tab _ Character tab.
	space _ Character space.
	spaceWidth _ (currentCharWidths at: 33) asFloat.
	loc _ 1.
	sSize _ aString size.
	[true]
		whileTrue: 
			[result _ BreakScanner
						scanCharactersFrom: loc
						to: sSize
						in: aString
						rightX: 1
						stopConditions: BreakScannerStops
						displaying: false.
			i _ BreakScanner lastIndex.
			
			(i > loc or: [i = loc and: [result == #endOfRun]])
				ifTrue: 
					[newWord _ aString copyFrom: loc to: (result == #endOfRun
									ifTrue: [i]
									ifFalse: [i - 1]).
					width _ index _ 0.
					length _ newWord size.
					[(index _ index + 1) <= length]
						whileTrue: [width _ width + (currentCharWidths at: (newWord at: index) asInteger + 1)].
					width _ width asFloat.
					currentLineWidth + width <= rmargin
						ifTrue: 
							[currentWords nextPutAll: newWord.
							currentLineWidth _ currentLineWidth + width]
						ifFalse: 
							[self outputChunks.
							self resetXdeltaY: 1.
							currentWords nextPutAll: newWord.
							currentLineWidth _ currentLineWidth + width.
							]].
			result == #space
				ifTrue: [currentLineWidth + spaceWidth <= rmargin
						ifTrue: 
							[currentLineWidth _ currentLineWidth + spaceWidth.
							currentWords nextPut: space]
						ifFalse: 
							[self outputChunks.
							self resetXdeltaY: 1]]
				ifFalse: [result == #tab
						ifTrue: 
							[n _ 1.
							[(i _ i + 1) <= sSize and: [(aString at: i)
									== tab]]
								whileTrue: [n _ n + 1].
							self outputChunks.
							self advanceToNextTabstop: n.
							i > sSize
								ifTrue: [^self]
								ifFalse: [i _ i - 1]]
						ifFalse: [result == #leftArrow
								ifTrue: [self putLeftArrow]
								ifFalse: [result == #upArrow
										ifTrue: [self putUpArrow]
										ifFalse: [result == #cr
												ifTrue: [self outputChunks; resetXdeltaY: 1]
												ifFalse: [result == #endOfRun
														ifTrue: [^self outputChunks]
														ifFalse: [result == #formFeed ifTrue: [self outputChunks; newPage]]]]]]].
			loc _ i + 1]!

changeFont: array 
	"Change to a new PostScript font and size combination.  Also scales   
	 the leading in proportion to the font size, and passes new       
	dimensions for the characters ^ and _."

	| fname size str names thickness |
	str _ WriteStream on: (String new: 255).
	fname _ array at: 1.
	size _ array at: 2.
	currentFont _ FontDescription named: fname.
	names _ (fname , size printString) asSymbol.
	currentCharWidths _ CharWidthTable at: names ifAbsent: [CharWidthTable at: names put: (currentFont widths collect: [:wid | wid * size])].
	underlining ifTrue: [self doUnderline: true].
	leading _ size asFloat / 6.0 + size asFloat * Adjustment.
"
	str nextPut: $/; nextPutAll: currentFont fullName; nextPutAll: ' findfont '.
	size printOn: str.
	str nextPutAll: ' scalefont setfont
/yDelta '.
"
	size printOn: str.
	str nextPutAll: ' ('; nextPutAll: currentFont fullName; nextPutAll: ') '.
	str nextPutAll: ' F
/yDelta '.
	leading asFloat / Adjustment printOn: str.
	str nextPutAll: ' def'; cr.
	currentSize _ size asFloat.
	leftArrowWidth _ currentCharWidths at: $_ asInteger + 1.
	leftArrowWidth asFloat / Adjustment printOn: str.
	str space.
	"leftArrowheadHeight" currentSize / 3.0 printOn: str.
	thickness _ currentFont underlineThickness * currentSize * 0.666 / Adjustment.
	str space.
	thickness printOn: str. "for left arrow"
	leftArrowOffsetY _ currentSize * Adjustment / 3.0.
	upArrowWidth _ currentCharWidths at: $^ asInteger + 1.
	str space.
	upArrowWidth asFloat / Adjustment printOn: str.
	str space.
	"upArrowHeight" currentSize / 2.0 printOn: str.
	str space.
	thickness printOn: str. "for up arrow"
	str nextPutAll: ' ArrowDim'; cr.
	chunks add: (Array with: #misc with: str contents)!

clipBox: height width: width 
	"Makes a box at the current origin,  and use it as the current clip  
	path.  Assumes gsave and grestore are done externally."

	file nextPutAll: 'newpath 0 0 moveto 0 '.
	height asFloat printOn: file.
	file nextPutAll: ' rlineto '.
	width asFloat printOn: file.
	file nextPutAll: ' 0 rlineto 0 '.
	height negated asFloat printOn: file.
	file nextPutAll: ' rlineto closepath clip'; cr!

currentTransformation: a b: b c: c d: d tx: e ty: f 
	"Output the PostScript code to set the current graphics coordinate 
	transformation matrix."

	file nextPut: $[.
	a asFloat printOn: file.
	file space.
	b asFloat printOn: file.
	file space.
	c asFloat printOn: file.
	file space.
	d asFloat printOn: file.
	file space.
	e asFloat printOn: file.
	file space.
	f asFloat printOn: file.
	file nextPutAll: ']'; cr!

deltaY: n 
	"'n' is the number of PostScript points to change the y    
	position.  If the page overflows, skip to a new page."

	currentY == nil
		ifTrue: [currentY _ topMargin]
		ifFalse: 
			[currentY _ currentY - n.
			currentY < bottomMargin ifTrue: [self newPage]]!

doUnderline: boolean 
	"Print an underline."

	| string |
	string _ (currentFont underlineThickness * currentSize / Adjustment) asFloat printString , ' ' , (currentFont underlinePosition * currentSize / Adjustment) asFloat printString , ' UStop
'.
	boolean
		ifTrue: [chunks add: (Array with: #underlining with: string)]
		ifFalse: [file nextPutAll: string]!

finalPageDef
	^'/finalPage
{
  /savefont currentfont def
  doFooter true eq { footer } if
  savefont setfont
  showpage
} bind def
'!

flushBuffer
	"Flush any waiting text out to 'chunks'."
	currentWords isEmpty
		ifFalse: 
			[chunks addLast: (Array
					with: #string
					with: currentWords contents
					with: currentFont
					with: currentSize).
			currentWords _ WriteStream on: (String new: 255)]!

grestore
	"Emit the PostScript code to restore a graphics state saved on the 
	PostScript stack."

	file nextPutAll: ' grestore'; cr!

gsave
	"Emit the PostScript code to save the current graphics state on the 
	PostScript stack."

	file nextPutAll: ' gsave'; cr!

imageWidth: width height: height bits: bits 
	"Emit the PostScript code needed to print a bitmap...  any needed 
	scaling,  translation,  etc.  is done externally."

	| hex s word n perLine |
	hex _ 'fedcba9876543210'.
	width printOn: file.
	file space.
	height printOn: file.
	file nextPutAll: ' 1 '.
	self
		currentTransformation: width
		b: 0
		c: 0
		d: height negated
		tx: 0
		ty: height.
	file nextPutAll: ' {currentfile pix readhexstring pop} image'; cr.
	perLine _ width / 16.
	n _ 0.
	"s _ ReadStream onCollection: bits."
	s _ ReadStream
				on: bits
				from: 1
				to: bits size.
	[s atEnd]
		whileFalse: 
			[word _ s next.
			file nextPut: (hex at: ((word bitShift: -12)
						bitAnd: 15)
						+ 1).
			file nextPut: (hex at: ((word bitShift: -8)
						bitAnd: 15)
						+ 1).
			file nextPut: (hex at: ((word bitShift: -4)
						bitAnd: 15)
						+ 1).
			file nextPut: (hex at: (word bitAnd: 15)
						+ 1).
			n _ n + 1.
			n = perLine
				ifTrue: 
					[file nextPut: $
.
					n _ 0]]!

lineto: aPoint 
	"Emit the Postscript code to draw a lineto to a position on the page."

	(aPoint x / Adjustment) asFloat printOn: file.
	file space.
	(aPoint y / Adjustment) asFloat printOn: file.
	file nextPutAll: ' lineto'; cr!

moveto: aPoint 
	"Emit the Postscript code to move to a position on the page."
	aPoint x asFloat / Adjustment printOn: file.
	file space.
	aPoint y asFloat / Adjustment printOn: file.
	file nextPutAll: ' moveto'; cr!

outputChunks
	"Output a 'chunk' of accumulated text. Chunks are represented as:   
	Array with: #type with: currentWords with: fontDescription."

	self flushBuffer.
	chunks do: [:aChunk | (aChunk at: 1)
			== #string
			ifTrue: 
				[self outputString: (aChunk at: 2).
				file nextPutAll: ' show'; cr]
			ifFalse: [file nextPutAll: (aChunk at: 2)]].
	chunks _ OrderedCollection new: 10!

outputString: aString 
	"Check for '( ' and ')' and '\' characters, and translate them so 
	PostScript can handle them.  
	Code for translating characters greater than ascii 127 to octal  
	escape sequences is here also,  but is currently commented out as it  
	is not needed at this time."

	| index length c |
	file nextPut: $(.
	index _ 0.
	length _ aString size.
	[(index _ index + 1) <= length]
		whileTrue: 
			[c _ aString at: index.
			c == $(
				ifTrue: [file nextPutAll: '\050']
				ifFalse: [c == $)
						ifTrue: [file nextPutAll: '\051']
						ifFalse: [c == $\
								ifTrue: [file nextPutAll: '\\']
								ifFalse: [file nextPut: c]]]].
	"ifFalse: [c asInteger > 127 
	ifTrue:  
	[file nextPut: $\. 
	c asInteger printOn: file base: 8] 
	ifFalse: [file nextPut: c]]]]]."
	file nextPut: $)!

putLeftArrow
	"Emit the code to print a 'left arrow'  -  invokes a predefined    
	Postscript method."

	| arrowStartX arrowEndX arrowY str |
	self flushBuffer.
	str _ WriteStream on: (String new: 80).
	arrowStartX _ currentLineWidth + leftMargin.
	arrowEndX _ arrowStartX + leftArrowWidth.
	arrowY _ currentY + leftArrowOffsetY.
	arrowEndX <= rightMargin
		ifFalse: 
			[self resetXdeltaY: 1.
			arrowStartX _ currentLineWidth + leftMargin.
			arrowEndX _ arrowStartX + leftArrowWidth.
			arrowY _ currentY + leftArrowOffsetY].
	currentLineWidth _ currentLineWidth + leftArrowWidth.
	arrowStartX asFloat / Adjustment printOn: str.
	str space.
	arrowY asFloat / Adjustment printOn: str.
	str nextPutAll: ' leftArrow'; cr.
	(currentLineWidth + leftMargin) asFloat / Adjustment printOn: str.
	str space.
	currentY asFloat / Adjustment printOn: str.
	str nextPutAll: ' moveto '; cr.
	chunks add: (Array with: #misc with: str contents)!

putUpArrow
	"Emit the code to print an 'up arrow'  -  invokes a predefined   
	Postscript method."

	| upArrowStartX upArrowEndX upArrowY str |
	self flushBuffer.
	str _ WriteStream on: (String new: 80).
	upArrowStartX _ currentLineWidth + leftMargin.
	upArrowEndX _ upArrowStartX + upArrowWidth.
	upArrowY _ currentY.
	upArrowEndX <= rightMargin
		ifFalse: 
			[self resetXdeltaY: 1.
			upArrowStartX _ currentLineWidth + leftMargin.
			upArrowEndX _ upArrowStartX + upArrowWidth.
			upArrowY _ currentY].
	currentLineWidth _ currentLineWidth + upArrowWidth.
	upArrowStartX asFloat / Adjustment printOn: str.
	str space.
	upArrowY asFloat / Adjustment printOn: str.
	str nextPutAll: ' upArrow'; cr.
	(currentLineWidth + leftMargin) asFloat / Adjustment printOn: str.
	str space.
	currentY asFloat / Adjustment printOn: str.
	str nextPutAll: ' moveto '; cr.
	chunks add: (Array with: #misc with: str contents)!

resetXdeltaY: n 
	"Rest x position to the start of a line,  and advance y down n lines."

	underlining ifTrue: [self doUnderline: false].
	currentY - (n * leading) < bottomMargin
		ifTrue: [self newPage]
		ifFalse: [n
				timesRepeat: 
					[file nextPutAll: 'CR'; cr.
					currentY _ currentY - leading]].
	underlining ifTrue: [self startUnderlining].
	currentLineWidth _ 0!

rlineto: aPoint 
	"Emit the Postscript code to draw a line to a position relative to the 
	current position on the page."

	(aPoint x / Adjustment) asFloat printOn: file.
	file space.
	(aPoint y / Adjustment) asFloat printOn: file.
	file nextPutAll: ' rlineto'; cr!

rotate: degrees 
	"Emit the PostScript code to rotate the coordinate system."

	degrees asFloat printOn: file.
	file nextPutAll: ' rotate'; cr!

scale: aPoint 
	"Emit the PostScript code to scale the coordinate system...  'aPoint' is 
	not really a point,  but rather the x and y scale factors."

	aPoint x asFloat printOn: file.
	file space.
	aPoint y asFloat printOn: file.
	file nextPutAll: ' scale'; cr!

show: string 
	"Emit the PostScript code to print a string of characters."

	self outputString: string.
	file nextPutAll: ' show'; cr!

showPage
	"Emit the PostScript code to actually print the current page...  push 
	paper!!"

	file nextPutAll: ' newPage'; cr!

startUnderlining
	"Set up to underline the following text."

	self flushBuffer.
	chunks add: (Array with: #underlining with: 'Ustart
').
	underlining _ true!

stopUnderlining
	"Defeat the underlining of the following text."

	self flushBuffer.
	self doUnderline: true.
	underlining _ false!

translate: aPoint 
	"Emit the PostScript code to translate the PostScript coordinate 
	system."

	| newPoint |
	newPoint _ aPoint / Adjustment.
	newPoint x asFloat printOn: file.
	file space.
	newPoint y asFloat printOn: file.
	file nextPutAll: ' translate'; cr!

underline
	"Add the parameters needed for the underlining."

	chunks add: (Array with: #underlining with: (currentFont underlineThickness * currentSize / Adjustment) asFloat printString , ' ' , (currentFont underlinePosition * currentSize / Adjustment) asFloat printString , ' UStop
')! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PostScriptPrinter class
	instanceVariableNames: ''!
int: Sensor mousePoint]
				whileTrue: [events runNextFor: controller on: view warp.
					view displayView]]"]"!



!PostScriptPrinter class methodsFor: 'class initialization'!

initialize
	"Initialize the printer... output file name,  character scanner 
	parameters, and some misc scaling/coordinate stuff."

	CharWidthTable _ IdentityDictionary new.
	Adjustment _ 1000.0.
	KPointsPerInch _ 72.0 * Adjustment.
	TempFileName _ 'temp.postscript'.
	BreakScanner _ CharacterScanner new.
	BreakScanner xTable: (Array new: 257 withAll: 0).
	BreakScannerStops _ Array new: 258.
	BreakScannerStops at: Character cr asciiValue + 1 put: #cr.
	BreakScannerStops at: Character space asciiValue + 1 put: #space.
	BreakScannerStops at: Character tab asciiValue + 1 put: #tab.
	BreakScannerStops at: 12 + 1 put: #formFeed.
	"formfeed"
	BreakScannerStops at: $_ asciiValue + 1 put: #leftArrow.
	BreakScannerStops at: $^ asciiValue + 1 put: #upArrow.
	BreakScannerStops at: 257 put: #endOfRun.
	BreakScannerStops at: 258 put: #crossedX.
	BreakScanner stopConditions: BreakScannerStops.
	BreakScanner destX: 0!

new
	"Initialize."

	^super new initialize! !

!PostScriptPrinter class methodsFor: 'instance creation'!

named: aString print: aDocument 
	"Send the document to be rendered to the named PostScript printer..."

	| baseName fileName idx tail numidx |
	fileName _ "Filename named:" 'ps-'.
	numidx _ fileName count.
	[(fileName at: numidx) isDigit] whileTrue: [numidx _ numidx - 1].
	tail _ fileName copyFrom: numidx + 1 to: fileName count.
	baseName _ fileName copyFrom: 1 to: numidx.
	tail count == 0
		ifTrue: [idx _ 0]
		ifFalse: [idx _ Integer readFrom: (tail readStream)].
	[fileName asFilename exists] whileTrue: [
		fileName _ baseName, (idx printString).
		idx _ idx + 1].
	(fileName isEmpty not and: [FileDirectory isLegalFileName: fileName])
		ifFalse: [^Transcript show: 'not printed'].
	TempFileName _ fileName.
	self new printer: aString print: aDocument onFileNamed: TempFileName! !

!PostScriptPrinter class methodsFor: 'printing'!

sendToPrinter
	"Send the temp file to the printer via a system call, or   
	print a failure message."

	Transcript show: 'sending to printer... '.
	Filename errorReporter unsupportedOperationSignal
		handle: [:ex |
				Transcript show: ex errorString.
				ex return]
		do: [TempFileName asFilename printFile.
			Transcript show: ' ...done.'; cr]
	"Transcript show: ' ... not really. do it yurself.'; cr; endEntry"! !

!PostScriptPrinter class methodsFor: 'temp file access'!

tempFileName: aString
	"Set the name for temp files."

	TempFileName _ aString! !

PostScriptPrinter initialize!
