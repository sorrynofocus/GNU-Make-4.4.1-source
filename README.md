# Building GNU Make 4.4.1 on Windows 

**NOTE: This is an UNOFFICIAL source/build of GNU Make.**

_This build was created for personal use and shared freely. It is not an official GNU Make release and is not affiliated with or supported by the GNU Project._

This repository contains a modified GNU Make 4.4.1 source tree for native Windows 64-bit builds. This README are notes taken to reproduce the build. 

## Prerequisites

* Visual Studio 2022 and above
* (optional) GNU make 3.1x 

Version location: `src\mkconfig.h`

## TL;DR

For the impatient:

* Open the **x64 Native Tools Command Prompt for VS 2022** from Start menu. Or run `%comspec% /k "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"`
* Verify env var is `VSCMD_ARG_TGT_ARCH=x64` after opening the vcvars64 developer BATch.
* Use an included or existing `make.exe` to build with (I had STM32 and make 3.1x):

  ```cmd
  make.exe -f Basic.mk MAKE_HOST=Windows64
  ```
* The custom `mk\Windows64.mk` forces an x64 build and outputs:

  ```text
  Win64Rel\make.exe
  ```
* Verify the result with:

  ```cmd
  dumpbin /headers Win64Rel\make.exe | findstr machine
  ```
* A correct 64-bit build reports:

  ```text
  8664 machine (x64)
  ```
* `Built for Windows32` in `make --version` does not necessarily mean the executable is 32-bit. That text comes from GNU Make's Windows configuration and is separate from the PE architecture.

* To clean:

  ```cmd
  make -f Basic.mk MAKE_HOST=Windows64 clean
  ```


## Build, in Detail

The original goal was to use GNU Make on Windows without depending on the copy bundled with STM32CubeIDE. That bundled executable worked for normal Makefiles, but it couldn't bootstrap the upstream GNU Make source correctly with `Basic.mk`.

The source used here is GNU Make 4.4.1:

```text
https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz
```

The build process below covers both the normal Windows build and the explicit `Windows64` build configuration added to this source tree.

## Requirements

This build uses Microsoft Visual C++ from Visual Studio 2022 Enterprise edition.

Open from Start Menu:

```text
x64 Native Tools Command Prompt for VS 2022
```

Or initialize the same environment manually:

```cmd
%comspec% /k "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
```

_Note: This version of VS is 2022\Enterprise, so yours may be Professional or Community. Change accordingly._

Verify that the prompt is configured for x64:

```cmd
set VSCMD_ARG
```

Expected values include:

```text
VSCMD_ARG_app_plat=Desktop
VSCMD_ARG_HOST_ARCH=x64
VSCMD_ARG_TGT_ARCH=x64
```

Also verify which compiler is being used:

```cmd
where cl
```

For an x64 build, the path should contain:

```text
Hostx64\x64
```

For example:

```text
C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe
```

## Source Changes

Two existing files were changed so the generated executable is named `make.exe` instead of `gnumake.exe`.

### `mk\Windows32.mk`

Change the program name from:

```make
PROG = $(OUTDIR)gnumake$(EXEEXT)
```

to:

```make
PROG = $(OUTDIR)make$(EXEEXT)
```

The modified file keeps the original line commented for reference:

```make
#PROG = $(OUTDIR)gnumake$(EXEEXT)
PROG = $(OUTDIR)make$(EXEEXT)
```

### `build_w32.bat`

Change:

```batch
set MAKE=gnumake
```

to:

```batch
set MAKE=make
```

## Standard Windows Bootstrap

If GNU Make is not already installed, the simplest bootstrap path is the supplied Windows build script:

```cmd
build_w32.bat --without-guile
```

`--without-guile` builds GNU Make without the optional GNU Guile integration.

## Bootstrapping with an Existing Make

I already had a copy of GNU Make bundled with STM32CubeIDE:

```text
C:\ST\STM32CubeIDE_2.2.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.make.win32_2.2.200.202604021615\tools\bin\make.exe
```

My first attempt was:

```cmd
"C:\ST\STM32CubeIDE_2.2.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.make.win32_2.2.200.202604021615\tools\bin\make.exe" -f Basic.mk
```

That failed with:

```text
make: *** No rule to make target 'src/config.h', needed by 'src/ar.o'.  Stop.
```

The reason is the host identity reported by the STM32 build of GNU Make.

It reports:

```text
Built for x86_64-w64-mingw32
```

`Basic.mk` selects a platform-specific file using the final component of `MAKE_HOST`:

