#!/bin/bash -x
adb shell setprop EXTERNAL_STORAGE_STATE mounted
adb shell am broadcast -a android.intent.action.MEDIA_MOUNTED --ez read-only false -d  file:///sdcard

