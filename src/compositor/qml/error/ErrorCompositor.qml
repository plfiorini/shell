/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 *
 * $BEGIN_LICENSE:GPL3+$
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * $END_LICENSE$
 ***************************************************************************/

import QtQml 2.2
import QtQuick 2.5
import QtQuick.Window 2.0
import QtWayland.Compositor 1.0
import Liri.Session 1.0 as Session
import Liri.WaylandServer 1.0 as WS
import Liri.private.shell 1.0 as P
import ".." as Root

WaylandCompositor {
    id: liriCompositor

    signal startedUp()

    onCreatedChanged: {
        if (liriCompositor.created) {
            console.debug("Compositor created");
            Session.SessionManager.setEnvironment("WAYLAND_DISPLAY", liriCompositor.socketName);
            startedUp();
        }
    }

    onSurfaceRequested: {
        var surface = surfaceComponent.createObject(liriCompositor, {});
        surface.initialize(liriCompositor, client, id, version);
    }

    Shortcut {
        context: Qt.ApplicationShortcut
        sequence: "Ctrl+Alt+Backspace"
        onActivated: liriCompositor.quit()
    }

    P.ScreenModel {
        id: screenModel
        fileName: screenConfigurationFileName
    }

    Instantiator {
        id: screenManager

        model: screenModel
        delegate: ErrorOutput {
            compositor: liriCompositor
            screen: screenItem
            position: screenItem.position
            manufacturer: screenItem.manufacturer
            model: screenItem.model
            physicalSize: screenItem.physicalSize
            subpixel: screenItem.subpixel
            transform: screenItem.transform
            scaleFactor: screenItem.scaleFactor

            Component.onCompleted: {
                // Set default output the first time
                if (!liriCompositor.defaultOutput)
                    liriCompositor.defaultOutput = this;
            }
        }
    }

    // Surface component
    Component {
        id: surfaceComponent

        WaylandSurface {}
    }

    // Shell helper
    WS.LiriShell {
        id: shellHelper
    }

    function quit() {
        shellHelper.sendQuit();

        for (var i = 0; i < screenManager.count; i++)
            screenManager.objectAt(i).window.close();

        Qt.quit();
    }
}