```make
include $(firstword $(wildcard $(SRCDIR)/mk/$(lastword $(subst -, ,$(MAKE_HOST)).mk)))
```

For the STM32 build, the final component is `mingw32`, so `Basic.mk` does not automatically select:

```text
mk\Windows32.mk
```

Without the Windows overrides, the build falls back to generic settings and starts looking for files such as:

```text
src\config.h
src\ar.o
```

instead of using the Windows build layout.

## Windows64 Build

This repository adds:

```text
mk\Windows64.mk
```

It is based on `Windows32.mk` but makes the 64-bit build explicit.

The important differences are:

- MSVC requires `VSCMD_ARG_TGT_ARCH=x64`.
- The linker receives `/MACHINE:X64`.
- MSVC release output goes to `Win64Rel\`.
- MSVC debug output goes to `Win64Debug\`.
- GCC builds use `-m64`.
- GCC release output goes to `Gcc64Rel\`.
- GCC debug output goes to `Gcc64Debug\`.
- The generated executable remains `make.exe`.
- The existing `/DWINDOWS32` and `/DWIN32` definitions are retained because they select GNU Make's Windows implementation. They do not select a 32-bit CPU architecture.

No change to `Basic.mk` is required.

With:

```cmd
MAKE_HOST=Windows64
```

the existing platform-selection expression resolves to:

```text
mk\Windows64.mk
```

The relevant source tree looks like this:

```text
make-4.4.1\
    Basic.mk
    build_w32.bat
    mk\
        Windows32.mk
        Windows64.mk
```

## Build the 64-bit Version

First confirm the Visual Studio environment is targeting x64:

```cmd
set VSCMD_ARG_TGT_ARCH
```

Expected:

```text
VSCMD_ARG_TGT_ARCH=x64
```

Then run the build from the GNU Make source root.

If an existing `make.exe` is available:

dry-run it first:

```cmd
make.exe -n -f Basic.mk MAKE_HOST=Windows64
```

This is useful when checking compiler flags, output paths, and platform selection before starting the actual build.

Build actual:
```cmd
make.exe -f Basic.mk MAKE_HOST=Windows64
```

If using the STM32 copy directly:

```cmd
"C:\ST\STM32CubeIDE_2.2.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.make.win32_2.2.200.202604021615\tools\bin\make.exe" -f Basic.mk MAKE_HOST=Windows64 TOOLCHAIN=msvc
```

The MSVC release build is written to:

```text
Win64Rel\make.exe
```

To clean:

```cmd
make -f Basic.mk MAKE_HOST=Windows64 clean
```

## Verify the Build

Check the GNU Make version:

```cmd
Win64Rel\make.exe --version
```

A build may still report:

```text
Built for Windows32
```

because the upstream Windows configuration header contains:

```c
#define MAKE_HOST "Windows32"
```

That string is separate from the PE executable architecture.

To verify the actual executable bitness, use `dumpbin`:

```cmd
dumpbin /headers Win64Rel\make.exe | findstr machine
```

A 64-bit build should report:

```text
8664 machine (x64)
```

A 32-bit build reports:

```text
14C machine (x86)
```

For architecture verification, `dumpbin` is what you want to check with.

## How `Basic.mk` Uses Automatic Variables

The GNU Make source itself contains useful examples of Make automatic variables.

The final program is linked with:

```make
$(PROG): $(OBJECTS)
	$(call LINK.cmd,$^)
```

Here:

```text
$^
```

means ALL prerequisites, so all object files are passed to the linker.

Object files are compiled with:

```make
$(OBJECTS): $(OUTDIR)%.$(OBJEXT): %.c
	$(call COMPILE.cmd,$<)
```

Here:

```text
$<
```

means the first prerequisite, which is the source file corresponding to the object file being built.

In short:

```text
$@ = current target
$< = first prerequisite (for compile)
$^ = all prerequisites (for link)
```

## Notes

`WINDOWS32` and `WIN32` in the compiler definitions are historical Windows platform identifiers used by GNU Make's Windows-specific source code. I didn't need to change all that, nor had the time. This also does not determine whether the executable is x86 or x64. You can check bitness as mentioned above. 

The actual architecture is determined by the selected compiler toolchain and linker configuration. For the custom `Windows64.mk` build, MSVC is explicitly configured for x64 and the linker is given:

```text
/MACHINE:X64
```

## License

GNU Make is licensed under the GNU General Public License version 3 or later.

This repository contains a modified version of GNU Make 4.4.1 and is distributed under the same GPL-3.0-or-later terms.

See `COPYING` for the full license text.