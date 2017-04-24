#set -x
#permanent in gnome:
setup_gconf() {
local toolname=${1?:missing toolname}
while read var value;do
	type=string
	case "$var" in \#*) continue;;esac
	case "$value" in true|false) type=bool;; [0-9]*) type=int;; "["*) type="list --list-type string";;esac
	case $toolname in
		gconf*) (set -x;$toolname -t $type -s $var "$value");;
		mate*)  (set -x;$toolname -t $type -s ${var//gnome/mate} "$value");;
	esac
done <<EOF
/desktop/gnome/peripherals/keyboard/kbd/options [lv3	lv3:rctrl_rshift_toggle,ctrl		ctrl:nocaps,grp	grp:shifts_toggle,ctrl	ctrl:nocaps]
#/desktop/gnome/peripherals/keyboard/kbd/layouts [us	altgr-intl,us	alt-intl,us,es]
/desktop/gnome/peripherals/keyboard/kbd/layouts [us	,es]
/apps/gnome-terminal/keybindings/switch_to_tab_1 <Control>1
/apps/gnome-terminal/keybindings/switch_to_tab_2 <Control>2
/apps/gnome-terminal/keybindings/switch_to_tab_3 <Control>3
/apps/gnome-terminal/keybindings/switch_to_tab_4 <Control>4
/apps/gnome-terminal/keybindings/switch_to_tab_5 <Control>5
/apps/gnome-terminal/keybindings/switch_to_tab_6 <Control>6
/apps/gnome-terminal/keybindings/switch_to_tab_7 <Control>7
/apps/gnome-terminal/keybindings/switch_to_tab_8 <Control>8
/apps/gnome-terminal/keybindings/switch_to_tab_9 <Control>9
/apps/gnome-terminal/profiles/Default/use_theme_colors false
/apps/gnome-terminal/profiles/Default/background_type solid
/apps/gnome-terminal/profiles/Default/background_color #000000000000
/apps/gnome-terminal/profiles/Default/foreground_color #FFFFFFFFFFFF
/apps/gnome-terminal/profiles/Default/use_menu_accelerators false
/apps/gnome-terminal/profiles/Default/use_mnemonics false
/apps/gnome_settings_daemon/keybindings/screensaver Pause
/apps/metacity/global_keybindings/switch_to_workspace_1 <Alt>F1
/apps/metacity/global_keybindings/switch_to_workspace_2 <Alt>F2
/apps/metacity/global_keybindings/switch_to_workspace_3 <Alt>F3
/apps/metacity/global_keybindings/switch_to_workspace_4 <Alt>F4
/apps/compiz-1/plugins/unityshell/screen0/options/execute_command <Shift><Alt>F2
/apps/compiz-1/plugins/unityshell/screen0/options/keyboard_focus = <Shift><Alt>F1
#flap it:
/desktop/gnome/peripherals/TPPS@47@2@32@IBM@32@TrackPoint/wheel_emulation false
/desktop/gnome/peripherals/TPPS@47@2@32@IBM@32@TrackPoint/wheel_emulation_button 3
/desktop/gnome/peripherals/TPPS@47@2@32@IBM@32@TrackPoint/wheel_emulation_x_axis false
/desktop/gnome/peripherals/TPPS@47@2@32@IBM@32@TrackPoint/wheel_emulation_x_axis true
/desktop/gnome/peripherals/TPPS@47@2@32@IBM@32@TrackPoint/wheel_emulation_button 2
/desktop/gnome/peripherals/TPPS@47@2@32@IBM@32@TrackPoint/wheel_emulation true
EOF
}
setup_gsettings(){
while read schema key value;do
	[[ $schema =~ \#.* ]] && continue
	(set -x;gsettings set $schema $key "$value")
done <<EOF
org.gnome.settings-daemon.plugins.media-keys screensaver 'Pause'
org.gnome.libgnomekbd.keyboard options @as ['ctrl:nocaps', 'ctrltctrl:nocaps', 'ctrl	ctrl:nocaps', 'grp	grp:shifts_toggle']
#org.gnome.libgnomekbd.keyboard layouts @as ['us	altgr-intl', 'us	intl', 'us', 'es']
org.gnome.libgnomekbd.keyboard layouts @as ['us	altgr-intl', 'es']
org.mate.Marco.global-keybindings panel-run-dialog '<Shift><Alt>F2'
org.mate.Marco.global-keybindings panel-main-menu '<Shift><Alt>F1'
org.mate.Marco.window-keybindings close '<Shift><Alt>F4'
org.mate.Marco.global-keybindings switch-to-workspace-1 '<Alt>F1'
org.mate.Marco.global-keybindings switch-to-workspace-2 '<Alt>F2'
org.mate.Marco.global-keybindings switch-to-workspace-3 '<Alt>F3'
org.mate.Marco.global-keybindings switch-to-workspace-4 '<Alt>F4'
org.mate.SettingsDaemon.plugins.media-keys screensaver 'Pause'
org.gnome.shell.overrides workspaces-only-on-primary false
EOF
}

#NOW!
setup_now(){
(set -x
ids=$(xinput list | sed -rn '/IBM.TrackPoint/s/.*id=([0-9]+).*/\1/p')
for id in $ids;do
	xinput set-int-prop $id "Evdev Wheel Emulation" 8 1
	xinput set-int-prop $id "Evdev Wheel Emulation Button" 8 2
	xinput set-int-prop $id "Evdev Wheel Emulation Axes" 8 6 7 4 5
done
setxkbmap -option ctrl:nocaps us altgr-intl
#disable thinkpad trackpad
trackpad_id=$(xinput list|sed -nr '/Synaptics.TouchPad/s/.*id=([0-9]+).*/\1/p')
test -n "$trackpad_id" && xinput set-prop $trackpad_id "Device Enabled" 0
)
}
setup_dconf() {
	dconf write /org/mate/desktop/keybindings/custom0/binding "'<Mod4>1'"
	dconf write /org/mate/desktop/keybindings/custom0/name "'terminator'"
	dconf write /org/mate/desktop/keybindings/custom0/action "'/home/jjo/bin/jjo-run1.sh terminator'"
	dconf write /org/mate/desktop/keybindings/custom1/binding "'<Mod4>2'"
	dconf write /org/mate/desktop/keybindings/custom1/name "'chromium-browser'"
	dconf write /org/mate/desktop/keybindings/custom1/action "'/home/jjo/bin/jjo-run1.sh chromium-browser'"
	dconf write /org/mate/desktop/keybindings/custom2/binding "'<Mod4>3'"
	dconf write /org/mate/desktop/keybindings/custom2/name "'google-chrome'"
	dconf write /org/mate/desktop/keybindings/custom2/action "'/home/jjo/bin/jjo-run1.sh google-chrome'"
}

test -x /usr/bin/gconftool      && setup_gconf gconftool
test -x /usr/bin/mateconftool-2 && {
	setup_gconf mateconftool-2
	mateconftool-2 --set /apps/marco/general/button_layout --type string "close,minimize,maximize"
}
test -x /usr/bin/gsettings      && setup_gsettings
test -x /usr/bin/dconf          && setup_dconf
setup_now
