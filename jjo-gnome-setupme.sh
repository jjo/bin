#set -x
#permanent in gnome:
xinput set-int-prop "TPPS/2 IBM TrackPoint" "Evdev Wheel Emulation" 8 1
xinput set-int-prop "TPPS/2 IBM TrackPoint" "Evdev Wheel Emulation Button" 8 2
xinput set-int-prop "TPPS/2 IBM TrackPoint" "Evdev Wheel Emulation Axes" 8 6 7 4 5
gconftool --list-type string -t list -s /desktop/gnome/peripherals/keyboard/kbd/options '[lv3	lv3:ralt_switch,ctrl	ctrl:nocaps]'
while read var value;do
	(set -x;gconftool -t string -s /apps/gnome-terminal/$var $value)
done <<EOF
keybindings/switch_to_tab_1 <Control>1
keybindings/switch_to_tab_2 <Control>2
keybindings/switch_to_tab_3 <Control>3
keybindings/switch_to_tab_4 <Control>4
keybindings/switch_to_tab_5 <Control>5
keybindings/switch_to_tab_6 <Control>6
keybindings/switch_to_tab_7 <Control>7
keybindings/switch_to_tab_8 <Control>8
keybindings/switch_to_tab_9 <Control>9
profiles/Default/background_color #000000000000
profiles/Default/foreground_color #FFFFFFFFFFFF
profiles/Default/use_theme_colors false
profiles/Default/use_menu_accelerators false
profiles/Default/use_mnemonics false
profiles/Default/background_type solid
EOF


#NOW!
setxkbmap -option ctrl:nocaps us intl

exit 0

DUMMY="
     <entry>
       <key>/desktop/gnome/peripherals/TPPS@47@2@32@IBM@32@TrackPoint/wheel_emulation</key>
       <value>
-        <bool>false</bool>
+        <bool>true</bool>
       </value>
     </entry>
     <entry>
       <key>/desktop/gnome/peripherals/TPPS@47@2@32@IBM@32@TrackPoint/wheel_emulation_button</key>
       <value>
         <int>2</int>
       </value>
     </entry>
"
D="/desktop/gnome/peripherals/TPPS@47@2@32@IBM@32@TrackPoint"
#gconftool-2 --type bool --set $D/wheel_emulation false
#gconftool-2 --type int  --set $D/wheel_emulation_button 3
#gconftool-2 --type bool --set $D/wheel_emulation_x_axis false
#gconftool-2 --type bool --set $D/wheel_emulation_x_axis true
#gconftool-2 --type int  --set $D/wheel_emulation_button 2
#gconftool-2 --type bool --set $D/wheel_emulation true
