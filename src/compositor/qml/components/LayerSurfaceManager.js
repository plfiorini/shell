// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

.pragma library
.import Liri.WaylandServer 1.0 as WS

function getParentForLayer(layerSurface, output) {
    if (layerSurface.nameSpace === "lockscreen")
        return output.layers.lockScreen;
    else if (layerSurface.nameSpace === "notification")
        return output.layers.notifications;

    switch (layerSurface.layer) {
    case WS.WlrLayerShellV1.BackgroundLayer:
        return output.layers.background;
    case WS.WlrLayerShellV1.BottomLayer:
        return output.layers.bottom;
    case WS.WlrLayerShellV1.TopLayer:
        return output.layers.top;
    case WS.WlrLayerShellV1.OverlayLayer:
        return output.layers.overlay;
    default:
        break;
    }

    return undefined;
}

function getLayerPriority(layerSurface) {
    if (layerSurface.nameSpace === "panel")
        return 0;
    else if (layerSurface.nameSpace === "indicators")
        return 2;
    else if (layerSurface.nameSpace === "modal")
        return 20;
    return 0;
}
