/***************************************************************************
 *   Copyright (C) 2020 by MakG <makg@makg.eu>                             *
 ***************************************************************************/

import QtQuick 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
	id: root
	
	Layout.fillWidth: true
	Layout.fillHeight: true
	width: 250
	height: 200
	
	Plasmoid.toolTipTextFormat: Text.RichText
	
	ProfilesModel {
		id: profilesModel
	}
	
	Component.onCompleted: {
		reloadProfileModel();
	}
	
	Connections {
		target: plasmoid.configuration
		
		function onProfilesChanged() {
			reloadProfileModel();
		}
	}
	
	Plasmoid.compactRepresentation: Item {
		PlasmaCore.IconItem {
			anchors.fill: parent
			source: "video-display"
		}
		
		
		MouseArea {
			id: mouseArea
			anchors.fill: parent
			
			onClicked: {
				plasmoid.expanded = !plasmoid.expanded
			}
		}
	}
	
	Plasmoid.fullRepresentation: Item {
		Layout.preferredWidth: 250
		Layout.preferredHeight: 200

		PlasmaExtras.ScrollArea {
			width: parent.width
			height: parent.height
		
			ListView {
				id: profilesListView
				anchors.fill: parent
				model: profilesModel
				highlight: PlasmaComponents.Highlight { }
				highlightMoveDuration: 0
				highlightResizeDuration: 0
				currentIndex: -1
				delegate: PlasmaComponents.ListItem {
					height: label.height + 5
    				enabled: true

					onClicked: {
						execSwitcherDS.switchProfile(model.config)
						plasmoid.expanded = false
					}

					Item {
						id: label
						height: childrenRect.height
						anchors {
							left: parent.left
							leftMargin: 5
							right: parent.right
							verticalCenter: parent.verticalCenter
						}

						PlasmaComponents.Label {
							width: parent.width
							height: undefined // unset PlasmaComponents.Label default height
							maximumLineCount: 2
							verticalAlignment: Text.AlignVCenter

							text: model.name
							elide: Text.ElideRight
							wrapMode: Text.WrapAtWordBoundaryOrAnywhere
							textFormat: Text.StyledText
						}
					}

					onContainsMouseChanged: {
						if (containsMouse) {
							profilesListView.currentIndex = index
						} else {
							profilesListView.currentIndex = -1
						}
					}
				}
			}
		}
		
		PlasmaComponents.Button {
			anchors.centerIn: parent
			text: i18n("Configure...")
			visible: profilesModel.count == 0
			onClicked: plasmoid.action("configure").trigger();
		}
	}

	PlasmaCore.DataSource {
		id: execSwitcherDS
		engine: "executable"
		connectedSources: []

		onNewData: {
			exited(sourceName, data.stdout)
			disconnectSource(sourceName)
		}
		
		function switchProfile(profileConfig) {
			connectSource("python3 ~/.local/share/plasma/plasmoids/eu.makg.plasma.display-profile-switcher/display-profile-switcher.py load " + profileConfig)
		}

		signal exited(string sourceName, string stdout)
	}
	
	function reloadProfileModel() {
		profilesModel.clear();
		
		var profiles = JSON.parse(plasmoid.configuration.profiles);
		
		for(var i = 0; i < profiles.length; i++) {
			if(profiles[i].active) {
				profilesModel.append(profiles[i]);
			}
		}
	}
	
	function switchProfile(index) {
		execSwitcherDS.switchProfile(profilesModel.get(index).config)
	}
}
