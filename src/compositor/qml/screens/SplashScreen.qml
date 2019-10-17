/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini
 *
 * Author(s):
 *    Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 *
 * $BEGIN_LICENSE:GPL3+$
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * $END_LICENSE$
 ***************************************************************************/

import QtQuick 2.10
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0

Rectangle {
    id: splash

    // Same color as Plymouth and SDDM
    color: Material.color(Material.BlueGrey, Material.Shade800)

    Material.theme: Material.Dark
    Material.primary: Material.Blue
    Material.accent: Material.Blue

    BusyIndicator {
        anchors.centerIn: parent
    }

    OpacityAnimator {
        id: showAnimation

        alwaysRunToEnd: true
        target: splash
        from: 0.0
        to: 1.0
        duration: 250
    }

    OpacityAnimator {
        id: hideAnimation

        alwaysRunToEnd: true
        target: splash
        from: 1.0
        to: 0.0
        duration: 250
    }

    function show() {
        showAnimation.start();
    }

    function hide() {
        if (opacity > 0.0)
            hideAnimation.start();
    }
}
