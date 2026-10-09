# Building The Choicer Voicer for Old 3DS on Windows

This source tree includes a Windows double-click build script for the native Old 3DS target.

## 1. Install devkitPro for Windows

Install the official devkitPro Windows environment and install the **3DS development tools (`3ds-dev`)**. The official Windows installer installs an MSYS2 environment under the devkitPro directory; the installer source uses the `msys2\usr\bin\bash.exe` layout.

The normal/default installation location is:

```text
C:\devkitPro\
```

The native project expects these components:

```text
C:\devkitPro\devkitARM\
C:\devkitPro\libctru\
C:\devkitPro\msys2\
```

The devkitPro 3DS rules set `CTRULIB` to the libctru installation, and the standard 3DS example Makefiles use `DEVKITARM\3ds_rules` in the same way as this project.

## 2. Build by double-clicking

Open this folder:

```text
The Choicer Voicer\
```

Double-click:

```text
build_windows.bat
```

The script automatically finds the default `C:\devkitPro` installation, launches the included MSYS2 Bash shell, and invokes the native `3ds_port\Makefile`.

## 3. Build output

On success, the native 3DSX is created in:

```text
The Choicer Voicer\3ds_port\TheChoicerVoicer3DS.3dsx
```

The SMDH metadata file is also generated when the build rules create it:

```text
The Choicer Voicer\3ds_port\TheChoicerVoicer3DS.smdh
```

## 4. Clean the build

Double-click:

```text
clean_windows.bat
```

## 5. Manual build from an MSYS2/devkitPro shell

The same build can be run manually:

```bash
cd '/path/to/The Choicer Voicer/3ds_port'
make -j2
```

The `Makefile` follows the official devkitPro 3DS project structure (`DEVKITARM/3ds_rules`, `armv6k`, `3dsx.specs`, `libctru`).

## 6. Why this uses Bash on Windows

The official devkitPro 3DS rules are GNU Make/Unix-style build rules. Using the MSYS2 shell shipped with the official Windows environment makes those rules work from a normal Windows PC without requiring the user to install a separate Unix environment.

### Convenience launcher

`BUILD-3DS-WINDOWS.bat` is also included at the project root and simply starts the same build script.
