# VibeChat

[![macOS](https://img.shields.io/badge/platform-macOS%2015.6+-black.svg)](https://apple.com)
[![Xcode](https://img.shields.io/badge/build-Xcode%20Native-blue.svg)](https://developer.apple.com/xcode/)
[![Architecture](https://img.shields.io/badge/arch-Apple%20Silicon%20%7C%20x86__64-orange.svg)]()
[![License](https://img.shields.io/badge/license-GPLv2%20%2B%20OpenSSL%20Exemption-green.svg)](vibe-hexchat/vibechat/hexchat/COPYING)

**VibeChat** is a modernized, native macOS port and optimization of the HexChat IRC client (version 2.16.2). Built specifically for contemporary macOS systems (Apple Silicon & Intel) using a native Xcode project configuration (`vibechat.xcodeproj`), Quartz-backed GTK+, and modern Homebrew libraries, VibeChat brings high-fidelity HiDPI Retina text rendering, clean warning-free compilation, native desktop notifications, and a streamlined footprint to classic IRC.

---

## Table of Contents

- [Required Libraries & Headers (Homebrew)](#required-libraries--headers-homebrew)
- [Compiling & Build Options](#compiling--build-options)
- [Additions & macOS Modernization](#additions--macos-modernization)
- [Complete Feature Set](#complete-feature-set)
- [Compile-Time Feature Flags (`config.h`)](#compile-time-feature-flags-configh)
- [Architecture & Repository Structure](#architecture--repository-structure)
- [Security Considerations & Hardening](#security-considerations--hardening)
- [License & Acknowledgements](#license--acknowledgements)

---

## Required Libraries & Headers (Homebrew)

Before building VibeChat, install all required libraries and development headers via [Homebrew](https://brew.sh) using the following command:

```bash
brew install gtk+ glib pango cairo gdk-pixbuf atk harfbuzz libcanberra enchant luajit dbus dbus-glib openssl@4 gettext perl iso-codes
```

### Package & Library Breakdown

| Homebrew Package | Linked Libraries (`OTHER_LDFLAGS`) | Header Search Paths (`HEADER_SEARCH_PATHS`) | Purpose |
| :--- | :--- | :--- | :--- |
| `gtk+` | `-lgtk-quartz-2.0`, `-lgdk-quartz-2.0` | `/opt/homebrew/include/gtk-2.0`, `/opt/homebrew/lib/gtk-2.0/include` | Native Quartz-backed GTK+ 2.x GUI toolkit |
| `glib` | `-lglib-2.0`, `-lgio-2.0`, `-lgobject-2.0`, `-lgmodule-2.0` | `/opt/homebrew/include/glib-2.0`, `/opt/homebrew/lib/glib-2.0/include` | Core data structures, main event loop, and GResource support |
| `pango` | `-lpango-1.0`, `-lpangocairo-1.0` | `/opt/homebrew/include/pango-1.0` | Internationalized text layout and font rendering engine |
| `cairo` | `-lcairo` | `/opt/homebrew/include/cairo` | 2D vector graphics library for HiDPI Retina subpixel text rendering |
| `gdk-pixbuf` | `-lgdk_pixbuf-2.0` | `/opt/homebrew/include/gdk-pixbuf-2.0` | Image loading and pixel buffer manipulation |
| `atk` | `-latk-1.0` | `/opt/homebrew/include/atk-1.0` | Accessibility toolkit for UI widgets |
| `harfbuzz` | *(Header & transitive Pango dependency)* | `/opt/homebrew/include/harfbuzz` | OpenType text shaping engine required by Pango/GTK+ |
| `gettext` | `-lintl` | `/opt/homebrew/opt/gettext/include` | GNU internationalization and localization (`libintl`) |
| `openssl@4` | `-lssl`, `-lcrypto` | `/opt/homebrew/opt/openssl@4/include`, `/opt/homebrew/opt/openssl/include` | SSL/TLS encryption for secure IRC connections, SNI, and CertFP |
| `libcanberra` | `-lcanberra` | `/opt/homebrew/opt/libcanberra/include` | XDG sound theme and audio event notifications |
| `enchant` | `-lenchant-2` | `/opt/homebrew/include/enchant-2`, `/opt/homebrew/opt/enchant/include` | Multilingual spell checking in the chat input bar |
| `dbus` | `-ldbus-1` | `/opt/homebrew/include/dbus-1.0`, `/opt/homebrew/lib/dbus-1.0/include` | D-Bus inter-process communication (IPC) message bus system |
| `dbus-glib` | `-ldbus-glib-1` | `/opt/homebrew/opt/dbus-glib/include/dbus-1.0` | GLib bindings for D-Bus remote command and automation support |
| `luajit` | `-lluajit-5.1` | `/opt/homebrew/include/luajit-2.1`, `/opt/homebrew/opt/luajit/include` | Just-In-Time compiler for Lua scripting and plugin support |
| `perl` | `-lperl` | `/opt/homebrew/opt/perl/lib/perl5/5.44/darwin-thread-multi-2level/CORE` | Perl 5 runtime library and headers for Perl scripting support |
| `iso-codes` | *(Runtime XML data)* | `/opt/homebrew/share/xml/iso-codes` | ISO 639/3166 language and country codes for spellcheck dictionaries |

In addition to Homebrew libraries, the project links against the native macOS system frameworks:
- `-framework Cocoa`
- `-framework CoreFoundation`
- `-framework ApplicationServices`

---

## Compiling & Build Options

### 1. Compiling in Xcode (GUI)

1. Open `vibechat.xcodeproj` in the root directory:
   ```bash
   open vibechat.xcodeproj
   ```
2. Select the **vibechat** scheme in the toolbar and set the run destination to **My Mac**.
3. Build or run:
   - **Build**: `Product > Build` (`Cmd + B`)
   - **Run**: `Product > Run` (`Cmd + R`)

### 2. Compiling via Command Line (`xcodebuild`)

You can compile VibeChat directly from the terminal using `xcodebuild`:

#### Release Build (Default — Optimized, Dead-Code Stripped, dSYM Enabled)
```bash
xcodebuild -project vibechat.xcodeproj -scheme vibechat -configuration Release build
```

#### Debug Build (Unoptimized `-O0`, `DEBUG=1`, Testability & Active Architecture Only)
```bash
xcodebuild -project vibechat.xcodeproj -scheme vibechat -configuration Debug build
```

#### Clean Build
```bash
xcodebuild -project vibechat.xcodeproj -scheme vibechat clean build
```

#### Custom Output Directory (`SYMROOT`)
```bash
xcodebuild -project vibechat.xcodeproj -scheme vibechat -configuration Release SYMROOT="$(pwd)/build" build
```
The compiled executable will be located at `build/Release/vibechat`.

### 3. Compiler & Linker Build Options

The Xcode project (`vibechat.xcodeproj/project.xcproj`) configures the following build settings:

| Setting | Value | Description |
| :--- | :--- | :--- |
| `GCC_C_LANGUAGE_STANDARD` | `gnu17` | GNU C17 standard |
| `CLANG_CXX_LANGUAGE_STANDARD` | `gnu++20` | GNU C++20 standard |
| `CLANG_ENABLE_OBJC_ARC` | `YES` | Automatic Reference Counting for Objective-C (`notification-osx.m`) |
| `MACOSX_DEPLOYMENT_TARGET` | `15.6` | Target macOS deployment version |
| `CREATE_INFOPLIST_SECTION_IN_BINARY` | `YES` | Embeds `osx/Info.plist` (`NSHighResolutionCapable`) directly into the Mach-O binary |
| `DEAD_CODE_STRIPPING` | `YES` | Strips unused symbols during linking |
| `GCC_NO_COMMON_BLOCKS` | `YES` | Enforces `-fno-common` for strict global symbol definitions |
| `WARNING_CFLAGS` | `-Wno-pointer-sign` `-Wno-deprecated-declarations` `-Wno-strict-prototypes` `-Wno-documentation` `-Wno-ambiguous-macro` | Suppresses legacy GTK+ 2.x deprecation noise while keeping strict bug/memory analyzers active |

---

## Additions & macOS Modernization

Upstream HexChat historically relied on Meson/JHBuild scripts, outdated GTK-OSX wrappers, and legacy `GdkPixmap` offscreen buffers that caused blurry text on Apple Retina displays. **VibeChat** introduces the following additions and architectural improvements:

| Subsystem / Area | Upstream HexChat (2.16.2) | VibeChat (macOS Port) |
| :--- | :--- | :--- |
| **Build System** | Meson & Ninja; requires Python-based code generators at build time | Native Apple Xcode project (`vibechat.xcodeproj`); instant compilation with zero external build scripts |
| **Retina / HiDPI Display** | Blurry font rendering; draws into legacy low-DPI `GdkPixmap` buffers | Direct Cairo vector text rendering (`pango_cairo_show_layout_line`), `NSHighResolutionCapable = YES`, subpixel antialiasing |
| **Default Typography** | Generic X11 `Monospace 9` and `Helvetica 10` | Optimized macOS defaults: `Menlo 12` (chat buffer) and `Helvetica Neue 12` (system UI) |
| **Embedded Resources** | Compiled during build via `glib-compile-resources` | Pre-compiled native `resources.c` & `resources.h` directly linked into the binary |
| **GLib / D-Bus Stubs** | Dynamically generated via `glib-genmarshal` and `dbus-binding-tool` | Pre-generated native `marshal.c`, `textenums.h`, `textevents.h`, and `remote-object-glue.h` |
| **macOS Notifications** | Legacy `NSUserNotificationCenter` with manual memory management warnings | ARC-safe modern Objective-C integration in `notification-osx.m` with runtime bundle detection |
| **URL Opening** | Escaped strings through Linux-oriented sanitizers; potential encoding issues | Native Cocoa `NSWorkspace` / `osx_show_uri` integration with clean URL dispatch |
| **Compiler Diagnostics** | Multiple warnings on modern Clang (pointer sign, uninitialized variables) | Zero compiler warnings; strict initialization of sockets, proxies, and scroll offsets |
| **OpenSSL Compatibility** | Compatible with legacy OpenSSL 1.0/1.1; type casting warnings on OpenSSL 3/4 | Updated pointer casts (`X509_PUBKEY`, `X509_NAME`) for modern OpenSSL 3.x / 4.x libraries |
| **Platform Clutter** | Contains Windows .NET Theme Manager (`src/htm`), Win8 spellcheck, and CLI `fe-text` | Pruned non-macOS legacy code, eliminating duplicate symbol conflicts |
| **Apple Silicon Support** | Required manual JHBuild or MacPorts patches | Native `/opt/homebrew` architecture paths for ARM64 and x86_64 macOS systems |

### In-Depth Code Additions

1. **Retina High-Resolution Font Engine (`src/fe-gtk/xtext.c`)**:
   - **Direct Cairo Line Rendering**: Added `#ifdef __APPLE__` hooks in `xtext_draw_layout_line` using `gdk_cairo_create(drawable)`. Layout lines are drawn directly through Cairo via `pango_cairo_show_layout_line(cr, line)` rather than low-DPI GDK graphics contexts.
   - **Bypassing GDK Pixmap Caching**: In `gtk_xtext_render_flush`, the allocation of an intermediate low-resolution `gdk_pixmap_new` is bypassed on macOS to prevent off-screen bitmap downsampling.
   - **Subpixel Antialiasing & Hinting**: Explicitly applies `CAIRO_ANTIALIAS_SUBPIXEL`, `CAIRO_HINT_STYLE_SLIGHT`, `CAIRO_HINT_METRICS_ON`, and `CAIRO_SUBPIXEL_ORDER_RGB`.
2. **Native macOS Initialization (`src/fe-gtk/fe-gtk.c` & `src/common/cfgfiles.c`)**:
   - Configures default monospaced font to `Menlo 12` and UI font to `Helvetica Neue 12` on macOS.
   - Configures `GdkScreen` font options on startup for consistent subpixel rendering across all GTK widgets.
3. **Warning-Free Modern C Hardening**:
   - Initialized uninitialized variables across network and UI handlers (`server.c`: `sok`, `psok`, `proxy`, `proxy_port`; `editlist.c` & `fkeys.c`: `delta`, `value`; `maingui.c`: `start`, `end`).
   - Explicitly defined `unsigned int` signedness for session bitfield flags in `src/common/hexchat.h`.
   - Fixed stray comma operators in `src/fe-gtk/servlistgui.c`.
   - Updated `const` pointer qualifiers on `X509_get_X509_PUBKEY` and `X509_get_subject_name` in `src/common/ssl.c` for OpenSSL 3.x/4.x.
4. **Single-Pass Xcode Modularization**:
   - Extracted `chanview-tabs.h` and `chanview-tree.h` declarations so Xcode's single-pass compilation model builds cleanly without duplicate symbol collisions.

---

## Complete Feature Set

### 1. IRC Protocol & IRCv3 Specifications
- **Full IRCv3 Support**:
  - `sasl` (`PLAIN`, `EXTERNAL` via client certificates, `SCRAM-SHA-1`, `SCRAM-SHA-256`, `SCRAM-SHA-512`)
  - `multi-prefix` (displays all user channel modes)
  - `server-time` (accurate message timestamps from bouncers and servers)
  - `account-notify` and `extended-join` (real-time account tracking)
  - `cap-notify` (dynamic capability negotiation)
  - `away-notify` (instant away status synchronization)
  - `batch`, `chghost`, `setname`, `message-tags`, and `invite-notify`
- **Multi-Network Connectivity**: Simultaneous connections to multiple IRC networks (Libera.Chat, OFTC, EFnet, IRCNet, private servers, etc.) with independent identities, proxies (SOCKS4, SOCKS5, HTTP, Wingate), and credentials.
- **SSL / TLS Encryption**: Native TLS socket connections, SNI (Server Name Indication), custom CA certificates, and client certificate authentication (CertFP).
- **Auto-Join & Auto-Identify**: Integrated NickServ password identification, Challenge-Auth, SASL, and automated channel joins upon connect.

### 2. User Interface & Display
- **Flexible Channel Views**:
  - Tabbed interface with activity and highlight badges.
  - Tree-view navigation grouping channels, private messages, and utility windows under network headers.
- **Rich Text & Color Formatting**:
  - Full support for standard mIRC color codes, hex RGB colors, bold, underline, italic, strikethrough, and hidden text.
  - Configurable color palette themes matching macOS light/dark appearances.
- **Fast Scrollback Buffer**: High-performance line buffer with regular expression search, text highlighting, URL grabbing, and `lastlog` filtering.
- **User List Management**:
  - Categorized by role: Founder (`~`), Owner (`&`), Operator (`@`), Half-Op (`%`), Voice (`+`), and standard members.
  - Context menu for whois, kick, ban, op/deop, DCC send, and private messaging.

### 3. File Transfers & Peer-to-Peer (DCC)
- **DCC Send & Receive**: Bandwidth throttling and file transfer resume support.
- **Passive DCC (Reverse DCC)**: Firewalled connection support without port forwarding.
- **DCC Chat**: Direct peer-to-peer chat connections bypassing IRC server relays.

### 4. macOS Integration
- **Native Notifications**: System banner alerts for mentions, private messages, and channel highlights via `notification-osx.m`.
- **Retina Displays**: Crisp, non-blurry fonts across internal chat buffers and GTK dialogs.
- **External URL Handling**: One-click opening of web links in the default macOS browser via `NSWorkspace`.
- **Keyboard Shortcuts**: macOS-compatible key bindings for tab cycling, line editing, and channel navigation.

### 5. Extensibility, Scripting & Plugins
- **Plugin Architecture**: Native C plugin API (`hexchat-plugin.h`) and scripting support for Lua (`luajit`), Perl (`perl`), and Python (`python3`), plus bundled plugin sources (`checksum`, `exec`, `fishlim`, `sysinfo`, `upd`, `winamp`).
- **Aliases & User Commands**: Custom `/command` aliases, userlist pop-up menus, CTCP replies, and replaceable variables.
- **D-Bus Automation**: Local IPC automation via the `io.github.Hexchat` interface (`dbus-client.c`, `dbus-plugin.c`).
- **Multilingual Spellcheck**: Inline spell checking in the chat input bar powered by `libenchant-2` and `iso-codes`.
- **Audio Feedback**: Configurable event sounds powered by `libcanberra`.

---

## Compile-Time Feature Flags (`config.h`)

Compile-time options are configured in [`vibe-hexchat/vibechat/hexchat/config.h`](vibe-hexchat/vibechat/hexchat/config.h):

| Macro | Default Value | Description |
| :--- | :--- | :--- |
| `USE_OPENSSL` | `1` | Enables OpenSSL TLS/SSL encrypted connections and SCRAM authentication |
| `USE_LIBCANBERRA` | `1` | Enables audio event notifications via `libcanberra` |
| `USE_DBUS` | `1` | Enables D-Bus IPC service (`io.github.Hexchat`) and single-instance remote commands |
| `USE_PLUGIN` | `1` | Enables dynamic plugin loading from `HEXCHATLIBDIR` (`/opt/homebrew/lib/hexchat/plugins`) |
| `ENABLE_NLS` | `1` | Enables GNU `gettext` localization (`LOCALEDIR` = `/opt/homebrew/share/locale`) |
| `HAVE_ISO_CODES` | `1` | Enables ISO language/territory name translation for spellcheck |

---

## Architecture & Repository Structure

```
vibechat/
├── README.md                            # Root documentation, Homebrew dependencies, and build guide
├── vibechat.xcodeproj/                  # Native Xcode project configuration
│   └── project.xcproj                   # Target settings, header/library search paths, and linker flags
└── vibe-hexchat/
    ├── README.md                        # Detailed technical & security documentation
    ├── plugins/                         # Standalone plugin source trees
    │   ├── checksum/                    # File hashing plugin (SHA-256 for DCC transfers)
    │   ├── exec/                        # Shell command execution plugin
    │   ├── fishlim/                     # FiSH Blowfish encryption & DH1080 key exchange plugin
    │   ├── lua/                         # LuaJIT scripting engine
    │   ├── perl/                        # Perl 5 scripting engine
    │   ├── python/                      # Python 3 scripting engine
    │   ├── sysinfo/                     # macOS/Unix system information plugin
    │   ├── upd/                         # Update notification plugin
    │   └── winamp/                      # Media player announcement plugin
    └── vibechat/
        └── hexchat/                     # Core HexChat engine
            ├── config.h                 # Xcode macOS build configuration & feature flags
            ├── osx/
            │   ├── Info.plist           # Retina HiDPI (NSHighResolutionCapable) & macOS metadata
            │   └── hexchat.icns         # Native macOS application icon
            └── src/
                ├── common/              # IRC core logic, networking, SSL, SCRAM, D-Bus
                │   ├── hexchat.h        # Main data structures & session state
                │   ├── server.c         # Network connection management
                │   ├── ssl.c            # OpenSSL TLS implementation
                │   ├── scram.c          # SASL SCRAM authentication
                │   ├── marshal.c/.h     # Pre-generated GLib marshalers
                │   ├── textevents.h     # Pre-generated event descriptors
                │   └── dbus/            # D-Bus IPC client and plugin implementation
                └── fe-gtk/              # GTK+ 2.x interface and Quartz backend
                    ├── xtext.c          # Retina-optimized Cairo text rendering
                    ├── fe-gtk.c         # GUI entrypoint and macOS font configurations
                    ├── chanview.c       # Channel navigation tabs & trees
                    ├── sexy-spell-entry.c # Enchant-2 spell checking entry widget
                    ├── resources.c/.h   # Embedded GTK GResource bundle
                    └── notifications/
                        └── notification-osx.m # Native macOS Notification Center backend
```

---

## Security Considerations & Hardening

To maintain a secure IRC environment on macOS, adhere to the following best practices (see [`vibe-hexchat/README.md`](vibe-hexchat/README.md) for a full vulnerability analysis):

1. **Strict DCC Rules**:
   - In **Preferences > File Transfers**, never enable *"Auto-accept file transfers"*.
   - Enable *"Use passive (reverse) mode"* to avoid exposing listening ports or leaking your local IP address.
2. **Enforce Strict TLS**:
   - Always connect via SSL/TLS (port `+6697`) and leave *"Accept invalid SSL certificates"* unchecked.
   - Prefer **SASL EXTERNAL** (CertFP) or **SASL SCRAM-SHA-256** over plaintext NickServ passwords.
3. **Audit Scripts & Plugins**:
   - Third-party Python, Perl, and Lua scripts run with full user privileges; only load audited scripts from trusted sources.

---

## License & Acknowledgements

VibeChat is released under the **GNU General Public License version 2 (GPLv2)** with the specific exception allowing compiling, linking, and distributing binaries linked against the **OpenSSL** library. See [`COPYING`](vibe-hexchat/vibechat/hexchat/COPYING) for full license terms.

- **X-Chat**: Copyright &copy; 1998–2010 Peter Zelezny.
- **HexChat**: Copyright &copy; 2009–2024 Berke Viktor, Patrick Griffis, and the HexChat development team.
- **VibeChat macOS Port**: Modernized for macOS, Xcode, and Retina HiDPI display architectures.
