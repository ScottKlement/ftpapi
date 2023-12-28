.SECONDARY:
.PRECIOUS:

.SECONDEXPANSION:
.ONESHELL:
SHELL = /usr/bin/qsh
.SHELLFLAGS = -ec

VERSION        := 2.6
COPYRIGHT      := Version $(VERSION). Copyright 2001-2023 Scott C. Klement.
LIBRARY				 ?= LIBFTPX
PKGLIB				 ?= LIBFTPXPKG
TGTRLS         ?= v7r1m0
BUILD_EXAMPLES ?= 1
DEBUG					 ?= 1

ifneq (,$(BUILDLIB))
LIBRARY=$(BUILDLIB)
endif

# Make sure LIBRARY has been set and doesn't have any blanks
ifneq (1,$(words [$(LIBRARY)]))
$(error LIBRARY variable is not set correctly. Set to a valid library name and try again)
endif
ifeq (,$(LIBRARY))
$(error LIBRARY variable is not set correctly. Set to a valid library name and try again)
endif

ILIBRARY      := /qsys.lib/$(LIBRARY).lib
IPKGLIB       := /qsys.lib/$(PKGLIB).lib
RPGINCDIR     := 'src/rpg'
RPGINCDIR     := incdir($(RPGINCDIR))
CINCDIR       := 'src' 'src/expat' 
CINCDIR       := incdir($(CINCDIR))
BNDDIR        :=
C_OPTS				:= localetype(*localeucs2) sysifcopt(*ifsio) define(HAVE_EXPAT_CONFIG_H)
CL_OPTS       :=
RPG_OPTS      := option(*noseclvl)
PGM_OPTS      :=
OWNER         := qpgmr
USRPRF        := *user
BNDSRVPGM			:=
PGM_ACTGRP		:= FTPAPI
SRVPGM_ACTGRP := *caller

SETLIBLIST    := liblist | grep ' USR' | while read lib type; do liblist -d $$lib; done; liblist -a $(LIBRARY)
TMPSRC        := tmpsrc
ISRCFILE      := $(ILIBRARY)/$(TMPSRC).file
SRCFILE       := srcfile($(LIBRARY)/$(TMPSRC)) srcmbr($(TMPSRC))
SRCFILE2      := $(LIBRARY)/$(TMPSRC)($(TMPSRC))
SRCFILE3      := file($(LIBRARY)/$(TMPSRC)) mbr($(TMPSRC))
PRDLIB        := $(LIBRARY)
TGTCCSID      := *job
DEVELOPER     ?= $(USER)
MAKE          := make
LOGFILE       = $(CURDIR)/tmp/$(@F).txt
OUTPUT        = >$(LOGFILE) 2>&1

