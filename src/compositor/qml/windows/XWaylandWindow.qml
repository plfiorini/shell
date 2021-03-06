/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2019 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
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
import QtWayland.Compositor 1.1 as QtWayland
import Fluid.Core 1.0 as FluidCore
import Liri.XWayland 1.0 as LXW

FluidCore.Object {
    id: window

    property LXW.XWaylandShellSurface shellSurface: null
    readonly property QtWayland.WaylandSurface surface: shellSurface ? shellSurface.surface : null
    readonly property alias parentSurface: d.parentSurface

    readonly property int windowType: shellSurface ? shellSurface.windowType : Qt.Window

    readonly property alias mapped: d.mapped

    readonly property alias moveItem: moveItem

    readonly property string title: shellSurface ? shellSurface.title : ""
    readonly property string appId: d.appId
    readonly property string iconName: d.iconName

    readonly property alias windowGeometry: d.windowGeometry
    readonly property alias surfaceGeometry: d.surfaceGeometry

    readonly property size minSize: Qt.size(0, 0)
    readonly property size maxSize: Qt.size(0, 0)

    readonly property bool activated: shellSurface && shellSurface.activated
    property bool minimized: false
    readonly property bool maximized: shellSurface && shellSurface.maximized
    readonly property bool fullscreen: shellSurface && shellSurface.fullscreen
    readonly property bool resizing: false

    readonly property bool decorated: shellSurface && shellSurface.windowType !== Qt.Popup && shellSurface.decorate && !shellSurface.fullscreen
    readonly property bool bordered: decorated && !shellSurface.maximized
    readonly property real borderSize: bordered ? 4 : 0
    readonly property real titleBarHeight: decorated ? 32 : 0

    readonly property bool focusable: shellSurface && shellSurface.windowType !== Qt.Popup
    readonly property bool maximizable: true

    signal showWindowMenu(QtWayland.WaylandSeat seat, point localSurfacePosition)

    QtObject {
        id: d

        property string appId: ""
        property string iconName: ""
        property rect windowGeometry
        property rect surfaceGeometry
        property bool mapped: false
        property bool registered: false
        property bool responsive: true
        property QtWayland.WaylandSurface parentSurface: null

        function recalculateWindowGeometry() {
            var w = window.surface ? window.surface.size.width : 0;
            var h = window.surface ? window.surface.size.height : 0;

            if (window.decorated)
                return Qt.rect(window.borderSize, window.borderSize,
                               w + window.borderSize, h + window.borderSize + window.titleBarHeight);

            return Qt.rect(0, 0, w > 0 ? w : -1, h > 0 ? h : -1);
        }

        function recalculateSurfaceGeometry() {
            var w = window.surface ? window.surface.size.width : 0;
            var h = window.surface ? window.surface.size.height : 0;

            return Qt.rect(0, 0, w > 0 ? w : -1, h > 0 ? h : -1);
        }
    }

    Connections {
        target: surface
        onSizeChanged: {
            d.windowGeometry = d.recalculateWindowGeometry();
            d.surfaceGeometry = d.recalculateSurfaceGeometry();
        }
    }

    Connections {
        target: shellSurface
        onActivatedChanged: {
            if (d.registered && shellSurface.activated && shellSurface.windowType !== Qt.Popup)
                applicationManager.focusShellSurface(window);
        }
        onSurfaceChanged: {
            // Surface is changed, which means that app id has likely changed too
            d.appId = applicationManager.canonicalizeAppId(shellSurface.appId);
        }
        onAppIdChanged: {
            // Canonicalize app id and cache it, so that it's known even during destruction
            d.appId = applicationManager.canonicalizeAppId(shellSurface.appId);

            if (!d.registered && d.appId) {
                // Register application
                applicationManager.registerShellSurface(window);
                d.registered = true;

                // Focus icon in the panel
                if (d.activated)
                    applicationManager.focusShellSurface(window);
            }

            // Set icon name when appId changes
            var appIconName = applicationManager.getIconName(d.appId);
            d.iconName = appIconName ? appIconName : "";
        }
        onMapped: {
            d.mapped = true;
        }
        onUnmapped: {
            d.mapped = false;
        }
        onSetMinimized: {
            minimized = !minimized;
        }
    }

    MoveItem {
        id: moveItem

        parent: rootItem
        width: windowGeometry.width
        height: windowGeometry.height
    }

    function __convertEdges(edges) {
        var wlEdges = LXW.XWaylandShellSurface.NoneEdge;
        if (edges & Qt.TopEdge && edges & Qt.LeftEdge)
            wlEdges |= LXW.XWaylandShellSurface.TopLeftEdge;
        else if (edges & Qt.BottomEdge && edges & Qt.LeftEdge)
            wlEdges |= LXW.XWaylandShellSurface.BottomLeftEdge;
        else if (edges & Qt.TopEdge && edges & Qt.RightEdge)
            wlEdges |= LXW.XWaylandShellSurface.TopRightEdge;
        else if (edges & Qt.BottomEdge && edges & Qt.RightEdge)
            wlEdges |= LXW.XWaylandShellSurface.BottomRightEdge;
        else {
            if (edges & Qt.TopEdge)
                wlEdges |= LXW.XWaylandShellSurface.TopEdge;
            if (edges & Qt.BottomEdge)
                wlEdges |= LXW.XWaylandShellSurface.BottomEdge;
            if (edges & Qt.LeftEdge)
                wlEdges |= LXW.XWaylandShellSurface.LeftEdge;
            if (edges & Qt.RightEdge)
                wlEdges |= LXW.XWaylandShellSurface.RightEdge;
        }
        return wlEdges;
    }

    function sizeForResize(size, delta, edges) {
        return shellSurface.sizeForResize(size, delta, __convertEdges(edges));
    }

    function sendResizing(size) {
        shellSurface.sendResize(size);
    }

    function sendMaximized(output) {
        shellSurface.maximize(output);
    }

    function sendUnmaximized() {
        shellSurface.unmaximize();
    }

    function sendFullscreen(output) {
        console.warn("Not implemented yet");
    }

    function pingClient() {
        console.warn("Not implemented yet");
    }

    function sendClose() {
        shellSurface.close();
    }
}
