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
import QtWayland.Compositor 1.2 as QtWayland
import Fluid.Core 1.0 as FluidCore

FluidCore.Object {
    id: window

    property QtWayland.XdgPopupV5 xdgPopup: null

    readonly property QtWayland.ShellSurface shellSurface: xdgPopup
    readonly property QtWayland.WaylandSurface surface: xdgPopup ? xdgPopup.surface : null
    readonly property QtWayland.WaylandSurface parentSurface: xdgPopup ? xdgPopup.parentSurface : null

    readonly property int windowType: Qt.Popup

    readonly property alias mapped: d.mapped
    readonly property alias offset: d.offset

    readonly property alias moveItem: moveItem

    readonly property rect windowGeometry: Qt.rect(0, 0, surface ? surface.size.width : -1, surface ? surface.size.height : -1)

    readonly property bool focusable: true

    QtObject {
        id: d

        property bool mapped: false
        property point offset: Qt.point(0, 0)
    }

    Connections {
        target: surface
        onHasContentChanged: {
            if (surface.hasContent)
                d.mapped = true;
        }
    }

    MoveItem {
        id: moveItem

        parent: rootItem
        width: windowGeometry.width
        height: windowGeometry.height
    }
}
