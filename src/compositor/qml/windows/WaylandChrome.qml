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

import QtQuick 2.0
import QtWayland.Compositor 1.0
import Fluid.Effects 1.0 as FluidEffects
import Liri.WaylandServer 1.0 as WS
import Liri.private.shell 1.0 as P

P.ChromeItem {
    id: chrome

    property QtObject window

    x: chrome.window.moveItem.x - shellSurfaceItem.output.position.x
    y: chrome.window.moveItem.y - shellSurfaceItem.output.position.y

    implicitWidth: chrome.window.surfaceGeometry.width + (2 * chrome.window.borderSize)
    implicitHeight: chrome.window.surfaceGeometry.height + (2 * chrome.window.borderSize) + chrome.window.titleBarHeight

    shellSurfaceItem: shellSurfaceItem

    // FIXME: Transparent backgrounds will be opaque due to shadows
    layer.enabled: chrome.window.mapped && chrome.window.bordered
    layer.effect: FluidEffects.Elevation {
        elevation: shellSurfaceItem.focus ? 24 : 8
    }

    transform: [
        Scale {
            id: scaleTransform
            origin.x: chrome.width / 2
            origin.y: chrome.height / 2
        },
        Scale {
            id: scaleTransformPos
            origin.x: chrome.width / 2
            origin.y: chrome.y - shellSurfaceItem.output.position.y - chrome.height
        }
    ]

    QtObject {
        id: __private

        property point moveItemPosition

        function setPosition() {
            if (chrome.window.windowType === Qt.Popup)
                return;

            var parentSurfaceItem = shellSurfaceItem.output.viewsBySurface[chrome.window.parentSurface];
            if (parentSurfaceItem) {
                chrome.window.moveItem.x = parentSurfaceItem.window.moveItem.x + ((parentSurfaceItem.width - chrome.width) / 2);
                chrome.window.moveItem.y = parentSurfaceItem.window.moveItem.y + ((parentSurfaceItem.height - chrome.height) / 2);
            } else {
                var pos = chrome.randomPosition(liriCompositor.mousePos);
                chrome.window.moveItem.x = pos.x;
                chrome.window.moveItem.y = pos.y;
            }
        }

        function giveFocusToParent() {
            // Give focus back to the parent
            var parentSurfaceItem = shellSurfaceItem.output.viewsBySurface[chrome.window.parentSurface];
            if (parentSurfaceItem)
                parentSurfaceItem.takeFocus();
        }
    }

    Connections {
        target: chrome.window
        ignoreUnknownSignals: true

        function onMappedChanged() {
            if (chrome.window.mapped) {
                if (chrome.window.focusable)
                    takeFocus();
                __private.setPosition();
                mapAnimation.start();
            }
        }
        function onActivatedChanged() {
            if (chrome.window.activated)
                chrome.raise();
        }
        function onMinimizedChanged() {
            if (chrome.window.minimized)
                minimizeAnimation.start();
            else
                unminimizeAnimation.start();
        }
        function onShowWindowMenu(seat, localSurfacePosition) {
            showWindowMenu(localSurfacePosition.x, localSurfacePosition.y);
        }
    }

    Connections {
        target: shellSurfaceItem.output

        function onGeometryChanged() {
            if (!chrome.primary)
                return;

            // Resize fullscreen windows as the geometry changes
            if (chrome.window.fullscreen)
                chrome.window.sendFullscreen(shellSurfaceItem.output);
        }
        function onAvailableGeometryChanged() {
            if (!chrome.primary)
                return;

            // Resize maximized windows as the available geometry changes
            if (chrome.window.maximized)
                chrome.window.sendMaximized(shellSurfaceItem.output);
        }
    }

    Decoration {
        id: decoration

        anchors.fill: parent
        drag.target: chrome.window.moveItem
        enabled: chrome.window.decorated
        visible: chrome.window.mapped && enabled
    }

    P.ShellSurfaceItem {
        id: shellSurfaceItem

        x: chrome.window.borderSize
        y: chrome.window.borderSize + chrome.window.titleBarHeight

        shellSurface: chrome.window.shellSurface
        moveItem: chrome.window.moveItem

        inputEventsEnabled: !output.locked

        focusOnClick: chrome.window.focusable

        onMoveStarted: {
            // Move initiated with Meta+LeftMouseButton has started
            shellHelper.grabCursor(WS.LiriShell.MoveGrabCursor);
        }
        onMoveStopped: {
            // Move initiated with Meta+LeftMouseButton has stopped
            shellHelper.grabCursor(WS.LiriShell.ArrowGrabCursor);
        }

        onSurfaceDestroyed: {
            bufferLocked = true;
            destroyAnimation.start();
        }

        /*
         * Animations
         */

        Behavior on width {
            SmoothedAnimation { alwaysRunToEnd: true; easing.type: Easing.InOutQuad; duration: 350 }
        }

        Behavior on height {
            SmoothedAnimation { alwaysRunToEnd: true; easing.type: Easing.InOutQuad; duration: 350 }
        }
    }

    ChromeMenu {
        id: chromeMenu
    }

    /*
     * Animations for creation and destruction
     */

    ParallelAnimation {
        id: mapAnimation

        alwaysRunToEnd: true

        NumberAnimation { target: chrome; property: "scale"; from: 0.9; to: 1.0; easing.type: Easing.OutQuint; duration: 220 }
        NumberAnimation { target: chrome; property: "opacity"; from: 0.0; to: 1.0; easing.type: Easing.OutCubic; duration: 150 }
    }

    SequentialAnimation {
        id: destroyAnimation

        alwaysRunToEnd: true

        ParallelAnimation {
            NumberAnimation { target: chrome; property: "scale"; from: 1.0; to: 0.9; easing.type: Easing.OutQuint; duration: 220 }
            NumberAnimation { target: chrome; property: "opacity"; from: 1.0; to: 0.0; easing.type: Easing.OutCubic; duration: 150 }
        }

        ScriptAction {
            script: {
                __private.giveFocusToParent();
                chrome.destroy();

                if (chrome.primary)
                    liriCompositor.handleShellSurfaceDestroyed(window);
            }
        }
    }

    /*
     * Animations when the window is minimized or unminimized
     */

    SequentialAnimation {
        id: minimizeAnimation

        alwaysRunToEnd: true

        ScriptAction {
            script: {
                var taskBarItem = shellSurfaceItem.output.viewsBySurface[chrome.window.taskBarSurface];
                if (taskBarItem) {
                    // Save previous coordinates
                    __private.moveItemPosition.x = chrome.window.moveItem.x;
                    __private.moveItemPosition.y = chrome.window.moveItem.y;

                    // Move to the task bar item
                    var x = chrome.window.taskBarEntryGeometry.x - (chrome.implicitWidth / 2);
                    var y = chrome.window.taskBarEntryGeometry.y - (chrome.implicitHeight / 2);
                    var coords = taskBarItem.mapToItem(taskBarItem.parent, x, y);
                    chrome.window.moveItem.animateTo(coords.x, coords.y);
                }
            }
        }

        ParallelAnimation {
            NumberAnimation { target: chrome; property: "scale"; easing.type: Easing.OutQuad; to: 0.0; duration: 550 }
            NumberAnimation { target: chrome; property: "opacity"; easing.type: Easing.Linear; to: 0.0; duration: 500 }
        }
    }

    SequentialAnimation {
        id: unminimizeAnimation

        alwaysRunToEnd: true

        ScriptAction {
            script: {
                chrome.window.moveItem.animateTo(__private.moveItemPosition.x, __private.moveItemPosition.y);
            }
        }

        ParallelAnimation {
            NumberAnimation { target: chrome; property: "scale"; easing.type: Easing.OutQuad; to: 1.0; duration: 550 }
            NumberAnimation { target: chrome; property: "opacity"; easing.type: Easing.Linear; to: 1.0; duration: 500 }
        }
    }

    /*
     * Methods
     */

    function showWindowMenu(x, y) {
        chromeMenu.x = x;
        chromeMenu.y = y;
        chromeMenu.open();
    }
}
