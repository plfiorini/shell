// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Liri.WaylandClient 1.0 as WC

BorderlessWindow {
    id: modalWindow

    signal closeRequested()

    screen: null

    WC.WlrLayerSurfaceV1 {
        shell: layerShell
        layer: WC.WlrLayerShellV1.TopLayer
        window: modalWindow
        showOnAllScreens: !modalWindow.screen
        anchors: WC.WlrLayerSurfaceV1.LeftAnchor |
                 WC.WlrLayerSurfaceV1.RightAnchor |
                 WC.WlrLayerSurfaceV1.TopAnchor |
                 WC.WlrLayerSurfaceV1.BottomAnchor
        keyboardInteractivity: true
        nameSpace: "modal"

        onConfigured: {
            modalWindow.width = width;
            modalWindow.height = height;
            console.debug("Configuring", nameSpace, "to", modalWindow.width + "x" + modalWindow.height);
            ackConfigure(serial);
            console.debug("Acked", nameSpace, "configure with serial", serial);
            modalWindow.visible = true;
        }
        onClosed: {
            modalWindow.closeRequested();
        }
    }
}
