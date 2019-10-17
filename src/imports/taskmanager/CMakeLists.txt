if(NOT TARGET Liri::Qt5GSettings)
    find_package(Qt5GSettings REQUIRED)
endif()
if(NOT TARGET Liri::Xdg)
    find_package(Liri1Xdg REQUIRED)
endif()
if(NOT TARGET Liri::WaylandClient)
    find_package(Liri1WaylandClient REQUIRED)
endif()

liri_add_qml_plugin(taskmanager
    MODULE_PATH
        "Liri/TaskManager"
    VERSION
        "1.0"
    SOURCES
        application.cpp
        application.h
        applicationsmodel.cpp
        applicationsmodel.h
        appusage.cpp
        appusage.h
        categoriesmodel.cpp
        categoriesmodel.h
        frequentmodel.cpp
        frequentmodel.h
        pagemodel.cpp
        pagemodel.h
        plugin.cpp
        tasksmodel.cpp
        tasksmodel.h
        usagetracker.cpp
        usagetracker.h
        xdgutils.cpp
        xdgutils.h
    QML_FILES
        qmldir
    DEFINES
        QT_NO_CAST_FROM_ASCII
        QT_NO_FOREACH
    PUBLIC_LIBRARIES
        Qt5::Core
        Qt5::Concurrent
        Qt5::Gui
        Qt5::GuiPrivate
        Liri::Qt5GSettings
        Liri::Xdg
        Liri::WaylandClient
)
