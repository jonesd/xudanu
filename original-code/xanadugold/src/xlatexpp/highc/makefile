#
#  xpp translated from smalltalk
#
#  $Id: makefile,v 1.3 1993/01/05 17:29:19 ravi Exp $
#
#  For SGI:
#   - Replaced % rule with generic rule for making o.txt from .rc.
#     Added .rc to SUFFIXES in xpp.mk.
#      - michael Mar 27 1992
#

XPPDIR = ../..
EXTRADEFS = -DMANUAL_CRUTCH
#CXXOPTS = -CRUTCH
include $(XPPDIR)/xpp/$(PLATFORM)/xpp.mk

include $(XPPDIR)/xpp/$(PLATFORM)/export.mk
include $(XPPDIR)/comm/$(PLATFORM)/export.mk
#include $(XPPDIR)/xlatexpp/$(PLATFORM)/export.mk

OTHER = convert gchooks primtab primval stepper thunk
SET_PLUS = set tabtool
SPACE1 = cross edge filter hspace 
SPACE2 = integer point real sequenc space
SPACE = $(SPACE1) $(SPACE2)
TABLE = hashtab inttab tabent tables array twaldo wimptab
MORE_MISC = reactor xmodel settab

NO_SPACES = $(OTHER) $(SET_PLUS)
SPACE_STUFF = $(SPACE) $(TABLE) $(MORE_MISC)

NO_SPACESX_O = $(NO_SPACES:%=%x.obj)
SPACE_STUFFX_O = $(SPACE_STUFF:%=%x.obj)

PACKAGET   = pkgcore pkgstub pkgapp
PACKAGET_O = $(PACKAGET:%=%x.obj)

LIBST1_O = $(XPPLIBX_O)
LIBST2_O = $(COMMLIBX_O) xxpplibx.lib spclibx.lib testerx.obj
LIBST3_O = rcmainx.obj $(MAINX_O)
LIBST_O  = $(LIBST1_O) $(LIBST2_O) $(LIBST3_O)


WORKING_TESTS1 = tester inttab hashtab integer
WORKING_TESTS2 = become set tabent settab  # package

TESTSD_TXT = $(WORKING_TESTS1:%=%.dif) $(WORKING_TESTS2:%=%.dif) 

TESTS1_O = $(WORKING_TESTS1:%=%t.obj)
TESTS2_O = $(WORKING_TESTS2:%=%t.obj) spacet.obj
TESTS_O = $(TESTS1_O) $(TESTS2_O)

default : spclibx.lib xxpplibx.lib rcmainx.obj

libs : default

all : spclibx.lib xxpplibx.lib tests

tests : $(TESTSD_TXT)

spclibx.lib : $(SPACE_STUFFX_O)
	echo $@ $(LIBFLAGS) -r > c:\tmp\_lib.lbc
	echo $(SPACE1:%=%x.obj) >> c:\tmp\_lib.lbc
	echo $(SPACE2:%=%x.obj) >> c:\tmp\_lib.lbc
	echo $(TABLE:%=%x.obj) >> c:\tmp\_lib.lbc
	echo $(MORE_MISC:%=%x.obj) >> c:\tmp\_lib.lbc
	$(LIB) @c:/tmp/_lib.lbc

xxpplibx.lib : $(NO_SPACESX_O)
	echo $@ $(LIBFLAGS) -r > c:\tmp\_lib.lbc
	echo $(OTHER:%=%x.obj) >> c:\tmp\_lib.lbc
	echo $(SET_PLUS:%=%x.obj) >> c:\tmp\_lib.lbc
	$(LIB) @c:/tmp/_lib.lbc

xlatestt.exp : $(TESTS_O) $(LIBST_O) # $(PACKAGET_O)
	echo -o $@ > c:\tmp\_link
	echo $(TESTS1_O) >> c:\tmp\_link
	echo $(TESTS2_O) >> c:\tmp\_link
	echo $(LIBST1_O) >> c:\tmp\_link
	echo $(LIBST2_O) >> c:\tmp\_link
	echo $(LIBST3_O) >> c:\tmp\_link
	$(LINK.cxx) @c:/tmp/_link.

tester.out:  xlatestt.exp ../tester.rc
inttab.out:  xlatestt.exp ../inttab.rc
hashtab.out: xlatestt.exp ../hashtab.rc
integer.out: xlatestt.exp ../integer.rc
become.out:  xlatestt.exp ../become.rc
set.out:     xlatestt.exp ../set.rc
package.out: xlatestt.exp ../package.rc
tabent.out:  xlatestt.exp ../tabent.rc
settab.out:  xlatestt.exp ../settab.rc
sequenc.out: xlatestt.exp ../sequence.rc

%.out: ../%.rc
	sh -c "run386 ./xlatestt.exp $< 1>&2 2> $@"


include depends.mk
