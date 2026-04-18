'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:45 pm'!

FMFont subclass: #FontObj
	instanceVariableNames: '
		fontInternal {Xv.U.opaque var}
		fontStructInternal {XFontStruct star}'
	classVariableNames: 'DefaultFont {Xv.U.opaque var} '
	poolDictionaries: ''
	category: 'Never Never Land'!

(FontObj getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FontObj methodsFor: 'creating'!

create

super create.
   
   '/* problem is what display is this going to be used on, fonts depend on
	dpy for verious things, bit depth, pixel size etc */
	fontInternal = DefaultFont;' translateOnly.

   XView USES.
  	[fontInternal _ DefaultFont.] translateOnly.
	["fontInternal_ XView xv.U.find: canvas with: #WIN.U.FONT"] smalltalkOnly!

create: realFont {Xv.U.opaque var} 
	
	super create.
	' 
	/* problem is what display is this going to be used on, fonts depend on 
	dpy for verious things, bit depth, pixel size etc */ 
	fontInternal = realFont; 
	
	' translateOnly.
	
	[XView USES.
	fontInternal _ realFont] smalltalkOnly! !

!FontObj methodsFor: 'accessing'!

{IntegerVar} ascent
	
	'return this->fontStruct()->ascent;' translateOnly.!

{IntegerVar}bearingOf: characterfoo{PackOBits}
	  
	  
	   '
	    int start;
	    int end;
	    int ch;
	    XFontStruct * xfs;
	    xfs = this->fontStruct();
	    start = (xfs->min_byte1<<8) | (xfs->min_char_or_byte2);
	    end = (xfs->max_byte1<<8) | (xfs->max_char_or_byte2);
	    ch = characterfoo->asLong();
	    if(ch >=start && ch<= end){
	  	return xfs->per_char[ch - start] .rbearing;
	    }else{
	  	 return xfs->per_char[(xfs->default_char)].rbearing;
	    }
	  	
	  	' translateOnly!

{IntegerVar} descent
	
	'return this->fontStruct()->descent;' translateOnly.!

{void star} font
	 
	  fontInternal = NULL ifTrue:[
		fontInternal _ (XView xv.U.find: (XView baseWindow) with: #FONT with: Int32Zero ) basicCast: #Xv.U.opaque var .
		FontObj  setDefaultFont: fontInternal.
	 ].
	^ fontInternal!

{XFontStruct star} fontStruct
'
 	if(!!fontStructInternal){ 
		fontStructInternal  = XQueryFont(defaultDpy(), (Xv_opaque)xv_get((Xv_opaque)this->font(),XV_XID));
	}
	return 	fontStructInternal;
' translateOnly.!

{UInt32} hashForEqual
	^self basicCast: UInt32!

{BooleanVar}isEqual: other{Heaper}
	"Return true if the two objects are equal."
	^ self hashForEqual = other hashForEqual!

{IntegerVar}widthOf: characterfoo{PackOBits}
	  
	  
	   '
	    int start;
	    int end;
	    int ch;
	    XFontStruct * xfs;
	    xfs = this->fontStruct();
	    start = (xfs->min_byte1<<8) | (xfs->min_char_or_byte2);
	    end = (xfs->max_byte1<<8) | (xfs->max_char_or_byte2);
	    ch = characterfoo->asLong();
	    if(ch >=start && ch<= end){
	  	return xfs->per_char[ch - start] .width;
	    }else{
	  	 return xfs->per_char[(xfs->default_char)].width;
	    }
	  	
	  	' translateOnly!

{IntegerVar} widthOfString: string {char vector}
self unimplemented.  "not used, I use more direct stuff, because of ambiguity of meaning of width"
	^10!

{ScruTable}widths
	"Answer the width of the argument as a character in the receiver."

	| widths{MuTable} width{IntegerPos} tmp {IntegerVar} |
	self unimplemented.
	tmp _ 255.
	widths _ IntegerTable make.IntegerVar: 256.
	
	[width _ IntegerPos make: 10.]translateOnly.
	[width _ self widthOf: (Character value: tmp).]smalltalkOnly.
	Int0 to:  tmp do: [:ascii{IntegerVar} | widths atInt: ascii store: width].
	["0 to: minAscii do: [:ascii | widths at.IntegerVar: ascii store: width].
	minAscii to: maxAscii do: 
		[:ascii | widths at.IntegerVar: ascii store: (xTable at: ascii + 2) - (xTable at: ascii + 1)].
	"] smalltalkOnly.
	^widths! !

!FontObj methodsFor: 'printing'!

{void}printOn: aStream {ostream reference}
	aStream << self getCategory name  << '('
	
	<< ' fontInternal  =' << fontInternal 
	<<	'fontStructInternal = ' <<  fontStructInternal << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FontObj class
	instanceVariableNames: ''!

(FontObj getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FontObj class methodsFor: 'randomness'!

{void} setDefaultFont: newFont {Xv.U.opaque var}
	
	DefaultFont = newFont.! !

!FontObj class methodsFor: 'pseudo constructors'!

{FMFont} fMFont
	^self create!

make
	^self create! !

!FontObj class methodsFor: 'smalltalk: smalltalk init'!

initTimeNoninhereted
	self REQUIRES: XView.
	FontObj  setDefaultFont:( (XView xv.U.find: (XView baseWindow) with: #FONT with: Int32Zero ) basicCast: #Xv.U.opaque var ).!

{void}linkTimeNonInherited
	DefaultFont _ NULL! !