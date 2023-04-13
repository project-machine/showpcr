# ShowPCR

This program will print out the PCR values while in the EFI shell.

By default this program will output PCR7 as a SHA256 digest with no options, use options below to specify PCR and hash algorithm.

Usage: ShowPCR.efi [-all] [--pcr] [n] digest_algorithm

--all : Shows all PCR values from 0-23

--pcr : pick an individual PCR value to output

## Releases

It is recommended to fetch the latest release from github, rather
than build your own.

## Build instructions

## Prerequisites

Use apt to get the following packages
```
sudo apt-get install build-essential git uuid-dev iasl nasm
```

### Preparing EDK2

1) Clone EDK2 into your favorite location and cd into it, I prefer my home directory

```
git clone https://github.com/tianocore/edk2.git && cd edk2
```

2) Clone submodules, make EDK2, and then setup 

```
git submodule update --init
make -C BaseTools
source edksetup.sh
```
3) We now must now configure our build settings, using your favorite text editor navigate Conf/target

On line 44 Set:
```
TARGET_ARCH           = X64
```

...then on line 54 set:
```
TOOL_CHAIN_TAG        = GCC5
```

Congrats! Your EDK2 setup is now complete, now on to building ShowPCR!

## Build ShowPCR

1) Prep our build enviornment variables 
```
export EDK_TOOLS_PATH=<edk2_root>/BaseTools
source edksetup.sh BaseTools
```
2) Navigate to the following and clone ShowPCR
```
cd <edk2 root>/EmulatorPkg/Application
git clone https://aci-github.cisco.com/atom/showpcr
```
3) Add our inf file to the Package Interface using your favorite text editor:
```
<edk2_root>/EmulatorPkg/EmulatorPkg.dsc
```
Just past the "Entry Point" section of Libaray Classes add the following

```
ShellCEntryLib|ShellPkg/Library/UefiShellCEntryLib/UefiShellCEntryLib.inf
```
and after the "LibraryClasses" section (ln 416) add the following:
```
EmulatorPkg/Application/showpcr/showpcr.inf
```


...and finally run the command
```
build
```

showpcr will now be located in <edk2_root>/Build/EmulatorX64/DEBUG_GCC5/X64/showpcr.efi

