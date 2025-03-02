--[[		Created by: Monstah		]]

name = "Yearly Seasonal Events"
description = [[
Version 1.1.1

󰀭 There's always one Year Of event active, which cycles on the second new moon after beginning of winter.

󰀧 Special Events (Hallowed Eve, Summer Cawnival and Winter's Feast) happen every in-game year.


----------------------------------------
󰀏 Fixed for caves and multiplayer! Also, won't explode again before I patch it the next time a Year Of event is launched.

󰀓 There *might* still be a bug where sometimes the lunacy overlay is triggered at world init. I think I sorted it out, but let me know. If it happens, just disconnect and reconnect; it's just UI.
]]

author = "Monstah"
version = "1.1.1"


api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true

all_clients_require_mod = true
client_only = false

server_filter_tags = {'event', 'season', 'calendar', 'yearly'}

icon_atlas = "calendar.xml"
icon = "calendar.tex"