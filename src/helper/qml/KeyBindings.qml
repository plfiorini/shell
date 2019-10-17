// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.5
import QtGSettings 1.0 as Settings
import Fluid.Core 1.0 as FluidCore
import Liri.Session 1.0 as Session
import Liri.WaylandClient 1.0 as WC

FluidCore.Object {
    Settings.GSettings {
        id: wmKeybindings

        schema.id: "io.liri.desktop.keybindings.wm"
        schema.path: "/io/liri/desktop/keybindings/wm/"
    }

    Settings.GSettings {
        id: smKeybindings

        schema.id: "io.liri.desktop.keybindings.sm"
        schema.path: "/io/liri/desktop/keybindings/sm/"
    }

    Settings.GSettings {
        id: desktopKeybindings

        schema.id: "io.liri.desktop.keybindings.desktop"
        schema.path: "/io/liri/desktop/keybindings/desktop/"
    }


    WC.LiriShortcut {
        shell: liriShell
        sequence: wmKeybindings.mainMenu
        onActivated: {
            appsDialog.open();
        }
    }

    WC.LiriShortcut {
        shell: liriShell
        sequence: desktopKeybindings.runCommand
        onActivated: {
            runDialog.open();
        }
    }

    WC.LiriShortcut {
        shell: liriShell
        sequence: smKeybindings.lockScreen
        onActivated: {
            Session.SessionManager.lock();
        }
    }

    WC.LiriShortcut {
        shell: liriShell
        sequence: smKeybindings.powerOff
        onActivated: {
            shutdownDialog.open();
        }
    }
}
