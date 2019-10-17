// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Liri.WaylandClient 1.0 as WC

BorderlessWindow {
    id: popupWindow

    property real itemWidth: 0
    property real itemHeight: 0

    signal closeRequested()

    screen: null

    WC.WlrLayerSurfaceV1 {
        shell: layerShell
        layer: WC.WlrLayerShellV1.TopLayer
        window: popupWindow
        size.width: itemWidth + 128
        size.height: itemHeight + 128
        showOnAllScreens: !popupWindow.screen
        keyboardInteractivity: true
        nameSpace: "popup"

        onConfigured: {
            popupWindow.width = width;
            popupWindow.height = height;
            console.debug("Configuring", nameSpace, "to", popupWindow.width + "x" + popupWindow.height);
            ackConfigure(serial);
            console.debug("Acked", nameSpace, "configure with serial", serial);
            popupWindow.visible = true;
        }
        onClosed: {
            popupWindow.closeRequested();
        }
    }
}
