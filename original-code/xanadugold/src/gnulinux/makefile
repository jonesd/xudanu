#
#  global makefile for xanadu
#
#	$Id: makefile,v 1.16 1993/03/16 23:39:17 hibbert Exp $
#

XPPDIR = ..
PLATFORM = gnulinux
EXTRASTUBBLEDEPENDS = $(XPPDIR)/stubble/copy.hf

include $(XPPDIR)/xpp/$(PLATFORM)/xpp.mk

default: most

most:	some febeexe

all:	most

some:	xpp xlatexpp comm server disk urdi

#
#  The tests rule is ordered so later tests need earlier ones to succeed.
#

test: tests

tests:
	cd ../xpp/gnulinux ; rm -f depends.mk ; xumake -k tests
	cd ../xlatexpp/gnulinux ; rm -f depends.mk ; xumake -k tests
	cd ../server/gnulinux ; rm -f depends.mk ; xumake -k tests
	cd ../urdi/gnulinux ; rm -f depends.mk ; xumake -k tests

febeexe: FORCE
	cd ../server/gnulinux ; make -k febet.exe

xpptests: FORCE
	cd ../xpp/gnulinux ; rm -f depends.mk ; xumake -k tests
	cd ../xlatexpp/gnulinux ; rm -f depends.mk ; xumake -k tests

xpp: FORCE
	cd ../xpp/gnulinux ; xumake -k libs

xlatexpp: FORCE
	cd ../xlatexpp/gnulinux ;xumake -k libs

# only test in server presently (9-8-1990), grantabt, doesn't run automatically
server: FORCE
	cd ../server/gnulinux ;  xumake -k libs

urdi: FORCE
	cd ../urdi/gnulinux ;  xumake -k libs

disk: FORCE
	cd ../disk/gnulinux ;  xumake -k libs

comm: FORCE
	cd ../comm/gnulinux ;  xumake -k libs

alldepends:
	cd ../xpp/gnulinux ; xumake depends
	cd ../xlatexpp/gnulinux ; xumake depends
	cd ../server/gnulinux ; xumake depends
	cd ../disk/gnulinux ; xumake depends
	cd ../comm/gnulinux ; xumake depends
	cd ../urdi/gnulinux ; xumake depends

allsxx:
	cd ../xpp/gnulinux ; rm -f depends.mk ; xumake sxx
	cd ../xlatexpp/gnulinux ; rm -f depends.mk ; xumake sxx
	cd ../server/gnulinux ; rm -f depends.mk ; xumake sxx
	cd ../disk/gnulinux ; rm -f depends.mk ; xumake sxx
	cd ../comm/gnulinux ; rm -f depends.mk ; xumake sxx
	cd ../urdi/gnulinux ; rm -f depends.mk ; xumake -k sxx

sxx:
	cd ../xpp/gnulinux ; xumake sxx
	cd ../xlatexpp/gnulinux ; xumake sxx
	cd ../server/gnulinux ; xumake sxx
	cd ../disk/gnulinux ; xumake sxx
	cd ../comm/gnulinux ; xumake sxx
	cd ../urdi/gnulinux ; xumake -k sxx

clean-alpha:
	cd ../xpp/gnulinux ; xumake clean
	cd ../xlatexpp/gnulinux ; xumake clean
	cd ../server/gnulinux ; xumake clean
	cd ../disk/gnulinux ; xumake clean
	cd ../comm/gnulinux ; xumake clean
	cd ../urdi/gnulinux ; xumake clean

virgin-alpha:
	cd ../xpp/gnulinux ; xumake virgin
	cd ../xlatexpp/gnulinux ; xumake virgin
	cd ../server/gnulinux ; xumake virgin
	cd ../disk/gnulinux ; xumake virgin
	cd ../comm/gnulinux ; xumake virgin
	cd ../urdi/gnulinux ; xumake virgin

newborn-alpha:
	cd ../xpp/gnulinux ; xumake virgin
	cd ../xlatexpp/gnulinux ; xumake newborn
	cd ../server/gnulinux ; xumake newborn
	cd ../disk/gnulinux ; xumake newborn
	cd ../comm/gnulinux ; xumake newborn
	cd ../urdi/gnulinux ; xumake virgin

# these are useful to keep track of things that change across a particular
# compile or fileout from smalltalk

timemarks:
	touch ../xpp/gnulinux/%mark
	touch ../xlatexpp/gnulinux/%mark
	touch ../server/gnulinux/%mark
	touch ../disk/gnulinux/%mark
	touch ../comm/gnulinux/%mark

removemarks:
	rm ../xpp/gnulinux/%mark
	rm ../xlatexpp/gnulinux/%mark
	rm ../server/gnulinux/%mark
	rm ../disk/gnulinux/%mark
	rm ../comm/gnulinux/%mark
