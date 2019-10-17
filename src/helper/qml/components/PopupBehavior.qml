// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.0
import Fluid.Core 1.0 as FluidCore

FluidCore.Object {
    id: popupBehavior

    property alias sourceComponent: loader.sourceComponent
    readonly property alias opened: loader.active
    readonly property alias visible: loader.active
    property bool modal: false

    Loader {
        id: loader

        asynchronous: true
        active: false
        onStatusChanged: {
            if (modal) {
                if (status === Loader.Ready)
                    modalOverlayInstantiator.setVisible(true, item.screen);
                else if (status === Loader.Error)
                    modalOverlayInstantiator.setVisible(false);
            }
        }
    }

    function open() {
        loader.active = true;
    }

    function close() {
        loader.active = false;
    }
}
