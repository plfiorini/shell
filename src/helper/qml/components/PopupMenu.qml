// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.10
import QtQuick.Controls 2.10
import QtQuick.Controls.Material 2.10
import Fluid.Core 1.0 as FluidCore
import Liri.WaylandClient 1.0 as WC

PopupWindow {
    id: menuWindow

    default property alias contentData: menu.contentData

    itemWidth: menu.implicitWidth
    itemHeight: menu.implicitHeight

    onVisibleChanged: {
        if (visible)
            menu.open();
        else
            menu.close();
    }

    Menu {
        id: menu

        Material.primary: Material.Blue
        Material.accent: Material.Blue

        anchors.centerIn: parent

        onClosed: {
            menuWindow.closeRequested();
        }
    }
}
