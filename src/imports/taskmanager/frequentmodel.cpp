/****************************************************************************
 * This file is part of Liri.
 *
 * Copyright (C) 2019 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
 * Copyright (C) 2017 Michael Spencer <sonrisesoftware@gmail.com>
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

#include <QtCore/QDebug>
#include <QtCore/QFileInfo>

#include "applicationsmodel.h"
#include "frequentmodel.h"
#include "usagetracker.h"

// FIXME: This old code might not be completely right
QString appIdFromDesktopFile(const QString &desktopFile)
{
    return QFileInfo(desktopFile).completeBaseName();
}

FrequentAppsModel::FrequentAppsModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    sort(0, Qt::DescendingOrder);

    connect(UsageTracker::instance(), &UsageTracker::updated,
            this, &FrequentAppsModel::invalidate);
}

bool FrequentAppsModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    QModelIndex sourceIndex = sourceModel()->index(sourceRow, 0, sourceParent);
    QString appId = sourceModel()->data(sourceIndex, ApplicationsModel::AppIdRole).toString();

    AppUsage *app = UsageTracker::instance()->usageForAppId(appId);

    return app != nullptr && app->score > 0;
}

bool FrequentAppsModel::lessThan(const QModelIndex &source_left,
                                 const QModelIndex &source_right) const
{
    QString leftAppId = sourceModel()->data(source_left, ApplicationsModel::AppIdRole).toString();
    QString rightAppId = sourceModel()->data(source_right, ApplicationsModel::AppIdRole).toString();

    AppUsage *leftApp = UsageTracker::instance()->usageForAppId(leftAppId);
    AppUsage *rightApp = UsageTracker::instance()->usageForAppId(rightAppId);

    if (leftApp == nullptr)
        return false;
    else if (rightApp == nullptr)
        return true;
    else
        return leftApp->score < rightApp->score;
}
