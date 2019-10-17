// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Liri.WaylandClient 1.0 as WC
import "components" as Components
import "ui/panel" as Panel

Components.UiWindow {
    id: panelWindow

    readonly property alias maximized: panel.maximized

    screen: primaryScreen

    WC.WlrLayerSurfaceV1 {
        shell: layerShell
        layer: WC.WlrLayerShellV1.TopLayer
        window: panelWindow
        showOnAllScreens: false
        size.height: panel.height * 2
        anchors: WC.WlrLayerSurfaceV1.LeftAnchor |
                 WC.WlrLayerSurfaceV1.RightAnchor |
                 WC.WlrLayerSurfaceV1.BottomAnchor
        topMargin: -panel.height
        exclusiveZone: 10
        keyboardInteractivity: false
        nameSpace: "panel"

        onConfigured: {
            panelWindow.width = width;
            panelWindow.height = height;
            console.debug("Configuring panel to " + panelWindow.width + "x" + panelWindow.height);
            ackConfigure(serial);
            console.debug("Acked panel configure with serial", serial);
            addMask(Qt.rect(0, height - panel.height, width, panel.height));
            panelWindow.configured = true;
            panelWindow.visible = true;
        }
        onClosed: {
            panelWindow.close();
        }
    }

    Panel.Panel {
        id: panel

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }
}
