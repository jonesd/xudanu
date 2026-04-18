'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:22 pm'!

Heaper subclass: #FMColor
	instanceVariableNames: ''
	classVariableNames: '
		BLACK {FMColor} 
		WHITE {FMColor} '
	poolDictionaries: ''
	category: 'FM-Warp Display'!
FMColor comment:
'Color is actually an Enum.  I just initialize globals BLACK and WHITE with an instance of Color.

The color model is implemented very sloppily.  

Warps have a current ink.  The ink can be either a color or a pattern of colors defined by an image.  All the operations draw using the current color.  The sloppiness arises using halftones for patterns:  is the white in a halftone white or transparent?  It should be opaque, but the white behind text should be transparent.  No simple display operation in Smalltalk handles both cases.  The correct thing to do is to make another glyph-set that uses the pattern and then draw with that, or something (that doesn''t work either...).  Just remember that this needs to be fixed for the sophisticated cases to work correctly.

Also note that pattern inks should ''and'' when combined.  Currently I just replace the ink.  Further, they should be translated to the origin of the warp (for alignment).  Finally, I don''t currently handle non-mask images.'!

(FMColor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMColor methodsFor: 'testing'!

{BooleanVar} isColor
	^true! !

!FMColor methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '('.
	WHITE == self ifTrue: [oo << 'WHITE'].
	BLACK == self ifTrue: [oo << 'BLACK'].
	oo << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMColor class
	instanceVariableNames: ''!

(FMColor getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMColor class methodsFor: 'smalltalk: smalltalk initialization'!

initTimeNonInherited
	BLACK _ FMColor create.
	WHITE _ FMColor create!

linkTimeNonInherited
	BLACK _ NULL.
	WHITE _ NULL! !

!FMColor class methodsFor: 'constants'!

{FMColor} fmBlackColor
	^BLACK!

{FMColor} fmWhiteColor
	^WHITE! !