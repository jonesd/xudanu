#!/usr/local/bin/ksh
#
# Moved echoed text to StubbleForm.f
# Added preprocessing of StubbleForm.f, rearranged 'rm's slightly.
# Added define for $(VANISH) output ant, which vanishes.
#       - michael, thru Nov 24 1990
#
# moved $(VANISH) define to StubbleForm.f, now that we have $DEF
#       - michael, thru Dec  3 1990
#
# $Id: stubble.ksh,v 1.1 1992/10/21 17:47:31 ravi Exp $
# set -x
formicbin=formic
cpp="cl386 -E"
cppflags=
cppcommflags=
lexex=NUL:
ffile=${0%/*}/../stubblef.f
fincldir=-I${0%/*}/../
#incldir="-Ic:/mstlsfix/include -Ic:/mstools/h/strict -Ic:/mstools/h"
fffile=fx$$.f
usage () {
cat <<EOF
echo "usage: $1 [args ...] input_file"
echo "  args are:"
echo "  -f<file>        specifies formic script"
echo "  -l<file>        specifies lexical extensions file"
echo "  -I<path>        include directory for cpp (run over input file)"
echo "  -J<path>        include directory for cpp (run over formic script)"
echo "  -D<define>      definition for cpp (run over input file)"
echo "  -F<define>      definition for cpp (run over formic script)"
echo "  -o<file>        output file"
echo "  -p              just produce .ppout file"
echo "  -d              use documentation script, producing .doc file"
echo "  Any number of -I, -J, -D, and -F can be given"
EOF
; }

if test $# -lt 1 ; then
        usage ${0##*/}
        exit 2
fi

#__cplusplus and c_plusplus as defined by C++
defs='-D__cplusplus=1 -Dc_plusplus=1 -DWIN32 -DMSC_VER=700'

fdefs=''
keepppout=0
document=0

for arg in $*; do
        case $arg in
            -f*) ffile=${arg#-f}
                ;;
            -l*) lexex=${arg#-l}
                ;;
            -I*) incls="$incls $arg"
                ;;
            -J*) fincls="$fincls -I${arg#-J}"
                ;;
            -D*) defs="$defs $arg"
                ;;
            -F*) fdefs="$fdefs -D${arg#-F}"
                ;;
            -o*) output=${arg#-o}
                ;;
            -d)  ffile=${0%/*}/doc.f
                 document=1
                ;;
#           -p)  keepppout=1
#               ;;
            -*)  echo "Do not understand $arg"
                 usage ${0##*/}
                 exit 2
                ;;
            *)   fname=$arg
                ;;
        esac
done

incldir="$incldir $incls"
fincldir="$fincldir $fincls"

fnroot=${fname%.*}
if test $document -eq 1 ; then
        output=${output:-"$fnroot".doc}
else
        output=${output:-$fnroot.stb}
fi

if [ ! -r "$fnroot".hxx ] ; then
     echo ${0##*/}: "$fnroot".hxx not found
     exit 1
fi

ppout=$fnroot.ppo
touch $ppout

hxxfile=$fnroot.hxx

touch $fffile

#if test $keepppout -eq 0; then
#       trap 'rm -f $ppout $fffile $output' 2;
#else
#       $cpp $cppflags -DSTUBBLE $defs $incldir $hxxfile > $ppout
#       exit 0
#fi

echo "$cpp -Za $cppcommflags $fdefs $fincldir $ffile > $fffile"
echo "if not errorlevel 1 goto cppok"
echo "  echo ${0##*/}: preprocessor failed for $ffile"
echo "  goto exit"
echo ":cppok"

echo "$cpp $cppflags -DSTUBBLE $defs $incldir $hxxfile > $ppout"
echo "if not errorlevel 1 goto cpp2ok"
echo "  echo ${0##*/}: preprocessor failed for $hxxfile"
echo "  goto exit"
echo ":cpp2ok"
echo "$formicbin $fffile -i $ppout > $output"
echo "if not errorlevel 1 goto formicok"
echo "  echo ${0##*/}: code generation failed"
echo "  goto exit"
echo ":formicok"
echo ":exit"
echo "rem rm -f $fffile $ppout $output"

