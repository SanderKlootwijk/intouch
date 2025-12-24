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
import "../components"

Page {
    id: categoryPage

    property bool categoryTopicsLoading: false
    property string categorySlug: ""
    property int currentPage: 0
    property int pageCount: 0

    Component.onCompleted: fetchCategoryTopics(categorySlug, 1);

    header: PageHeader {
        id: categoryPageHeader
        title: ""
    }

    ProgressBar {
        visible: categoryTopicsLoading

        anchors {
            top: categoryPageHeader.bottom
            left: parent.left
            right: parent.right
        }

        indeterminate: true
    }

    ListModel {
        id: subCategoriesListModel
    }

    ListModel {
        id: topicsListModel
    }

    Flickable {
        id: categoryFlickable

        anchors {
            fill: parent
            topMargin: categoryPageHeader.height
        }

        contentWidth: categoryColumn.width
        contentHeight: categoryColumn.height

        Column {
            id: categoryColumn

            width: categoryPage.width

            Repeater {
                model: subCategoriesListModel
                delegate: CategoryListItem {}
            }

            ListItem {
                width: parent.width
                height: units.gu(5)

                visible: subCategoriesListModel.count > 0 && topicsListModel.count > 0

                Label {
                    anchors.centerIn: parent
                    
                    text: i18n.tr("Topics")
                }
            }

            Repeater {
                model: topicsListModel
                delegate: TopicListItem {}
            }
        }

        onAtYEndChanged: {
            if (currentPage < pageCount && !categoryTopicsLoading) {
                fetchCategoryTopics(categorySlug, currentPage + 1);
            }
        }
    }

    Scrollbar {
        id: categoryScrollbar

        flickableItem: categoryFlickable
        align: Qt.AlignTrailing
    }

    // Fetch topics for a given category slug
    function fetchCategoryTopics(slug, page) {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", "https://forums.ubports.com/api/category/" + slug + "?page=" + page, true);

        categoryTopicsLoading = true;

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    let data = JSON.parse(xhr.responseText);
                    let topics = data.topics;
                    let children = data.children;

                    categoryPageHeader.title = data.name.replace("&#x2F;", "/");
                    currentPage = page;
                    pageCount = data.pagination.pageCount;

                    for (let i = 0; i < topics.length; i++) {
                        topicsListModel.append({
                            "title": topics[i].titleRaw,
                            "postcount": topics[i].postcount,
                            "lastposttimeISO": topics[i].lastposttimeISO,
                            "pinned": topics[i].pinned,
                            "deleted": topics[i].deleted,
                            "picture": topics[i].user.picture == null ? "" : "https://forums.ubports.com/" + topics[i].user.picture,
                            "username": topics[i].user.username,
                            "bgColor": topics[i].user["icon:bgColor"],
                            "usernameText": topics[i].user["icon:text"],
                            "slug": topics[i].slug.toString()
                        });
                    }

                    if (page == 1) {
                        for (let j = 0; j < children.length; j++) {
                            subCategoriesListModel.append({
                                "name": children[j].name.replace("&#x2F;", "/"),
                                "icon": children[j].icon,
                                "iconColor": children[j].color,
                                "bgColor": children[j].bgColor,
                                "description": children[j].descriptionParsed.replace("<p>", "").replace("</p>", "").replace('<p dir="auto">', ""),
                                "slug": children[j].slug.toString()
                            });
                        }
                    }

                    categoryTopicsLoading = false;

                    console.log("Topics fetched successfully, page " + currentPage + "/" + pageCount);
                } else {
                    categoryTopicsLoading = false;

                    console.log("Failed to fetch topics:", xhr.status, xhr.statusText);
                }
            }
        };

        xhr.send();
    }
}