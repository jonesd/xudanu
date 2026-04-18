'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:02 pm'!

Object subclass: #Document
	instanceVariableNames: 'entities currentStyle currentFontStyle '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Printing'!
)!


!Document methodsFor: 'initialize-release'!

close
	"Close out the current document."

	currentStyle _ 0!

initialize
	"Set up defaults,  and create an ordered collection to hold the 
	intermediate representation of the document."

	entities 			_ OrderedCollection new: 255.
	currentStyle 		_ PageStyle default.
	currentFontStyle 	_ FontStyle default.
	self fontStyleChanged.
	self setpageHeight: currentStyle pageHeight deepCopy.
	self setpageWidth: currentStyle pageWidth deepCopy.
	self setTabs: currentStyle tabStops deepCopy.
	self setMargins: currentStyle margins deepCopy! !

!Document methodsFor: 'rendering control'!

render: aBlock 
	"Render the entities to PostScript."

	aBlock value: (Association key: #start: value: nil).
	entities do: [:entity | aBlock value: entity].
	aBlock value: (Association key: #end: value: nil)!

toPrinter
	"Send the data to the printer... note that 'PostScriptPrinter' expects 
	a string naming the device.  This is just a stub, but in the future..."

	PostScriptPrinter named: '' print: self! !

!Document methodsFor: 'Smalltalk compatibility'!

addText: aText 
	"Add a formatted Text (strings and runs) to the document,    
	using TextStyle default."

	self addText: aText asText under: (TextStyle styleNamed: #small ifAbsent: [TextStyle default])!

addText: aText under: aTextStyle 
	"Add a formatted Text (strings and runs) to the document,    
	using a specified text style."

	| changed familySizeFace size face familyName underlined |
	changed _ false.
	self stringsAndIndexesFor: aText do: 
		[:string :index | 
		familySizeFace _ (aTextStyle fontAt: index) familySizeFace.
		underlined _ aTextStyle isFontUnderlined: index.
		familyName _ self getFontLike: familySizeFace.
		size _ familySizeFace at: 2.
		face _ familySizeFace at: 3.
		face _ #(Default Bold Italic BoldItalic ) at: face + 1.
		familyName ~= currentFontStyle currentFamily
			ifTrue: 
				[currentFontStyle setFamily: familyName.
				changed _ true].
		size ~= currentFontStyle currentSize
			ifTrue: 
				[currentFontStyle setSize: size.
				changed _ true].
		face ~= currentFontStyle currentFace
			ifTrue: 
				[currentFontStyle setFace: face.
				changed _ true].
		underlined
			ifTrue: 
				[self startUnderlining.
				changed _ true].
		changed
			ifTrue: 
				[self fontStyleChanged].
		self addString: string.
		underlined ifTrue: [self stopUnderlining]]!

getFontLike: familySizeFace 
	"Map a strike font to an abstract type family."

	| family |
	family _ familySizeFace at: 1.
	(family = 'TIMESROMAN' or: [family = 'SERIF'])
		ifTrue: [^#Serif].
	(family = 'HELVETICA' or: [family = 'SANSERIF' or: [family = 'SANS-SERIF']])
		ifTrue: [^#SanSerif].
	(family = 'FIXED' or: [family = 'ICON'])
		ifTrue: [^#FixedPitch].
	self error: 'don''t know how to handle this font yet!!'! !

!Document methodsFor: 'adding entities'!

addImage: aForm 
	"Add a form to the list of entities,  to be printed in a device 
	independent scaling giving an image at screen resolution."

	entities add: (Association key: #image: value: aForm "deepCopy")!

addImageOneToN: aFormandScale 
	"Add a form to the list of entities,  to be printed in a device  
	dependent scaling giving an image at one-to-n pixel resolution."

	entities add: (Association key: #imageOneToN: value: aFormandScale deepCopy)!

addItalicHeader: aString pointSize: pointSize 
	"Add to the list of entities an italic header,  at a point size given by 
	the user."

	| oldStyle oldSize |
	oldStyle _ currentFontStyle currentFace.
	oldSize _ currentFontStyle currentSize.
	currentFontStyle setFace: #Italic.
	currentFontStyle setSize: pointSize.
	self fontStyleChanged.
	entities add: (Association key: #string: value: aString).
	currentFontStyle setFace: oldStyle.
	currentFontStyle setSize: oldSize.
	self fontStyleChanged!

addString: aString 
	"Add the given string to the current paragraph."

	
	entities add: (Association key: #string: value: aString)!

doFooter: doFooter footerString: footerString doPageNumbers: doPageNumbers 
	"Set the footer of the page."

	entities add: (Association key: #doFooter: value: (Array
				with: doFooter
				with: footerString
				with: doPageNumbers))!

fontStyleChanged
	"Something stylistic has changed,  so copy all the font style stuff  
	into the list of entities."

	entities add: (Association key: #fontStyle: value: currentFontStyle deepCopy)!

newPage
	"Advance to the next page."

	entities add: (Association key: #newPage: value: nil)!

setLandscape
	"Rotate the rendering 90 degrees."

	| oldPageWidth oldPageHeight |
	oldPageWidth _ currentStyle pageWidth.
	oldPageHeight _ currentStyle pageHeight.
	currentStyle pageSize: oldPageHeight @ oldPageWidth.
	self setpageHeight: currentStyle pageHeight deepCopy.
	self setpageWidth: currentStyle pageWidth deepCopy.
	entities add: (Association key: #landscape: value: nil).
	self setMargins: currentStyle margins deepCopy!

setMargins: anArray 
	"Set the margins to the given displacements inward from the page 
	edges."

	entities add: (Association key: #margins: value: anArray)!

setpageHeight: height 
	"Set the height of the page to the given value."

	entities add: (Association key: #pageHeight: value: height)!

setpageWidth: width 
	"Set the width of the page to the given value."

	entities add: (Association key: #pageWidth: value: width)!

setTabs: anArray 
	"Set the tab stops to the given x positions."

	entities add: (Association key: #tabs: value: anArray)!

startParagraph
	"Set up to start a new paragraph of text."

	
	entities add: (Association key: #startParagraph: value: nil)!

startUnderlining
	"Set up to underline any subsequent text."

	entities add: (Association key: #underline: value: true)!

stopUnderlining
	"Set up to not underline subsequent text."

	entities add: (Association key: #underline: value: false)! !

!Document methodsFor: 'errors'!

errorNotBuilding
	"If not building a paragraph when something is added to one,  print an 
	error message."

	self error: 'paragraph not being built!!'! !

!Document methodsFor: 'margins'!

margins
	"Return the current margin settings."

	^currentStyle margins!

setBottomMargin: newY 
	"Set the value of the bottom margin."

	currentStyle bottomMargin: newY!

setLeftMargin: newX 
	"Set the value of the left margin."

	currentStyle leftMargin: newX!

setRightMargin: newX 
	"Set the right margin."

	currentStyle rightMargin: newX!

setTopMargin: newY 
	"Set the top margin."

	currentStyle topMargin: newY! !

!Document methodsFor: 'private:'!

stringsAndIndexesFor: aText do: aBlock 
	"Send string and strike font index to aBlock for a text."

	| fontruns values str index string|
	string _ aText string.
	index _ 1.
	fontruns _ aText runs runs.
	values _ aText runs values.
	1 to: fontruns size do: 
		[:i | 
		str _ string copyFrom: index to: (fontruns at: i) + index - 1.
		aBlock value: str value: (values at: i).
		index _ index + str size]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Document class
	instanceVariableNames: ''!
AMERICAN PHYSICAL SOCIETY
                            SPRING MEETING - 1-2 MAY 1989
                                    BALTIMORE, MD

                           SPECIAL SESSION ON COLD FUSION

                                      ABSTRACT
'
"
                Beginning  on  the  evening  of  1  May 1989, a Special
              Session on Cold Fusion was held at the American  Physical
              Society  Spring  Meeting  in  Baltimore.  Representatives
              from GE Research attended.  This  report  represents  the
              combination  of  several  reports  by  GE Researchers; at
              least one of which was written written between  2  and  3
              am, immediately following the session.

                The session  was  scheduled for 7:30pm to 12:24am (yes,
              12:24am exactly) with four invited  talks  and  seventeen
              contributed  talks.  One  contributed  talk was withdrawn
              prior to the meeting.   A  full  agenda  is  provided  as
              Appendix  I.  About 1800 people were in attendance during
              the four invited talks. This number dropped sharply after
              the  invited talks, and then dwindled to about 100 by the
              end of the meeting. The meeting ended at 12:28am.

                Neither Fleischmann nor Pons attended. Fleischmann  was
              invited  as  soon  as this special session was organized,
              and said that either he or Pons would try  to  attend.  A
              few  days  ago,  the  conference  was  notified than both
              Fleischmann and Pons were too busy to attend.

                In summary, the  session  was  characterized  by  major
              research  groups  announcing that they had been unable to
              confirm the results of F&P. Many also refuted the results
              of Jones.  Not one single group presented data to confirm
              the F&P cold fusion claims.

          1. Invited Speakers

          1.1. Jones

          Steve Jones, BYU, opened the session with a discussion of his own
          work,  which  he  emphatically said would NOT lead to a nzewz power
          source, but does present interesting nzew physics.

          After discussing briefly muon catalyzed fusion  and  piezo-driven
          fusion,  Jones  showed  a  laboratory  notebook from his research
          group dated 22 May 1986, showing something which looked very much
          like  the  electrolytic  set-up for a F&P cold fusion cell.  They
          specifically set out to design a neutron detector using a  liquid
          scintillator  to  slow down the neutrons and Li(6) doped glass in
          front of 2 PMT''s to capture the (thermalized?)  neutrons.    They
          somehow got from this an energy spectrum of the neutrons.  Fusion
          neutrons have a characteristic energy at 2.45  MeV.    What  they
          ended  up  seeing  was a signal at ~2.5 MeV at about 5.7 standard
          deviations above the background.(Someone  later  questioned  this
          and  said  it  may  really  be  more like 2 standard deviations.)
          Their actual observation rate was 6E-4 sec-1, the  efficiency  of
          detection  was  1%, so their measured neutron production rate was
          0.06 sec-1.  He said they checked many controls like using  light
          water  and  trying the whole thing with zero current on the cell.
          This appears to be very important.  In those controls he only saw
          the usual background.  They also tried some nezw experiments where
          they simplified the electrolyte (to an acid of some sort) and saw
          essentially  the  same excess neutrons when the thing was on.  He
          said something (we couldn''t hear very well) about  the  palladium
          plating out on the titanium, which is important.


"!


!Document class methodsFor: 'instance creation'!

new
	"Initialize."

	^super new initialize!

open
	"Make a new document."

	^self new! !

!Document class methodsFor: 'examples'!

doTest1
	"Make a simple PostScript file... just some text,  with everything 
	defaulted."
	"Document doTest1"

	| document |
	Cursor wait
		showWhile: 
			[document _ Document new.
			document startParagraph.
			document addString: 'Oh,  nooooooo Mr. Bill!!'.
			document close.
			document toPrinter]!

doTest2
	"Make a simple PostScript file... a screendump scaled in a device 
	independent way."
	"Document doTest2"

	| document |
	Cursor wait
		showWhile: 
			[document _ Document new.
			document startParagraph.
			document addItalicHeader: 'Screendump:' pointSize: 24.
			document addImage: Form fromUser.
			document close.
			document toPrinter]!

doTest3
	"Make a screendump,  at one-to-n pixel resolution from screen          
	pixels to printer pixels,  to a PostScript file... a scale factor of four   
	looks nice on the Apple laserwriter:  it prints at 75 'points' to the 
	inch rather than Adobe's 72 'points' to the inch,  resulting in better  
	looking bitmaps. A scale factor of one will print one form pixel to one  
	printer pixel; this looks very nice indeed but takes a lot of data!!"
	"Document doTest3"

	| document scale |
	scale _ 2.
	Cursor wait
		showWhile: 
			[document _ Document new.
			document startParagraph.
			document addItalicHeader: 'Screendump:' pointSize: 24.
			document addImageOneToN: (Array with: Form fromUser with: scale).
			document close.
			document toPrinter]!

doTest4
	"Make a simple PostScript file... some text,  with page numbers and a footer, in landscape mode."
	"Document doTest4"

	| document |
	Cursor wait
		showWhile: 
			[document _ Document new.
			document
				doFooter: true
				footerString: 'Foobar!!'
				doPageNumbers: true.
			document setLandscape.
			document startParagraph.
			document addString: '0
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
21
22
23
24
25
26
27
28
29
30
31
32
33
34
35
36
37
38
39
40
41
42'.
			document close.
			document toPrinter]! !