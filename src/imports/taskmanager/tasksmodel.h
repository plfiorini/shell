/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2019 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
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

#ifndef TASKSMODEL_H
#define TASKSMODEL_H

#include <QSortFilterProxyModel>
#include <QQmlComponent>

class Application;
class ApplicationsModel;

class TasksModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(bool hasMaximizedWindow READ hasMaximizedWindow NOTIFY hasMaximizedWindowChanged)
public:
    explicit TasksModel(QObject *parent = nullptr);

    void setSourceModel(QAbstractItemModel *sourceModel) override;

    bool hasMaximizedWindow() const;

    Q_INVOKABLE Application *get(int row) const;
    Q_INVOKABLE int indexFromAppId(const QString &appId) const;

Q_SIGNALS:
    void hasMaximizedWindowChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &sourceLeft, const QModelIndex &sourceRight) const override;

private:
    ApplicationsModel *m_appsModel = nullptr;
};

QML_DECLARE_TYPE(TasksModel)

#endif // TASKSMODEL_H
