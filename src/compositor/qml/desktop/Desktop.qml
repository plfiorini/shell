/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 * Copyright (C) 2017 Michael Spencer <sonrisesoftware@gmail.com>
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

import QtQuick 2.0
import QtWayland.Compositor 1.0 as QtWaylandCompositor
import QtGraphicalEffects 1.0
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import Fluid.Controls 1.0 as FluidControls
import Fluid.Effects 1.0 as FluidEffects
import Liri.WaylandServer 1.0 as WS
import Liri.Shell 1.0 as LS
import ".."
import "../components"

Item {
    id: desktop

    Material.theme: Material.Dark
    Material.primary: Material.Blue
    Material.accent: Material.Blue

    // Margins for "present" mode to fit screen aspect ratio
    property QtObject margins: QtObject {
        property real left: desktop.width * 0.1
        property real right: desktop.width * 0.1
        property real top: desktop.height * 0.1
        property real bottom: desktop.height * 0.1
    }

    readonly property alias backgroundLayer: backgroundLayer
    readonly property alias currentWorkspace: workspacesView.currentWorkspace
    readonly property alias windowSwitcher: windowSwitcher

    // All the necessary for the "present" mode
    layer.enabled: false
    layer.effect: FluidEffects.Elevation {
        elevation: 24
    }

    state: currentWorkspace.state
    states: [
        State {
            name: "normal"

            PropertyChanges {
                target: desktop
                anchors.margins: 0
            }
        },
        State {
            name: "present"

            // Margins respect screen aspect ratio
            PropertyChanges {
                target: desktop
                anchors.leftMargin: margins.left
                anchors.rightMargin: margins.right
                anchors.topMargin: margins.top
                anchors.bottomMargin: margins.bottom
            }
        }

    ]
    transitions: [
        Transition {
            to: "normal"

            SequentialAnimation {
                NumberAnimation {
                    properties: "anchors.leftMargin,anchors.rightMargin,anchors.topMargin,anchors.bottomMargin"
                    easing.type: Easing.OutQuad
                    duration: 300
                }
                ScriptAction {
                    script: {
                        desktop.layer.enabled = false;
                        output.layers.top.visible = true;
                    }
                }
            }
        },
        Transition {
            to: "present"

            SequentialAnimation {
                ScriptAction {
                    script: {
                        desktop.layer.enabled = true;
                        output.layers.top.visible = false;
                    }
                }
                NumberAnimation {
                    properties: "anchors.leftMargin,anchors.rightMargin,anchors.topMargin,anchors.bottomMargin"
                    easing.type: Easing.InQuad
                    duration: 300
                }
            }
        }
    ]

    /*
     * Workspace
     */

    Item {
        id: backgroundLayer

        anchors.fill: parent
    }

    WorkspacesView {
        id: workspacesView
    }

    // Windows switcher
    WindowSwitcher {
        id: windowSwitcher
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
    }

    /*
     * Methods
     */

    function selectPreviousWorkspace() {
        workspacesView.selectPrevious();
    }

    function selectNextWorkspace() {
        workspacesView.selectNext();
    }

    function selectWorkspace(num) {
        workspacesView.select(num);
    }

    function handleKeyPressed(event) {
        // Handle Meta modifier
        if (event.modifiers & Qt.MetaModifier) {
            // Open window switcher
            if (output.primary) {
                if (event.key === Qt.Key_Tab) {
                    event.accepted = true;
                    desktop.windowSwitcher.next();
                    return;
                } else if (event.key === Qt.Key_Backtab) {
                    event.accepted = true;
                    desktop.windowSwitcher.previous();
                    return;
                }
            }
        }

        event.accepted = false;
    }

    function handleKeyReleased(event) {
        // Handle Meta modifier
        if (event.modifiers & Qt.MetaModifier) {
            // Close window switcher
            if (output.primary) {
                if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) {
                    event.accepted = true;
                    desktop.windowSwitcher.close();
                    desktop.windowSwitcher.activate();
                    return;
                }
            }
        }

        event.accepted = false;
    }
}
