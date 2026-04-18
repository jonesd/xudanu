#
#  global makefile for xanadu
#
#	$Id: makefile,v 1.16 1993/03/16 23:39:17 hibbert Exp $
#

XPPDIR = ..

EXTRASTUBBLEDEPENDS = $(XPPDIR)/stubble/copy.hf

include $(XPPDIR)/xpp/$(PLATFORM)/xpp.mk

#default: allsxx most
default: febeexe

most:	some febeexe

all:	most

some:	xpp xlatexpp comm server disk urdi

#
#  The tests rule is ordered so later tests need earlier ones to succeed.
#

test: tests

tests:
	cd ../xpp/sun ; rm -f depends.mk ; xumake -k tests
	cd ../xlatexpp/sun ; rm -f depends.mk ; xumake -k tests
	cd ../server/sun ; rm -f depends.mk ; xumake -k tests
	cd ../urdi/sun ; rm -f depends.mk ; xumake -k tests

febeexe: FORCE
	cd ../server/sun ; make -k febet.exe

xpptests: FORCE
	cd ../xpp/sun ; rm -f depends.mk ; xumake -k tests
	cd ../xlatexpp/sun ; rm -f depends.mk ; xumake -k tests

xpp: FORCE
	cd ../xpp/sun ; rm -f depends.mk ; xumake -k libs

xlatexpp: FORCE
	cd ../xlatexpp/sun ; rm -f depends.mk ; xumake -k libs

# only test in server presently (9-8-1990), grantabt, doesn't run automatically
server: FORCE
	cd ../server/sun ; rm -f depends.mk ; xumake -k libs

urdi: FORCE
	cd ../urdi/sun ; rm -f depends.mk ; xumake -k libs

disk: FORCE
	cd ../disk/sun ; rm -f depends.mk ; xumake -k libs

comm: FORCE
	cd ../comm/sun ; rm -f depends.mk ; xumake -k libs

alldepends:
	cd ../xpp/sun ; xumake depends
	cd ../xlatexpp/sun ; xumake depends
	cd ../server/sun ; xumake depends
	cd ../disk/sun ; xumake depends
	cd ../comm/sun ; xumake depends
	cd ../urdi/sun ; xumake depends

allsxx:
	cd ../xpp/sun ; rm -f depends.mk ; xumake sxx
	cd ../xlatexpp/sun ; rm -f depends.mk ; xumake sxx
	cd ../server/sun ; rm -f depends.mk ; xumake sxx
	cd ../disk/sun ; rm -f depends.mk ; xumake sxx
	cd ../comm/sun ; rm -f depends.mk ; xumake sxx
	cd ../urdi/sun ; rm -f depends.mk ; xumake sxx

sxx:
	cd ../xpp/sun ; xumake sxx
	cd ../xlatexpp/sun ; xumake sxx
	cd ../server/sun ; xumake sxx
	cd ../disk/sun ; xumake sxx
	cd ../comm/sun ; xumake sxx
	cd ../urdi/sun ; xumake sxx

clean-alpha:
	cd ../xpp/sun ; xumake clean
	cd ../xlatexpp/sun ; xumake clean
	cd ../server/sun ; xumake clean
	cd ../disk/sun ; xumake clean
	cd ../comm/sun ; xumake clean
	cd ../urdi/sun ; xumake clean

virgin-alpha:
	cd ../xpp/sun ; xumake virgin
	cd ../xlatexpp/sun ; xumake virgin
	cd ../server/sun ; xumake virgin
	cd ../disk/sun ; xumake virgin
	cd ../comm/sun ; xumake virgin
	cd ../urdi/sun ; xumake virgin

newborn-alpha:
	cd ../xpp/sun ; xumake virgin
	cd ../xlatexpp/sun ; xumake newborn
	cd ../server/sun ; xumake newborn
	cd ../disk/sun ; xumake newborn
	cd ../comm/sun ; xumake newborn
	cd ../urdi/sun ; xumake virgin

# these are useful to keep track of things that change across a particular
# compile or fileout from smalltalk

timemarks:
	touch ../xpp/sun/%mark
	touch ../xlatexpp/sun/%mark
	touch ../server/sun/%mark
	touch ../disk/sun/%mark
	touch ../comm/sun/%mark

removemarks:
	rm ../xpp/sun/%mark
	rm ../xlatexpp/sun/%mark
	rm ../server/sun/%mark
	rm ../disk/sun/%mark
	rm ../comm/sun/%mark
