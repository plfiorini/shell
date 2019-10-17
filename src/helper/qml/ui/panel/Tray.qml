// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import QtQuick.Controls.Material 2.0
import Fluid.Effects 1.0 as FluidEffects

Rectangle {
    id: tray

    readonly property real elevation: 8

    anchors.margins: panelWindow.maximized ? 0 : elevation
    radius: 2
    color: Material.dialogColor

    layer.enabled: !panelWindow.maximized
    layer.effect: FluidEffects.Elevation {
        // Reference it as `tray.elevation` to avoid a circular
        // dependency on the `elevation` property of the effect
        elevation: tray.elevation
    }
}
