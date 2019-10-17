// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Liri.WaylandClient 1.0 as WC
import "components" as Components
import "ui/panel" as Panel

Components.UiWindow {
    id: indicatorsWindow

    screen: primaryScreen

    WC.WlrLayerSurfaceV1 {
        shell: layerShell
        layer: WC.WlrLayerShellV1.TopLayer
        window: indicatorsWindow
        showOnAllScreens: false
        size.width: indicatorsRow.width
        size.height: indicatorsRow.height
        anchors: WC.WlrLayerSurfaceV1.RightAnchor |
                 WC.WlrLayerSurfaceV1.BottomAnchor
        keyboardInteractivity: false
        nameSpace: "indicators"

        onConfigured: {
            indicatorsWindow.width = width;
            indicatorsWindow.height = height;
            console.debug("Configuring indicators to " + indicatorsWindow.width + "x" + indicatorsWindow.height);
            ackConfigure(serial);
            console.debug("Acked indicators configure with serial", serial);
            indicatorsWindow.configured = true;
            indicatorsWindow.visible = true;
        }
        onClosed: {
            indicatorsWindow.close();
        }
    }

    Panel.IndicatorsRow {
        id: indicatorsRow
    }
}
