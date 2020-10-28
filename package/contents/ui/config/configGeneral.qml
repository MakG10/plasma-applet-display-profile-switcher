import QtQuick 2.1
import QtQuick.Controls 1.2
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0

import ".."

Item {
	id: configGeneral
	Layout.fillWidth: true
	
	property string cfg_profiles: plasmoid.configuration.profiles
	property int selectedProfile: -1

	readonly property string kcmName: "kcm_kscreen"
	readonly property bool kcmAllowed: KCMShell.authorize(kcmName + ".desktop").length > 0
	
	ProfilesModel {
		id: profilesModel
	}
	
	Component.onCompleted: {
		profilesModel.clear();
		
		var profiles = JSON.parse(cfg_profiles);
		
		for(var i = 0; i < profiles.length; i++) {
			profilesModel.append(profiles[i]);
		}
	}

	RowLayout {
		anchors.fill: parent
		
		Layout.alignment: Qt.AlignTop | Qt.AlignRight
		
		TableView {
			id: profilesTable
			model: profilesModel
			
			anchors.top: parent.top
			anchors.right: buttonsColumn.left
			anchors.bottom: parent.bottom
			anchors.left: parent.left
			anchors.rightMargin: 10
			
			TableViewColumn {
				role: "active"
				width: 20
				delegate: CheckBox {
					checked: model.active
					onClicked: {
						model.active = checked;
						
						saveConfig()
					}
				}
			}
			
			TableViewColumn {
				role: "name"
				title: "Name"
			}
			
			onDoubleClicked: {
				editProfile();
			}
			
			onActivated: {
				moveUp.enabled = row > 0;
				moveDown.enabled = row < profilesTable.model.count - 1;
			}
		}
		
		ColumnLayout {
			id: buttonsColumn
			
			anchors.top: parent.top
			
			PlasmaComponents.Button {
				text: "Create profile from current setup"
				iconSource: "list-add"
				
				onClicked: {
					execSwitcherDS.saveCurrentProfile()
				}
			}

			PlasmaComponents.Button {
				text: "Edit"
				iconSource: "edit-entry"
				
				onClicked: {
					editProfile();
				}
			}
			
			PlasmaComponents.Button {
				text: "Remove"
				iconSource: "list-remove"
				
				onClicked: {
					if(profilesTable.currentRow == -1) return;
					
					profilesTable.model.remove(profilesTable.currentRow);
					
					saveConfig()
				}
			}
			
			PlasmaComponents.Button {
				id: moveUp
				text: i18n("Move up")
				iconSource: "go-up"
				enabled: false
				
				onClicked: {
					if(profilesTable.currentRow == -1) return;
					
					profilesTable.model.move(profilesTable.currentRow, profilesTable.currentRow - 1, 1);
					profilesTable.selection.clear();
					profilesTable.selection.select(profilesTable.currentRow - 1);

					saveConfig()
				}
			}
			
			PlasmaComponents.Button {
				id: moveDown
				text: i18n("Move down")
				iconSource: "go-down"
				enabled: false
				
				onClicked: {
					if(profilesTable.currentRow == -1) return;
					
					profilesTable.model.move(profilesTable.currentRow, profilesTable.currentRow + 1, 1);
					profilesTable.selection.clear();
					profilesTable.selection.select(profilesTable.currentRow + 1);

					saveConfig()
				}
			}

			PlasmaComponents.Button {
				id: systemSettings
				text: i18n("System Settings")
				iconSource: "settings-configure"
				visible: kcmAllowed
				
				onClicked: {
					KCMShell.open(kcmName);
				}
			}
		}
	}

	Dialog {
		id: profileDialog
		visible: false
		title: "Profile"
		standardButtons: StandardButton.Save | StandardButton.Cancel
		
		onAccepted: {
			profilesModel.get(selectedProfile).name = profileName.text
			
			saveConfig()
		}

		ColumnLayout {
			GridLayout {
				columns: 2
				
				PlasmaComponents.Label {
					text: "Name:"
				}
				
				TextField {
					id: profileName
					Layout.minimumWidth: theme.mSize(theme.defaultFont).width * 40
				}
			}
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
		
		function saveCurrentProfile() {
			connectSource("python3 ~/.local/share/plasma/plasmoids/eu.makg.plasma.display-profile-switcher/display-profile-switcher.py save")
		}
		
		signal exited(string sourceName, string stdout)
	}
	
	Connections {
		target: execSwitcherDS

		onExited: {
			profilesModel.append({
				name: "New profile",
				active: true,
				config: stdout
			})

			saveConfig()
		}
	}

	function editProfile() {
		selectedProfile = profilesTable.currentRow;
		
		profileName.text = profilesModel.get(selectedProfile).name
		
		profileDialog.visible = true;
		profileName.focus = true;
	}

	function saveConfig() {
		cfg_profiles = JSON.stringify(getProfilesArray());
	}
	
	function getProfilesArray() {
		var profilesArray = [];
		
		for(var i = 0; i < profilesModel.count; i++) {
			profilesArray.push(profilesModel.get(i));
		}
		
		return profilesArray;
	}
}
