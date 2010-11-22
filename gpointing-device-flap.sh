set -x
xinput set-int-prop "TPPS/2 IBM TrackPoint" "Evdev Wheel Emulation" 8 1
xinput set-int-prop "TPPS/2 IBM TrackPoint" "Evdev Wheel Emulation Button" 8 2
xinput set-int-prop "TPPS/2 IBM TrackPoint" "Evdev Wheel Emulation Axes" 8 6 7 4 5
setxkbmap -option ctrl:nocaps us intl
#permanent in gnome:
gconftool --list-type string -t list -s /desktop/gnome/peripherals/keyboard/kbd/options '[lv3	lv3:ralt_switch,ctrl	ctrl:nocaps]'

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
