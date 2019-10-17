// SPDX-FileCopyrightText: 2020 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later

#include "qmlauthenticator.h"

QmlAuthenticator::QmlAuthenticator(QObject *parent)
    : QObject(parent)
    , m_authenticator(new Authenticator(this))
{
    connect(m_authenticator, &Authenticator::authenticationSucceded, this, [this] {
        m_succeded = true;
        executeCallback();
    });
    connect(m_authenticator, &Authenticator::authenticationFailed, this, [this] {
        m_succeded = false;
        executeCallback();
    });
    connect(m_authenticator, &Authenticator::authenticationError, this, [this] {
        m_succeded = false;
        executeCallback();
    });
}

void QmlAuthenticator::authenticate(const QString &password, const QJSValue &callback)
{
    if (m_authRequested)
        return;

    // Prevent another authentication, until we executed the callback
    m_authRequested = true;

    // Authenticate and execute the callback
    m_lastCallback = callback;
    m_authenticator->authenticate(password);
}

void QmlAuthenticator::executeCallback()
{
    if (m_lastCallback.isCallable())
        m_lastCallback.call(QJSValueList() << m_succeded);

    // New authentication requests can now be fulfilled
    m_succeded = false;
    m_authRequested = false;
}
