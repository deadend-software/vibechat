# VibeChat

[![macOS](https://img.shields.io/badge/platform-macOS%2015.6+-black.svg)](https://apple.com)
[![Xcode](https://img.shields.io/badge/build-Xcode%20Native-blue.svg)](https://developer.apple.com/xcode/)
[![Architecture](https://img.shields.io/badge/arch-Apple%20Silicon%20%7C%20x86__64-orange.svg)]()
[![License](https://img.shields.io/badge/license-GPLv2%20%2B%20OpenSSL%20Exemption-green.svg)](vibe-hexchat/hexchat/COPYING)

**VibeChat** is a modernized, native macOS port and optimization of the HexChat IRC client (version 2.16.2). Built specifically for contemporary macOS systems (Apple Silicon & Intel) using native Xcode project configuration, Quartz-backed GTK+, and modern Homebrew libraries, VibeChat brings high-fidelity HiDPI Retina text rendering, clean warning-free compilation, native desktop notifications, and a streamlined footprint to classic IRC.

---

## Table of Contents

- [Overview & Modernization](#overview--modernization)
- [Comprehensive Changes Compared to Upstream HexChat](#comprehensive-changes-compared-to-upstream-hexchat)
- [Complete Feature Set](#complete-feature-set)
- [Potential Security Risks & Vulnerability Analysis](#potential-security-risks--vulnerability-analysis)
- [Recommended Security Hardening](#recommended-security-hardening)
- [Building & Installation](#building--installation)
- [Architecture & Repository Structure](#architecture--repository-structure)
- [License & Acknowledgements](#license--acknowledgements)

---

## Overview & Modernization

Upstream HexChat is an established, feature-rich graphical IRC client originally based on X-Chat. However, official macOS support historically depended on outdated Meson/JHBuild packaging scripts, obsolete GTK-OSX wrappers, and legacy rendering pipelines that suffered from severe blurriness on modern Apple Retina displays.

**VibeChat** completely rearchitects the build and rendering toolchain for modern macOS:
1. **Fully Native Xcode Workspace**: Compiles directly inside Xcode (`vibe-hexchat.xcodeproj`) or through `xcodebuild` without Meson, Ninja, or complex Python build scripts.
2. **True HiDPI Retina Text Rendering**: Re-engineers the GTK text widget (`xtext.c`) to bypass low-DPI pixmap buffers and leverage direct Cairo vector font rendering with subpixel antialiasing and hint metrics.
3. **Zero-Warning Modern C Toolchain**: Resolves uninitialized variables, signedness issues, OpenSSL 3.x/4.x pointer type mismatches, and Clang compiler diagnostics.
4. **Platform Decoupling**: Purges legacy Windows-specific C# binaries, obsolete Windows spellcheck providers, and redundant terminal frontends, leaving a lean, performant codebase.

---

## Comprehensive Changes Compared to Upstream HexChat

| Subsystem / Area | Upstream HexChat (2.16.2) | VibeChat (macOS Port) |
| :--- | :--- | :--- |
| **Build System** | Meson & Ninja; requires Python-based code generators at build time | Native Apple Xcode project (`project.xcproj`); instant compilation with zero external build generators |
| **Retina / HiDPI Display** | Blurry font rendering; draws into legacy low-DPI `GdkPixmap` buffers | Direct Cairo text rendering (`pango_cairo_show_layout_line`), `NSHighResolutionCapable = YES`, subpixel antialiasing |
| **Default Typography** | Generic X11 `Monospace 9` and `Helvetica 10` | Optimized macOS defaults: `Menlo 12` (chat buffer) and `Helvetica Neue 12` (system UI) |
| **Embedded Resources** | Compiled during build via `glib-compile-resources` | Pre-compiled native `resources.c` & `resources.h` directly linked into binary |
| **GLib / D-Bus Stubs** | Dynamically generated via `glib-genmarshal` and `dbus-binding-tool` | Pre-generated native `marshal.c`, `textenums.h`, `textevents.h`, and `remote-object-glue.h` |
| **macOS Notifications** | Legacy `NSUserNotificationCenter` with manual memory management warnings | ARC-safe modern Objective-C integration in `notification-osx.m` with runtime bundle detection |
| **URL Opening** | Escaped strings through Linux-oriented sanitizers; potential encoding issues | Native Cocoa `NSWorkspace` / `osx_show_uri` integration with clean URL dispatch |
| **Compiler Diagnostics** | Multiple warnings on modern Clang (pointer sign, uninitialized variables) | Zero compiler warnings; strict initialization of sockets, proxies, and scroll offsets |
| **OpenSSL Compatibility** | Compatible with legacy OpenSSL 1.0/1.1; type casting warnings on OpenSSL 3/4 | Updated pointer casts (`X509_PUBKEY`, `X509_NAME`) for modern OpenSSL 3.x / 4.x libraries |
| **Platform Clutter** | Contains Windows .NET Theme Manager (`src/htm`), Win8 spellcheck, and CLI `fe-text` | Completely pruned non-macOS legacy code, eliminating duplicate symbol conflicts |
| **Apple Silicon Support** | Required manual JHBuild or MacPorts patches | Native `/opt/homebrew` architecture paths for ARM64 and x86_64 macOS systems |

### In-Depth Code Modifications

#### 1. Retina High-Resolution Font Engine (`src/fe-gtk/xtext.c`)
- **Direct Cairo Line Rendering**: Added `#ifdef __APPLE__` hooks in `xtext_draw_layout_line` using `gdk_cairo_create (drawable)`. Instead of blitting via low-resolution GDK graphics contexts, layout lines are drawn directly through Cairo with `pango_cairo_show_layout_line (cr, line)`.
- **Bypassing GDK Pixmap Caching**: In `gtk_xtext_render_flush`, the allocation of an intermediate low-resolution `gdk_pixmap_new` is bypassed on macOS. This avoids off-screen bitmap downsampling that causes blurry text on high-density Retina displays.
- **Subpixel Antialiasing & Hinting**: Cairo font options are explicitly applied with:
  - Antialiasing: `CAIRO_ANTIALIAS_SUBPIXEL`
  - Hint Style: `CAIRO_HINT_STYLE_SLIGHT`
  - Hint Metrics: `CAIRO_HINT_METRICS_ON`
  - Subpixel Order: `CAIRO_SUBPIXEL_ORDER_RGB`

#### 2. Native macOS Initialization (`src/fe-gtk/fe-gtk.c` & `src/common/cfgfiles.c`)
- Default monospaced font changed from `Monospace 9` to `Menlo 12` on macOS.
- UI font set to `Helvetica Neue 12`.
- `GdkScreen` font options configured on startup for consistent subpixel rendering across all GTK interface widgets.

#### 3. Warning-Free Modern C Hardening
- **Uninitialized Variable Cleanup**: Initialized uninitialized variables across network and UI handlers (`server.c`: `sok`, `psok`, `proxy`, `proxy_port`; `editlist.c` & `fkeys.c`: `delta`, `value`; `maingui.c`: `start`, `end`).
- **Bitfield Specification**: Explicitly defined signedness (`unsigned int`) for session bitfield flags (`ignore_date`, `ignore_mode`, `ignore_names`, `end_of_names`, `doing_who`, `done_away_check`) in `src/common/hexchat.h`.
- **Syntax Correction**: Fixed stray comma operators in `src/fe-gtk/servlistgui.c`.
- **OpenSSL 3/4 Casting**: Corrected pointer qualifiers on `X509_get_X509_PUBKEY` and `X509_get_subject_name` in `src/common/ssl.c`.

#### 4. Project Modularization
- Replaced `#include "chanview-tabs.c"` and `#include "chanview-tree.c"` with header declarations (`chanview-tabs.h`, `chanview-tree.h`) to support Xcode's single-pass folder compilation model and eliminate duplicate symbol collisions.
- Pre-generated GResource bundles (`resources.c`), GLib marshalers (`marshal.c`), and text event tables (`textevents.h`).

---

## Complete Feature Set

### 1. IRC Protocol & IRCv3 Specifications
- **Full IRCv3 Support**:
  - `sasl` (PLAIN, EXTERNAL via client certificates)
  - `multi-prefix` (shows all user channel modes)
  - `server-time` (accurate message timestamps from bouncers and servers)
  - `account-notify` and `extended-join` (real-time account tracking)
  - `cap-notify` (dynamic capability negotiation)
  - `away-notify` (instant status synchronization)
  - `batch` and `invite-notify`
- **Multi-Network Connectivity**: Simultaneous connections to multiple IRC networks (Libera.Chat, OFTC, EFnet, IRCNet, private servers, etc.) with independent identities, proxies, and credentials.
- **SSL / TLS Encryption**: Native TLS socket connections, SNI (Server Name Indication), custom CA certificates, and client certificate authentication (CertFP).
- **Auto-Join & Auto-Identify**: Integrated NickServ password identification, Challenge-Auth, and automated channel joins upon connect.

### 2. User Interface & Display
- **Flexible Channel Views**:
  - Tabbed interface with notification badges.
  - Tree-view navigation grouping channels, private messages, and utility windows under network headers.
- **Rich Text & Color Formatting**:
  - Full support for standard mIRC color codes, hex RGB colors, bold, underline, italic, and strikethrough.
  - Configurable palette themes matching macOS light/dark appearances.
- **Fast Scrollback Buffer**: High-performance line buffer with regular expression search, text highlighting, and `lastlog` filtering.
- **User List Management**:
  - Categorized by role: Founder (`~`), Owner (`&`), Operator (`@`), Half-Op (`%`), Voice (`+`), and standard members.
  - Context menu for whois, kick, ban, op/deop, and private messaging.

### 3. File Transfers & Peer-to-Peer
- **DCC (Direct Client-to-Client)**:
  - DCC Send and Receive with bandwidth throttling and resume support (`resume`).
  - Passive DCC (Reverse DCC) support for firewalled connections.
  - DCC Chat for private direct messaging bypassing IRC server logs.
  - UPnP integration for automatic NAT port forwarding.

### 4. macOS Integration
- **Native Notifications**: System banner alerts for mentions, private messages, and channel highlights via `NSUserNotificationCenter`.
- **Retina Displays**: Crisp, non-blurry fonts across internal chat buffers and GTK dialogs.
- **External URL Handling**: One-click opening of web links in the default macOS browser via `NSWorkspace`.
- **Keyboard Shortcuts**: macOS-compatible key bindings for tab cycling, line editing, and channel navigation.

### 5. Extensibility & Automation
- **Scripting Architecture**: Supports plugins and scripts via LuaJIT, Perl, and Python bindings.
- **Aliases & User Commands**: Custom commands, pop-up menus, and automated CTCP replies.
- **D-Bus Automation**: Local IPC automation via `io.github.Hexchat` interface.
- **Multilingual Spellcheck**: Spell checking integrated directly into the chat input bar via `libenchant-2`.
- **Audio Feedback**: Configurable event sounds powered by `libcanberra`.

---

## Potential Security Risks & Vulnerability Analysis

IRC is an unauthenticated, decentralized, text-based protocol that exposes clients to various attack vectors if not configured safely. The following analysis outlines the technical security risks inherent to IRC clients and HexChat's architecture.

### 1. DCC (Direct Client-to-Client) & Network Exposure
- **Real IP Address Leakage**:
  - *Risk*: When initiating or accepting a DCC file transfer or DCC Chat, the client sends a CTCP message containing the user's direct IP address (local or public) and listening port.
  - *Impact*: Bypasses VPNs, proxies, or Tor connections that the user relies on to mask their identity from IRC channel operators or adversaries, leading to targeted DDoS attacks, geolocation tracking, or local network port scanning.
- **Insecure File Reception & Remote Code Execution**:
  - *Risk*: Malicious files received via DCC can contain malicious payloads (e.g., weaponized AppleScripts, malicious `.pkg` installers, Mach-O binaries, or malicious Office documents).
  - *Impact*: If the user has configured HexChat to "Auto-accept DCC transfers" or clicks to open files directly from the download directory, arbitrary code execution on macOS may occur.

### 2. TLS / SSL & Certificate Verification Pitfalls
- **Self-Signed Certificates & Disabled Verification**:
  - *Risk*: HexChat permits users to check "Accept invalid SSL certificates" per network.
  - *Impact*: Disabling strict certificate verification leaves the connection vulnerable to Man-in-the-Middle (MitM) attacks on public Wi-Fi or compromised network routes, allowing attackers to intercept credentials, NickServ passwords, and private conversations.
- **SNI and Hostname Mismatches**:
  - *Risk*: IRC servers often use pooled or round-robin domain names (`irc.example.net`) whose TLS certificates may match individual server hostnames rather than the pool name. Users frequently disable verification to bypass connection warnings.

### 3. C Codebase & Memory Safety Considerations
- **String Parsing & Memory Management**:
  - *Risk*: HexChat is written in C and uses manual memory management (`malloc`, `free`, GLib's `g_malloc`) alongside custom buffer tokenizers (`split_words`, `format_event`).
  - *Impact*: Malformed IRC server messages, oversized CTCP queries, invalid UTF-8 byte sequences, or crafted color codes could trigger heap/stack buffer overflows, integer wrap-arounds, or out-of-bounds reads.
- **Denial of Service (DoS) via Channel Flooding**:
  - *Risk*: Rapid transmission of high-frequency NOTICEs, PRIVMSGs with complex ANSI/mIRC formatting, or mass user joins/parts can saturate the Pango layout cache and Cairo rendering pipeline.
  - *Impact*: UI freeze, high CPU utilization, and potential application crash.

### 4. Third-Party Scripting & Plugin Risks
- **Arbitrary Code Execution via Untrusted Scripts**:
  - *Risk*: Python, Perl, and Lua scripts run with the full security context and user permissions of the HexChat process.
  - *Impact*: HexChat does not isolate or sandbox external scripts. An untrusted script loaded by the user can read SSH keys, access macOS Keychain items, install persistence mechanisms, or transmit local files.
- **The `/exec` Plugin Danger**:
  - *Risk*: The `/exec` plugin runs shell commands directly in the user's terminal environment.
  - *Impact*: Binding `/exec` to automated triggers, CTCP requests, or unescaped message variables (`%s`) can result in shell command injection.
- **FiSH Encryption Limitations (`fishlim`)**:
  - *Risk*: FiSH encryption relies on Blowfish in ECB (Electronic Codebook) or CBC mode with shared symmetric keys.
  - *Impact*: ECB mode leaks structural patterns of plaintext. FiSH does not offer Perfect Forward Secrecy (PFS), cryptographic message authentication (MAC), or identity verification. It should not be considered secure against modern nation-state surveillance or cryptanalysis.

### 5. Inter-Process Communication (D-Bus)
- **Local IPC Attack Surface**:
  - *Risk*: HexChat exposes the `io.github.Hexchat` interface on the user's session D-Bus.
  - *Impact*: Any untrusted local application running under the same user UID can send D-Bus commands to HexChat to transmit IRC messages, join channels, read channel lists, or inspect user status without user confirmation.

### 6. macOS-Specific URL Dispatch Risks
- **URI Handler Exploitation**:
  - *Risk*: Clicking formatted URLs in chat buffers triggers `NSWorkspace openURL:`.
  - *Impact*: If non-HTTP URI schemes (e.g., `file://`, `help:`, `applescript:`, or custom app schemes) are processed without confirmation dialogs, an attacker could invoke unintended macOS system actions.

---

## Recommended Security Hardening

To maintain a secure IRC environment, adhere to the following best practices:

1. **Strict DCC Rules**:
   - Navigate to **HexChat > Preferences > File Transfers**.
   - **Never** enable *"Auto-accept file transfers"*.
   - Enable *"Use passive (reverse) mode"* to avoid exposing open listening ports.
   - Do not open received files without scanning them with local security tools.
2. **Enforce Strict TLS**:
   - Always connect using SSL/TLS (default port `+6697`).
   - Leave *"Accept invalid SSL certificates"* unchecked.
   - Use SASL EXTERNAL with client certificates (CertFP) instead of plaintext NickServ passwords.
3. **Audit Scripts & Plugins**:
   - Only load scripts from trusted repositories whose source code you have personally reviewed.
   - Avoid using `/exec` with unescaped arguments or public channel triggers.
4. **Use IRC Bouncers (ZNC / Soju)**:
   - Route IRC connections through a trusted remote bouncer to protect your residential IP address from being exposed in `/whois` and DNS queries.

---

## Building & Installation

### Prerequisites

Ensure you have [Homebrew](https://brew.sh) installed with the required dependencies:

```bash
brew install gtk+ glib pango cairo gdk-pixbuf atk libcanberra enchant luajit dbus-glib openssl@4 gettext perl
```

### Compiling with Xcode

1. Open `vibe-hexchat.xcodeproj` in Xcode:
   ```bash
   open vibe-hexchat.xcodeproj
   ```
2. Select the **vibe-hexchat** scheme and choose **My Mac** as the run destination.
3. Build the project using `Product > Build` (`Cmd + B`) or run it directly (`Cmd + R`).

### Compiling via Command Line (`xcodebuild`)

You can build a Release binary directly from your terminal:

```bash
xcodebuild -project vibe-hexchat.xcodeproj -scheme vibe-hexchat -configuration Release build
```

The compiled binary will be placed in:
```
build/Release/vibe-hexchat
```

---

## Architecture & Repository Structure

```
vibe-hexchat/
├── vibe-hexchat.xcodeproj/          # Native Xcode project definitions
│   └── project.xcproj               # Target settings, search paths, and linker flags
├── plugins/                         # Standalone plugin source trees
│   ├── checksum/                    # File hashing plugin
│   ├── exec/                        # Command execution plugin
│   ├── fishlim/                     # FiSH Blowfish encryption plugin
│   ├── lua/                         # LuaJIT scripting engine
│   ├── perl/                        # Perl 5 scripting engine
│   ├── python/                      # Python 3 scripting engine
│   ├── sysinfo/                     # System information plugin
│   ├── upd/                         # Update notification plugin
│   └── winamp/                      # Media player announcement plugin
└── vibe-hexchat/
    └── hexchat/                     # Core HexChat engine
        ├── config.h                 # Xcode macOS build configuration
        ├── osx/
        │   ├── Info.plist           # Retina HiDPI & macOS bundle metadata
        │   └── hexchat.icns         # Native macOS application icon
        ├── src/
        │   ├── common/              # IRC core logic, networking, SSL, D-Bus
        │   │   ├── hexchat.h        # Main data structures & session state
        │   │   ├── server.c         # Network connection management
        │   │   ├── ssl.c            # OpenSSL TLS implementation
        │   │   ├── marshal.c/.h     # Pre-generated GLib marshalers
        │   │   ├── textevents.h     # Pre-generated event descriptors
        │   │   └── textenums.h      # Event enumerations
        │   └── fe-gtk/              # GTK+ 2.x interface and Quartz backend
        │       ├── xtext.c          # Retina-optimized Cairo text rendering
        │       ├── fe-gtk.c         # GUI entrypoint and font configurations
        │       ├── chanview.c       # Channel navigation tabs & trees
        │       ├── resources.c/.h   # Embedded GTK GResource bundle
        │       └── notifications/
        │           └── notification-osx.m # Native macOS Notification Center
        └── readme.md                # Submodule documentation
```

---

## License & Acknowledgements

VibeChat is released under the **GNU General Public License version 2 (GPLv2)** with the specific exception allowing compiling, linking, and distributing binaries linked against the **OpenSSL** library. See [COPYING](vibe-hexchat/hexchat/COPYING) for complete details.

### Heritage & Credits
- **X-Chat**: Copyright &copy; 1998–2010 Peter Zelezny.
- **HexChat**: Copyright &copy; 2009–2024 Berke Viktor, Patrick Griffis, and the HexChat development team.
- **VibeChat macOS Port**: Modernized for macOS and Retina HiDPI display architectures.
