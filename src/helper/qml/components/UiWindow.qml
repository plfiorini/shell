// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick 2.10
import QtQuick.Window 2.9

Window {
    property bool configured: false
    property bool registered: false

    flags: Qt.Window | Qt.BypassWindowManagerHint
    color: "transparent"
    visible: false

    onConfiguredChanged: {
        if (configured && !registered) {
            refCount--;
            registered = true;
        }
    }

    Component.onCompleted: {
        refCount++;
    }
}
