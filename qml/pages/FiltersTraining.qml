/*
 * Copyright 2017 Marcus Soll
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.vocabulary.Trainer 1.0
import harbour.vocabulary.SettingsProxy 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    property int language_id: -1
    property int number_vocabulary: 0

    property var filter_type: []
    property var filter_argv: []
    property int selected_modus: Trainer.TEST_BOTH

    DatePickerDialog {
        id: creation_since
        date: new Date()
        onAccepted: {
            switch_creation_since.checked = true
            functions.update_filters()
        }
        onRejected: {
            switch_creation_since.checked = false
            functions.update_filters()
        }
    }

    DatePickerDialog {
        id: creation_until
        date: new Date()
        onAccepted: {
            switch_creation_until.checked = true
            functions.update_filters()
        }
        onRejected: {
            switch_creation_until.checked = false
            functions.update_filters()
        }
    }

    DatePickerDialog {
        id: modification_since
        date: new Date()
        onAccepted: {
            switch_modification_since.checked = true
            functions.update_filters()
        }
        onRejected: {
            switch_modification_since.checked = false
            functions.update_filters()
        }
    }

    DatePickerDialog {
        id: modification_until
        date: new Date()
        onAccepted: {
            switch_modification_until.checked = true
            functions.update_filters()
        }
        onRejected: {
            switch_modification_until.checked = false
            functions.update_filters()
        }
    }

    Item {
        id: functions

        function load_languages() {
            languageModel.clear()
            var languages = language_interface.getAllLanguages()
            var language_id_correct = false
            languageModel.append({"lid": -1, "language": qsTr("All languages")})
            for(var i = 0; i < languages.length; ++i) {
                if(languages[i] === page.language_id) {
                    language_id_correct = true
                }

                languageModel.append({"lid": languages[i], "language": language_interface.getLanguageName(languages[i])})
            }

            if(!language_id_correct) {
                page.language_id = -1
            }
        }

        function update_filters() {
            var filter_type = []
            var filter_argv = []

            // Language

            if(language_id !== -1) {
                filter_type.push(Trainer.LANGUAGE)
                filter_argv.push(page.language_id)
            }

            // Dates

            if(switch_creation_since.checked) {
                filter_type.push(Trainer.CREATION_SINCE)
                filter_argv.push(creation_since.date)
            }

            if(switch_creation_until.checked) {
                filter_type.push(Trainer.CREATION_UNTIL)
                filter_argv.push(creation_until.date)
            }

            if(switch_modification_since.checked) {
                filter_type.push(Trainer.MODIFICATION_SINCE)
                filter_argv.push(modification_since.date)
            }

            if(switch_modification_until.checked) {
                filter_type.push(Trainer.MODIFICATION_UNTIL)
                filter_argv.push(modification_until.date)
            }

            // Minimum priority

            if(minimum_priority.value !== 0) {
                filter_type.push(Trainer.MINIMUM_PRIORITY)
                filter_argv.push(minimum_priority.value)
            }

            // Update

            page.number_vocabulary = trainer.count_vocabulary(filter_type, filter_argv)
            page.filter_type = filter_type
            page.filter_argv = filter_argv
        }
    }

    Trainer {
        id: trainer
    }

    SettingsProxy {
        id: settings_proxy
    }

    Component.onCompleted: {
        // Load settings
        page.language_id = settings_proxy.trainingFilterLanguage

        switch_creation_since.checked = settings_proxy.trainingFilterCreationSinceEnabled
        switch_creation_until.checked = settings_proxy.trainingFilterCreationUntilEnabled
        switch_modification_since.checked = settings_proxy.trainingFilterModificationSinceEnabled
        switch_modification_until.checked = settings_proxy.trainingFilterModificationUntilEnabled

        creation_since.date = settings_proxy.trainingFilterCreationSinceDate
        creation_until.date = settings_proxy.trainingFilterCreationUntilDate
        modification_since.date = settings_proxy.trainingFilterModificationSinceDate
        modification_until.date = settings_proxy.trainingFilterModificationUntilDate

        minimum_priority.value = settings_proxy.trainingFilterPriority

        // Call initialising functions
        functions.load_languages()
        functions.update_filters()
    }

    ListModel {
        id: languageModel
    }

    SilicaFlickable {
        anchors.fill: parent

        VerticalScrollDecorator {}

        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                text: qsTr("Reset to default")
                onClicked: {
                    page.language_id = -1

                    switch_creation_since.checked = false
                    switch_creation_until.checked = false
                    switch_modification_since.checked = false
                    switch_modification_until.checked = false

                    creation_since.date = new Date()
                    creation_until.date = new Date()
                    modification_since.date = new Date()
                    modification_until.date = new Date()

                    minimum_priority.value = 0

                    functions.update_filters()
                }
            }
        }

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Select training options")
            }

            Row {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }

                Label {
                    text: qsTr("Number vocabulary:")
                }
                Label {
                    text: " "
                }
                Label {
                    text: "" + page.number_vocabulary
                    color: Theme.secondaryColor
                }
            }

            Button {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                width: parent.width
                text: qsTr("Start training")
                enabled: page.number_vocabulary !== 0
                onClicked: {
                    settings_proxy.trainingFilterLanguage = page.language_id

                    settings_proxy.trainingFilterCreationSinceEnabled = switch_creation_since.checked
                    settings_proxy.trainingFilterCreationUntilEnabled = switch_creation_until.checked
                    settings_proxy.trainingFilterModificationSinceEnabled = switch_modification_since.checked
                    settings_proxy.trainingFilterModificationUntilEnabled = switch_modification_until.checked

                    settings_proxy.trainingFilterCreationSinceDate = creation_since.date
                    settings_proxy.trainingFilterCreationUntilDate = creation_until.date
                    settings_proxy.trainingFilterModificationSinceDate = modification_since.date
                    settings_proxy.trainingFilterModificationUntilDate = modification_until.date

                    settings_proxy.trainingFilterPriority = minimum_priority.value


                    pageStack.replace(Qt.resolvedUrl("Training.qml"), { filter_type: page.filter_type, filter_argv: page.filter_argv, selected_modus: page.selected_modus } )
                }
            }

            ComboBox {
                id: modus
                label: qsTr("Training modus")
                menu: ContextMenu {
                    MenuItem { text: qsTr("Both ways"); onClicked: page.selected_modus = Trainer.TEST_BOTH }
                    MenuItem { text: qsTr("Guess translation"); onClicked: page.selected_modus = Trainer.GUESS_TRANSLATION }
                    MenuItem { text: qsTr("Guess word"); onClicked: page.selected_modus = Trainer.GUESS_WORD }
                }
            }

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.paddingLarge
                }

                text: qsTr("Language:")
            }

            Repeater {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                model: languageModel

                delegate: ListItem {
                    width: parent.width
                    Label {
                        anchors.centerIn: parent
                        width: parent.width - 2*Theme.horizontalPageMargin
                        text: language
                        color: page.language_id === lid ? Theme.primaryColor : Theme.secondaryColor
                        font.bold: page.language_id === lid
                        horizontalAlignment: Text.AlignHCenter
                        truncationMode: TruncationMode.Fade
                    }

                    onClicked: {
                        page.language_id = lid
                        functions.update_filters()
                    }
                }
            }

            TextSwitch {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                id: switch_creation_since
                automaticCheck: false
                text: qsTr("Vocabulary creation date after")
                onClicked: {
                    pageStack.push(creation_since)
                }
            }

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                text: creation_since.date.toLocaleDateString()
                color: Theme.secondaryColor
                visible: switch_creation_since.checked
            }

            TextSwitch {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                id: switch_creation_until
                automaticCheck: false
                text: qsTr("Vocabulary creation date before")
                onClicked: {
                    pageStack.push(creation_until)
                }
            }

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                text: creation_until.date.toLocaleDateString()
                color: Theme.secondaryColor
                visible: switch_creation_until.checked
            }

            TextSwitch {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                id: switch_modification_since
                automaticCheck: false
                text: qsTr("Vocabulary modification date after")
                onClicked: {
                    pageStack.push(modification_since)
                }
            }

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                text: modification_since.date.toLocaleDateString()
                color: Theme.secondaryColor
                visible: switch_modification_since.checked
            }

            TextSwitch {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                id: switch_modification_until
                automaticCheck: false
                text: qsTr("Vocabulary modification date before")
                onClicked: {
                    pageStack.push(modification_until)
                }
            }

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                text: modification_until.date.toLocaleDateString()
                color: Theme.secondaryColor
                visible: switch_modification_until.checked
            }

            Slider {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }

                id: minimum_priority
                stepSize: 1
                minimumValue: 0
                maximumValue: 100
                value: 0
                label: qsTr("Minimum priority")
                valueText: "" + value

                onReleased: {
                    functions.update_filters()
                }
            }
        }
    }

    UpperPanel {
        id: panel
        text: qsTr("Can not save change to vocabulary")
    }
}

