/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2018 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 *
 * $BEGIN_LICENSE:LGPLv3+$
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * $END_LICENSE$
 ***************************************************************************/

#include <Solid/DeviceNotifier>
#include <Solid/StorageAccess>

#include "storagedevice.h"
#include "storagemodel.h"

StorageModel::StorageModel(QObject *parent)
    : QAbstractListModel(parent)
{
    // Populate list as devices come and go
    Solid::DeviceNotifier *notifier = Solid::DeviceNotifier::instance();
    connect(notifier, &Solid::DeviceNotifier::deviceAdded, [this](const QString &udi) {
        Solid::Device device(udi);
        if (device.as<Solid::StorageAccess>()) {
            beginInsertRows(QModelIndex(), m_devices.size(), m_devices.size());
            StorageDevice *storageDevice = new StorageDevice(udi);
            m_devices.append(storageDevice);
            m_devicesMap[udi] = storageDevice;
            endInsertRows();
            Q_EMIT countChanged();
        }
    });
    connect(notifier, &Solid::DeviceNotifier::deviceRemoved, [this](const QString &udi) {
        StorageDevice *storageDevice = m_devicesMap.value(udi, nullptr);
        if (storageDevice) {
            int index = m_devices.indexOf(storageDevice);
            beginRemoveRows(QModelIndex(), index, index);
            m_devices.removeOne(storageDevice);
            m_devicesMap.remove(udi);
            storageDevice->deleteLater();
            endRemoveRows();
            Q_EMIT countChanged();
        }
    });

    // Add already existing devices
    for (const Solid::Device &device : Solid::Device::allDevices()) {
        if (device.as<Solid::StorageAccess>()) {
            beginInsertRows(QModelIndex(), m_devices.size(), m_devices.size());
            StorageDevice *storageDevice = new StorageDevice(device.udi());
            m_devices.append(storageDevice);
            m_devicesMap[device.udi()] = storageDevice;
            endInsertRows();
            Q_EMIT countChanged();
        }
    }
}

QHash<int, QByteArray> StorageModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(StorageDeviceRole, QByteArrayLiteral("storageDevice"));
    roles.insert(UdiRole, QByteArrayLiteral("udi"));
    roles.insert(NameRole, QByteArrayLiteral("name"));
    roles.insert(IconNameRole, QByteArrayLiteral("iconName"));
    roles.insert(FilePathRole, QByteArrayLiteral("filePath"));
    roles.insert(IsMountedRole, QByteArrayLiteral("mounted"));
    roles.insert(IsIgnoredRole, QByteArrayLiteral("ignored"));
    return roles;
}

int StorageModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_devices.size();
}

QVariant StorageModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    if (index.row() >= m_devices.size())
        return QVariant();

    StorageDevice *storageDevice = m_devices.at(index.row());

    switch (role) {
    case StorageDeviceRole:
        return qVariantFromValue(storageDevice);
    case UdiRole:
        return storageDevice->udi();
    case NameRole:
        return storageDevice->name();
    case IconNameRole:
        return storageDevice->iconName();
    case FilePathRole:
        return storageDevice->filePath();
    case IsMountedRole:
        return storageDevice->isMounted();
    case IsIgnoredRole:
        return storageDevice->isIgnored();
    default:
        break;
    }

    return QVariant();
}
