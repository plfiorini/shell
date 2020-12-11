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
import QtQuick.Controls.Material 2.0
import QtWayland.Compositor 1.3
import Liri.WaylandServer 1.0 as WS
import Fluid.Effects 1.0 as FluidEffects
import "LayerSurfaceManager.js" as LayerSurfaceManager

WaylandQuickItem {
    id: layerSurfaceItem

    property Item containerItem: layerSurfaceItem
    property bool honorAnchors: true
    property WS.WlrLayerSurfaceV1 layerSurface: null
    property real implicitSurfaceWidth: Math.max(0, implicitWidth)
    property real implicitSurfaceHeight: Math.max(0, implicitHeight)
    readonly property real surfaceWidth: Math.max(layerSurface.width, implicitSurfaceWidth)
    readonly property real surfaceHeight: Math.max(layerSurface.height, implicitSurfaceHeight)

    focusOnClick: layerSurface.keyboardInteractivity
    visible: layerSurface && layerSurface.mapped && layerSurface.configured

    onVisibleChanged: {
        if (visible && layerSurface && layerSurface.keyboardInteractivity)
            takeFocus();
    }

    Connections {
        target: layerSurface

        function onChanged() {
            setupAnchors();
            sendConfigure();
        }
        function onLayerChanged() {
            var newParent = LayerSurfaceManager.getParentForLayer(layerSurface, output);
            containerItem.parent = newParent;
        }
    }

    function setupAnchors() {
        // Some kind of layer surfaces should not be anchored
        if (!containerItem.honorAnchors) {
            containerItem.anchors.left = undefined;
            containerItem.anchors.right = undefined;
            containerItem.anchors.top = undefined;
            containerItem.anchors.bottom = undefined;
            containerItem.anchors.horizontalCenter = undefined;
            containerItem.anchors.verticalCenter = undefined;
            containerItem.anchors.leftMargin = 0;
            containerItem.anchors.rightMargin = 0;
            containerItem.anchors.topMargin = 0;
            containerItem.anchors.bottomMargin = 0;
            return;
        }

        var hasLeft = layerSurface.anchors & WS.WlrLayerSurfaceV1.LeftAnchor;
        var hasRight = layerSurface.anchors & WS.WlrLayerSurfaceV1.RightAnchor;
        var hasTop = layerSurface.anchors & WS.WlrLayerSurfaceV1.TopAnchor;
        var hasBottom = layerSurface.anchors & WS.WlrLayerSurfaceV1.BottomAnchor;

        if (!hasLeft && !hasRight) {
            containerItem.anchors.left = undefined;
            containerItem.anchors.right = undefined;
            containerItem.anchors.horizontalCenter = containerItem.parent.horizontalCenter;
            implicitSurfaceWidth = 0;
        } else {
            containerItem.anchors.horizontalCenter = undefined;
            containerItem.anchors.left = hasLeft ? containerItem.parent.left : undefined;
            containerItem.anchors.right = hasRight ? containerItem.parent.right : undefined;
            implicitSurfaceWidth = hasLeft && hasRight ? containerItem.parent.width : 0;
        }
        if (!hasTop && !hasBottom) {
            containerItem.anchors.top = undefined;
            containerItem.anchors.bottom = undefined;
            containerItem.anchors.verticalCenter = containerItem.parent.verticalCenter;
            implicitSurfaceHeight = 0;
        } else {
            containerItem.anchors.verticalCenter = undefined;
            containerItem.anchors.top = hasTop ? containerItem.parent.top : undefined;
            containerItem.anchors.bottom = hasBottom ? containerItem.parent.bottom : undefined;
            implicitSurfaceHeight = hasTop && hasBottom ? containerItem.parent.height : 0;
        }

        if (hasLeft)
            containerItem.anchors.leftMargin = layerSurface.leftMargin;
        if (hasRight)
            containerItem.anchors.rightMargin = layerSurface.rightMargin;
        if (hasTop)
            containerItem.anchors.topMargin = layerSurface.topMargin;
        if (hasBottom)
            containerItem.anchors.bottomMargin = layerSurface.bottomMargin;
    }

    function sendConfigure() {
        if (surfaceWidth >= 0 && surfaceHeight >= 0) {
            console.debug("Layer surface", layerSurface.nameSpace, "size:", surfaceWidth + "x" + surfaceHeight);
            layerSurface.sendConfigure(surfaceWidth, surfaceHeight);
        }
    }

    function reconfigure() {
        setupAnchors();

        if (layerSurface.configured)
            sendConfigure();
    }
}
