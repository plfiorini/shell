/****************************************************************************
 * This file is part of Kahai.
 *
 * Copyright (C) 2012-2014 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 *
 * Author(s):
 *    Pier Luigi Fiorini
 *
 * $BEGIN_LICENSE:GPL2+$
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
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

import QtQuick 2.0
import QtQuick.Controls 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "."
import "components"

Item {
    property string name
    property alias iconName: icon.iconName
    property alias text: label.text
    property string tooltip
    readonly property bool selected: selectedIndicator == indicator
    property Component component

    signal triggered(var caller)

    id: indicator
    width: {
        if (!visible)
            return 0;

        var size = 0;
        if (iconName)
            size += units.smallSpacing + icon.width;
        if (text)
            size += units.smallSpacing + label.width;
        if (iconName && text)
            size += units.smallSpacing;
        return size;
    }
    height: Math.max(icon.height, label.height)

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: indicator.triggered(indicator)
    }

    Icon {
        id: icon
        anchors.centerIn: parent
        color: selected ? Theme.panel.selectedTextColor : Theme.panel.textColor
        width: units.roundToIconSize(units.iconSizes.smallMedium)
        height: width
    }

    Label {
        id: label
        anchors.centerIn: parent
        color: Theme.panel.textColor
        font.pixelSize: units.roundToIconSize(units.iconSizes.small)
    }
}