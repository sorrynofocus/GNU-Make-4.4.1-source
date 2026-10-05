# GNU -*-Makefile-*- to build GNU Make on 64-bit Windows
#
# Modified 2026 by sorrynofocus
# Added explicit Windows x64 build support.
#
# This file remains licensed under the GNU General Public License,
# version 3 or any later version.
#
# Windows x64 overrides for use with Basic.mk.
#
# Select with: make -f Basic.mk MAKE_HOST=Windows64
#
# For MSVC this file intentionally requires an x64-targeting Visual Studio
# developer environment. The compiler architecture is selected by the MSVC
# toolchain environment, not by a C compiler flag. /MACHINE:X64 is also
# passed to the linker as a fail-fast architecture check.
#
# Copyright (C) 2017-2023 Free Software Foundation, Inc.
# This file is part of GNU Make.
#
# GNU Make is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# GNU Make is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <https://www.gnu.org/licenses/>.

# TARGET_TYPE can be either "release" or "debug"
TARGET_TYPE = release

# TOOLCHAIN can be either "msvc" or "gcc"
TOOLCHAIN = msvc

# cl.exe does not have a switch that changes an x86 compiler into an x64
# compiler. Require the x64 Visual Studio target environment when using MSVC.
# The "x64 Native Tools Command Prompt for VS 2022" sets this automatically.
ifeq ($(TOOLCHAIN),msvc)
ifeq ($(filter x64 amd64,$(VSCMD_ARG_TGT_ARCH)),)
$(error Windows64.mk requires an x64 MSVC target environment; VSCMD_ARG_TGT_ARCH='$(VSCMD_ARG_TGT_ARCH)')
endif
endif

# Translate a POSIX path into a Windows path.  Don't bother with drives.
# Used only inside recipes, with DOS/CMD tools that require it.
P2W = $(subst /,\,$1)

prog_SOURCES += $(loadavg_SOURCES) $(glob_SOURCES) $(w32_SOURCES)

BUILT_SOURCES += $(lib)alloca.h $(lib)fnmatch.h $(lib)glob.h

w32_LIBS = kernel32 user32 gdi32 winspool comdlg32 advapi32 shell32 ole32 \
	   oleaut32 uuid odbc32 odbccp32

CPPFLAGS =
CFLAGS =
LDFLAGS =

# --- Visual Studio
msvc_CC = cl.exe
msvc_LD = link.exe

msvc_CPPFLAGS = /DHAVE_CONFIG_H /DWINDOWS32 /DWIN32 /D_CONSOLE
msvc_CPPFLAGS += /I$(OUTDIR)src /I$(SRCDIR)/src /I$(SRCDIR)/src/w32/include /I$(OUTDIR)lib /I$(SRCDIR)/lib

msvc_CFLAGS = /nologo /MT /W4 /EHsc
msvc_CFLAGS += /FR$(OUTDIR) /Fp$(BASE_PROG).pch /Fd$(BASE_PROG).pdb

msvc_LDFLAGS = /nologo /SUBSYSTEM:console /MACHINE:X64 /PDB:$(BASE_PROG).pdb

msvc_LDLIBS = $(addsuffix .lib,$(w32_LIBS))

msvc_C_SOURCE = /c
msvc_OUTPUT_OPTION = /Fo$@
msvc_LINK_OUTPUT = /OUT:$@

release_msvc_OUTDIR = ./Win64Rel/
release_msvc_CPPFLAGS = /D NDEBUG
release_msvc_CFLAGS = /O2

debug_msvc_OUTDIR = ./Win64Debug/
debug_msvc_CPPFLAGS = /D _DEBUG
debug_msvc_CFLAGS = /Zi /Od
debug_msvc_LDFLAGS = /DEBUG

# --- GCC
gcc_CC = gcc
gcc_LD = $(gcc_CC)

release_gcc_OUTDIR = ./Gcc64Rel/
debug_gcc_OUTDIR = ./Gcc64Debug/

gcc_CPPFLAGS = -DHAVE_CONFIG_H -I$(OUTDIR)src -I$(SRCDIR)/src -I$(SRCDIR)/src/w32/include -I$(OUTDIR)lib -I$(SRCDIR)/lib
gcc_CFLAGS = -m64 -mthreads -Wall -std=gnu99 -gdwarf-2 -g3
gcc_LDFLAGS = -m64 -mthreads -gdwarf-2 -g3
gcc_LDLIBS = $(addprefix -l,$(w32_libs))

gcc_C_SOURCE = -c
gcc_OUTPUT_OPTION = -o $@
gcc_LINK_OUTPUT = -o $@

debug_gcc_CFLAGS = -O0
release_gcc_CFLAGS = -O2

# ---

LINK.cmd = $(LD) $(extra_LDFLAGS) $(LDFLAGS) $(TARGET_ARCH) $1 $(LDLIBS) $(LINK_OUTPUT)

CHECK.cmd = cmd /c cd tests \& .\run_make_tests.bat -make ../$(PROG)

MKDIR.cmd = cmd /c mkdir $(call P2W,$1)
RM.cmd = cmd /c del /F /Q $(call P2W,$1)
CP.cmd = cmd /c copy /Y $(call P2W,$1 $2)

CC = $($(TOOLCHAIN)_CC)
LD = $($(TOOLCHAIN)_LD)

C_SOURCE = $($(TOOLCHAIN)_C_SOURCE)
OUTPUT_OPTION = $($(TOOLCHAIN)_OUTPUT_OPTION)
LINK_OUTPUT = $($(TOOLCHAIN)_LINK_OUTPUT)

OUTDIR = $($(TARGET_TYPE)_$(TOOLCHAIN)_OUTDIR)

OBJEXT	= obj
EXEEXT	= .exe

_CUSTOM = $($(TOOLCHAIN)_$1) $($(TARGET_TYPE)_$1) $($(TARGET_TYPE)_$(TOOLCHAIN)_$1)

# Build the executable as make.exe.
PROG = $(OUTDIR)make$(EXEEXT)
BASE_PROG = $(basename $(PROG))

extra_CPPFLAGS = $(call _CUSTOM,CPPFLAGS)
extra_CFLAGS = $(call _CUSTOM,CFLAGS)
extra_LDFLAGS = $(call _CUSTOM,LDFLAGS)
LDLIBS = $(call _CUSTOM,LDLIBS)

$(OUTDIR)src/config.h: $(SRCDIR)/src/config.h.W32
	$(call CP.cmd,$<,$@)
