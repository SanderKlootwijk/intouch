/*
 * Copyright (C) 2025  Sander Klootwijk
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * intouch is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Lomiri.Components 1.3
import QtQuick.Layouts 1.3

Page {
    id: settingsPage

    header: PageHeader {
        id: settingsPageHeader

        title: i18n.tr("Settings")
    }

    Flickable {
        id: settingsFlickable

        anchors {
            fill: parent
            topMargin: settingsPageHeader.height
        }

        contentWidth: settingsColumn.width
        contentHeight: settingsColumn.height

        Column {
            id: settingsColumn

            width: settingsPage.width

            ListItem {
                id: aboutListItem

                // height: units.gu(4)

                ListItemLayout {
                        id: layoutAbout
                        title.text : i18n.tr("About page")
                        ProgressionSlot {color: theme.palette.normal.baseText; }
                    }
                onClicked: pageStack.push(aboutPage)
            }

            ListItem {
                id: themeTitle

                height: units.gu(6.25)

                divider.colorFrom: theme.palette.normal.background
                divider.colorTo: theme.palette.normal.background

                Label {
                    id: themeTitleLabel

                    width: parent.width - units.gu(4)

                    anchors {
                        bottom: parent.bottom
                        bottomMargin: units.gu(1.25)
                        left: parent.left
                        leftMargin: units.gu(2)
                    }

                    text: i18n.tr("Theme") + ":"

                    elide: Text.ElideRight
                }
            }

            ListItem {
                id: themeListItem

                height: themeOptionSelector.height + units.gu(2)

                OptionSelector {
                    id: themeOptionSelector

                    width: parent.width - units.gu(4)

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                    }

                    model: [i18n.tr("System"), "Ambiance", "Suru Dark"]

                    onSelectedIndexChanged: settings.theme = selectedIndex

                    Component.onCompleted: selectedIndex = settings.theme
                }
            }

            ListItem {
                id: defaultTabTitle

                height: units.gu(6.25)

                divider.colorFrom: theme.palette.normal.background
                divider.colorTo: theme.palette.normal.background

                Label {
                    id: defaultTabTitleLabel

                    width: parent.width - units.gu(4)

                    anchors {
                        bottom: parent.bottom
                        bottomMargin: units.gu(1.25)
                        left: parent.left
                        leftMargin: units.gu(2)
                    }

                    text: i18n.tr("Default tab on startup") + ":"

                    elide: Text.ElideRight
                }
            }

            ListItem {
                id: defaultTabListItem

                height: defaultTabOptionSelector.height + units.gu(2)

                OptionSelector {
                    id: defaultTabOptionSelector

                    width: parent.width - units.gu(4)

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                    }

                    model: [i18n.tr("Categories"), i18n.tr("Recent topics")]

                    onSelectedIndexChanged: settings.defaultTab = selectedIndex

                    Component.onCompleted: selectedIndex = settings.defaultTab
                }
            }
        }
    }

    Scrollbar {
        id: settingsScrollbar

        flickableItem: settingsFlickable
        align: Qt.AlignTrailing
    }
}