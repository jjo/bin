#set -x
#permanent in gnome:
setup_gconftool2() {
while read var value;do
	type=string
	case "$var" in \#*) continue;;esac
	case "$value" in true|false) type=bool;; [0-9]*) type=int;; "["*) type="list --list-type string";;esac
	(set -x;gconftool -t $type -s $var "$value")
done <<EOF
/desktop/gnome/peripherals/keyboard/kbd/options [lv3 lv3:rctrl_rshift_toggle,ctrl  ctrl:nocaps,grp grp:rctrl_rshift_toggle]
/desktop/gnome/peripherals/keyboard/kbd/layouts [us  altgr-intl,us alt-intl,us,es]
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
	(set -x;gsettings set $schema $key "$value")
done <<EOF
org.gnome.settings-daemon.plugins.media-keys screensaver 'Pause'
org.gnome.libgnomekbd.keyboard options @as ['ctrl:nocaps', 'ctrltctrl:nocaps', 'ctrl	ctrl:nocaps', 'grp	grp:rctrl_rshift_toggle']
org.gnome.libgnomekbd.keyboard layouts @as ['us	altgr-intl', 'us	intl', 'us', 'es']
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
)
}

setup_gconftool2
test -x /usr/bin/gsettings && setup_gsettings
setup_now
