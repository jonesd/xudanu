#!/usr/local/bin/ksh
#
# $Id: stubble.ksh,v 1.2 1992/12/19 00:50:19 ravi Exp $
set -x
formicbin="run386 c:/xu/bin/hc/formic"
cpp="c:\c700\bin\cl -E"
cppflags=
cppcommflags=
lexex=NUL:
ffile=${0%/*}/../stubblef.f
fincldir=-I${0%/*}/../
incldir="-Id:/hc/inc -Id:/hc/incc"
fffile=fx$$.f
usage () {
cat <<EOF
usage: $1 [args ...] input_file
	args are:
	-f<file>	specifies formic script
	-l<file>	specifies lexical extensions file
	-I<path>	include directory for cpp (run over input file)
	-J<path>	include directory for cpp (run over formic script)
	-D<define>	definition for cpp (run over input file)
	-F<define>	definition for cpp (run over formic script)
	-o<file>	output file
	-p		just produce .ppout file
	-d		use documentation script, producing .doc file
	Any number of -I, -J, -D, and -F can be given
EOF
; }

if test $# -lt 1 ; then
	usage ${0##*/}
	exit 2
fi

#__cplusplus and c_plusplus as defined by C++
defs='-D__cplusplus=1 -Dc_plusplus=1'

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
	    -d)  ffile=${0%/*}/Doc.f
		 document=1
		;;
	    -p)  keepppout=1
		;;
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
	output=${output:-$fnroot-stb.cxx}
fi

if [ ! -r "$fnroot".hxx ] ; then
     echo ${0##*/}: "$fnroot".hxx not found
     exit 1
fi

ppout=$fnroot.ppo
touch $ppout

hxxfile=$fnroot.hxx

touch $fffile

if test $keepppout -eq 0; then
	trap 'rm -f $ppout $fffile $output' 2;
else
	echo $cppflags -DSTUBBLE $defs $incldir $hxxfile > pp$$.tmp
	$cpp @p$$.tmp > $ppout
	exit 0
fi

#cat > /tmp/_stub.sed <<DONE
#s:///:~~~:
#s://:~~:
#s:^\$:~:
#DONE
#sed -f /tmp/_stub.sed < $ffile > $fffile
$cpp $cppcommflags $fdefs $fincldir $fffile > $fffile
#cat > /tmp/_stub.sed <<DONE
#s/\$ LEX/$LEX/
#s: \$/:$/:
#/#pragma/d
#s:~~~:///:
#s:~~://:
#s:^~:$:
#DONE
#else
# hc386 seems to return non-zero even when it succeeds
#        echo ${0##*/}: preprocessor failed for $ffile
#	rm -f $fffile
#        exit 1

echo $cppflags -DSTUBBLE $defs $incldir $hxxfile > pp$$.tmp
#if $cpp @pp$$.tmp > $ppout ; then
$cpp @pp$$.tmp > $ppout
        if $formicbin $fffile -i $ppout > $output ; then
#	   rm -f $fffile $ppout
        else
#	   rm -f $output $fffile
	   echo ${0##*/}: code generation failed
	   exit 1
        fi

#    rm -f $fffile $ppout

#else
#        echo ${0##*/}: preprocessor failed for $hxxfile
#	rm -f $fffile
#        exit 1
#fi

trap  2
exit 0


