// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.14
import QtQuick.Controls.Material 2.0
import Liri.WaylandClient 1.0 as WC
import "components" as Components

Components.BorderlessWindow {
    id: modalOverlayWindow

    color: Material.backgroundDimColor

    WC.WlrLayerSurfaceV1 {
        shell: layerShell
        layer: WC.WlrLayerShellV1.OverlayLayer
        window: modalOverlayWindow
        showOnAllScreens: false
        anchors: WC.WlrLayerSurfaceV1.LeftAnchor |
                 WC.WlrLayerSurfaceV1.RightAnchor |
                 WC.WlrLayerSurfaceV1.TopAnchor |
                 WC.WlrLayerSurfaceV1.BottomAnchor
        keyboardInteractivity: false
        nameSpace: "modal-overlay"

        onConfigured: {
            modalOverlayWindow.width = width;
            modalOverlayWindow.height = height;
            console.debug("Configuring modal overlay to " + modalOverlayWindow.width + "x" + modalOverlayWindow.height);
            ackConfigure(serial);
            console.debug("Acked modal overlay configure with serial", serial);
        }
        onClosed: {
            modalOverlayWindow.close();
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onTapped: {
            modalOverlayWindow.hide();
        }
    }
}