# Remove compile listings from previous `make`
$(shell test -d $(CURDIR)/tmp || mkdir $(CURDIR)/tmp; rm $(CURDIR)/tmp/*.txt >/dev/null 2>&1)

#
# Set variables for adding in a debugging view if desired
#

ifeq ($(DEBUG), 1)
	DEBUG_OPTS     := dbgview(*all)
	SQL_DEBUG_OPTS := dbgview(*source)
	CPP_OPTS       := $(CPP_OPTS) output(*print)
else
	DEBUG_OPTS     := dbgview(*none)
	SQL_DEBUG_OPTS := dbgview(*none)
	CPP_OPTS       := $(CPP_OPTS) optimize(40) output(*none)
	RPG_OPTS       := $(RPG_OPTS) optimize(*full)
endif

define EXAMPLES
	TESTAPP.pgm TESTGET.pgm TESTMGET.pgm TESTMIRIN.pgm TESTMIROUT.pgm TESTPUT.pgm TESTURL.pgm
	TESTXPROC.pgm TEST2SESS.pgm
  EX1PUT.pgm EX2APPEND.pgm EX3GET.pgm EX4MGET.pgm EX5XPROC.pgm EX6TREEFRM.pgm EX7TREETO.pgm	
endef	
EXAMPLES := $(addprefix $(ILIBRARY)/, $(EXAMPLES))

define FTP_OBJS
	FTPAPI.bnddir FTPAPIR4.srvpgm INSTALL.pgm
endef	
FTP_OBJS := $(addprefix $(ILIBRARY)/, $(FTP_OBJS))

define SRCF_OBJS
	QCLSRC.file QRPGLESRC.file QSRVSRC.file QSH.file
endef
SRCF_OBJS := $(addprefix $(ILIBRARY)/, $(SRCF_OBJS))

TARGETS := $(FTP_OBJS)
SRVPGMS := $(addprefix $(ILIBRARY)/, FTPAPIR4.srvpgm)

NTLM_OBJS := MD4R4.module ENCRYPTR4.module NTLMR4.module

FTPAPIR4.module_deps := src/rpg/VERSION.rpgleinc
FTPAPIR4.srvpgm_deps := $(addprefix $(ILIBRARY)/, FTPAPIR4.module)

.PHONY: all clean release

all: examples | $(ILIBRARY) 

ftp: $(ILIBRARY)/QRPGLESRC.file $(TARGETS)

examples: $(TARGETS) $(EXAMPLES)

clean:
	rm -rf $(ISRCFILE) $(EXAMPLES) $(FTP_OBJS) $(ILIBRARY)/*.MODULE
	rm -rf $(SRCF_OBJS) $(IPKGLIB)/FTPAPI.file build
	rm -f src/rpg/VERSION.rpgleinc

$(ILIBRARY): | tmp
	-system -v 'crtlib lib($(LIBRARY)) type(*PROD)'
	system -v "chgobjown obj($(LIBRARY)) objtype(*lib) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)) objtype(*lib) user(*public) aut(*use) replace(*yes)"

$(IPKGLIB):
	-system -v 'crtlib lib($(PKGLIB)) type(*PROD)'
	system -v "chgobjown obj($(PKGLIB)) objtype(*lib) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(PKGLIB)) objtype(*lib) user(*public) aut(*use) replace(*yes)"

$(ISRCFILE): | $(ILIBRARY)
	-system -v 'crtsrcpf rcdlen(250) $(SRCFILE3)'

tmp:
	mkdir $(CURDIR)/tmp	

#
#  Specific rules for objects that don't follow the "cookbook" rules, below.
#

src/rpg/VERSION.rpgleinc:
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -f '$(@)'
	touch -C 819 '$(@)'
	echo "     H COPYRIGHT('$(COPYRIGHT) +" >> '$(@)'
	echo "     H All rights reserved. A member called LICENSE was included +" >> '$(@)'
	echo "     H with this distribution and contains important license +" >> '$(@)'
	echo "     H information.')" >> '$(@)') $(OUTPUT)

$(ILIBRARY)/FTPAPI.bnddir: | $(ILIBRARY)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -rf '$(@)'
	system -v "crtbnddir bnddir($(LIBRARY)/$(basename $(@F)))"
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)"
	system -v "addbnddire bnddir($(LIBRARY)/$(basename $(@F))) obj((*libl/ftpapir4 *srvpgm))") $(OUTPUT)

$(ILIBRARY)/QRPGLESRC.file: src/rpg/VERSION.rpgleinc | $(ILIBRARY)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -f '$(@)'
	system -v 'crtsrcpf file($(LIBRARY)/$(basename $(@F))) rcdlen(112)'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)"
	for MBR in RECIO_H IFSIO_H FTPAPI_H SOCKET_H VERSION; do
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(rpgle)"; \
	  cat "src/rpg/$${MBR}.rpgleinc" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done
	for MBR in EX1PUT EX2APPEND EX3GET EX4MGET EX5XPROC EX6TREEFRM EX7TREETO \
						 TESTAPP TESTGET TESTMGET TESTMIRIN TESTMIROUT TESTPUT TESTURL TESTXPROC TEST2SESS \
						 FTPAPIR4; do
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(rpgle)"; \
	  cat "src/rpg/$${MBR}.rpgle" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done
	for MBR in README; do \
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(txt)"; \
	  cat "$${MBR}.md" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done
	for MBR in CHANGELOG; do \
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(txt)"; \
	  cat "$${MBR}.txt" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done
	for MBR in LICENSE; do \
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(txt)"; \
	  cat "src/rpg/$${MBR}.txt" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done) $(OUTPUT)

$(ILIBRARY)/QCLSRC.file: | $(ILIBRARY)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -f '$(@)'
	system -v 'crtsrcpf file($(LIBRARY)/$(basename $(@F))) rcdlen(92)'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)"
	for MBR in INSTALL PACKAGE; do
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(clle)"; \
	  cat "src/cl/$${MBR}.clle" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done
	for MBR in LICENSE; do
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(txt)"; \
	  cat "src/cl/$${MBR}.txt" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done) $(OUTPUT)
	
$(ILIBRARY)/QSRVSRC.file: | $(ILIBRARY)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -f '$(@)'
	system -v 'crtsrcpf file($(LIBRARY)/$(basename $(@F))) rcdlen(92)'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)"
	for MBR in FTPAPI_X; do
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(bnd)"; \
	  cat "src/srvsrc/$${MBR}.bnd" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done
	for MBR in LICENSE; do
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(txt)"; \
	  cat "src/srvsrc/$${MBR}.txt" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done) $(OUTPUT)

$(ILIBRARY)/QSH.file: | $(ILIBRARY)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -f '$(@)'
	system -v 'crtsrcpf file($(LIBRARY)/$(basename $(@F))) rcdlen(92)'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)"
	for MBR in MKZIP; do
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(txt)"; \
	  cat "src/sh/$${MBR}.sh" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done
	for MBR in LICENSE; do
	  system -v "addpfm file($(LIBRARY)/$(basename $(@F))) mbr($${MBR}) srctype(txt)"; \
	  cat "src/sh/$${MBR}.txt" | Rfile -wQ "$(LIBRARY)/$(basename $(@F))($${MBR})"; \
	done) $(OUTPUT)
			
$(ILIBRARY)/FTPAPIR4.srvpgm: src/srv/FTPAPI_X.bnd $(FTPAPIR4.srvpgm_deps) | $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -rf '$(@)'
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	$(SETLIBLIST)
	system -v 'dltsrvpgm srvpgm($(LIBRARY)/FTPAPIR4)' || true
	system -v 'crtsrvpgm srvpgm($(LIBRARY)/FTPAPIR4) module($(foreach MODULE, $(notdir $(filter %.module, $(^))), ($(LIBRARY)/$(basename $(MODULE))))) $(SRCFILE) $(PGM_OPTS) actgrp($(SRVPGM_ACTGRP)) tgtrls($(TGTRLS)) bndsrvpgm($(foreach SRVPGM, $(notdir $(filter %.srvpgm, $(^))), ($(basename $(SRVPGM))))) $($(@F)_opts) $(BNDDIR) usrprf($(USRPRF))'
	system -v "chgobjown obj($(LIBRARY)/FTPAPIR4) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/FTPAPIR4) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)

#
#  Standard "cookbook" recipes for building objects
#
$(ILIBRARY)/%.module: src/cl/%.clle | $(ISRCFILE) $$($$*.module_files) $$($$*.module_spgms)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	system -v "crtclmod module($(LIBRARY)/$(*F)) $(SRCFILE) $(CL_OPTS) tgtrls($(TGTRLS)) $(DEBUG_OPTS)") $(OUTPUT)
	
$(ILIBRARY)/%.module: src/rpg/%.rpgle $$($$*.module_deps) | $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	system -v "crtrpgmod module($(LIBRARY)/$(*F)) $(SRCFILE) $(RPGINCDIR) $(RPG_OPTS) tgtrls($(TGTRLS)) $(DEBUG_OPTS)") $(OUTPUT)
	
$(ILIBRARY)/%.module: src/rpg/%.sqlrpgle $$($$*.module_deps) | $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	system -v "crtsqlrpgi obj($(LIBRARY)/$(*F)) $(SRCFILE) compileopt('$(subst ','',$(RPGINCDIR)) $(subst ','',$(RPG_OPTS))') $(SQL_OPTS) tgtrls($(TGTRLS)) $(SQL_DEBUG_OPTS) objtype(*module) rpgppopt(*lvl2)") $(OUTPUT)
	
$(ILIBRARY)/%.pnlgrp: src/pnlsrc/%.pnlgrp | $$($$*.pnlgrp_deps) $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	system -v "crtpnlgrp pnlgrp($(LIBRARY)/$(*F)) $(SRCFILE)"
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)

$(ILIBRARY)/%.cmd: src/cmdsrc/%.cmd $$($$*.cmd_deps) | $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	system -v 'crtcmd cmd($(LIBRARY)/$(*F)) $(SRCFILE) pgm(*libl/$(*F)) prdlib($(PRDLIB))'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)

$(ILIBRARY)/%.pgm: $$($$*.pgm_deps) $(ILIBRARY)/%.module | $(ILIBRARY) $(SRVPGMS)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	system -v 'dltpgm pgm($(LIBRARY)/$(*F))' || true
	system -v 'crtpgm pgm($(LIBRARY)/$(*F)) module($(foreach MODULE, $(notdir $(filter %.module, $(^))), ($(LIBRARY)/$(basename $(MODULE))))) entmod(*pgm) $(PGM_OPTS) actgrp($(PGM_ACTGRP)) tgtrls($(TGTRLS)) bndsrvpgm($(foreach SRVPGM, $(notdir $(filter %.srvpgm, $(|))), ($(basename $(SRVPGM))))) $(BNDDIR) $($(@F)_opts) usrprf($(USRPRF))'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)
			
$(ILIBRARY)/%.srvpgm: src/srv/%.bnd $$($$*.srvpgm_deps) | $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -rf '$(@)'
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	$(SETLIBLIST)
	system -v 'dltsrvpgm srvpgm($(LIBRARY)/$(*F))' || true
	system -v 'crtsrvpgm srvpgm($(LIBRARY)/$(*F)) module($(foreach MODULE, $(notdir $(filter %.module, $(^))), ($(LIBRARY)/$(basename $(MODULE))))) $(SRCFILE) $(PGM_OPTS) actgrp($(SRVPGM_ACTGRP)) tgtrls($(TGTRLS)) bndsrvpgm($(foreach SRVPGM, $(notdir $(filter %.srvpgm, $(^))), ($(basename $(SRVPGM))))) $($(@F)_opts) $(BNDDIR) usrprf($(USRPRF))'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)

$(ILIBRARY)/%.file: src/dds/%.dspf | $$($$*.file_deps) $(ISRCFILE)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -rf '$(@)'
	cat '$(<)' | Rfile -wQ '$(SRCFILE2)'
	$(SETLIBLIST)
	system -v 'crtdspf file($(LIBRARY)/$(*F)) $(SRCFILE)'
	system -v "chgobjown obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) newown($(OWNER)) curownaut(*revoke)"
	system -v "grtobjaut obj($(LIBRARY)/$(basename $(@F))) objtype(*$(subst .,,$(suffix $(@F)))) user(*public) aut(*use) replace(*yes)") $(OUTPUT)

$(IPKGLIB)/FTPAPI.file: all $(SRCF_OBJS) membertext | $(IPKGLIB)
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -rf $(ISRCFILE) $(ILIBRARY)/EVFEVENT.file $(ILIBRARY)/*.MODULE
	system -v 'dltf file($(PKGLIB)/FTPAPI)' || true
	system -v 'crtsavf file($(PKGLIB)/FTPAPI)'
	system -v 'savlib lib($(LIBRARY)) dev(*savf) savf($(PKGLIB)/FTPAPI) tgtrls($(TGTRLS)) DTACPR(*HIGH)') $(OUTPUT)

build:
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	(rm -rf build
	mkdir build) $(OUTPUT)

membertext: $(SRCF_OBJS) | $(ILIBRARY)
	@$(info Setting member text descriptions)touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	while read FILE MBR TEXT; do \
		system -v "chgpfm file($(LIBRARY)/$${FILE}) mbr($${MBR}) text('$${TEXT}')"; \
	done < src/sh/member_text.txt) $(OUTPUT)

build/ftpapi.zip: $(SRCF_OBJS) membertext | build
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	system -v 'dltf file($(PKGLIB)/WORK)' || true
	system -v 'crtpf file($(PKGLIB)/WORK) rcdlen(256)'	
	src/sh/MKZIP.sh "$(LIBRARY)" "$(CURDIR)") $(OUTPUT)

build/ftpapi.savf: $(IPKGLIB)/FTPAPI.file | build
	@$(info Creating $(@))touch -C 1208 $(LOGFILE)
	($(SETLIBLIST)
	system -v " CPYTOSTMF FROMMBR('$(IPKGLIB)/FTPAPI.file') TOSTMF('build/ftpapi.savf') STMFOPT(*REPLACE) CVTDTA(*NONE)"
	chmod 644 build/ftpapi.savf) $(OUTPUT)

package: clean build/ftpapi.savf build/ftpapi.zip