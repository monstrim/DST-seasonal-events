--[[		Created by: Monstah		]]

name = "Yearly Seasonal Events"
description = [[
Version 1.2.5

󰀧 Special Events (Hallowed Eve, Summer Cawnival and Winter's Feast) happen every in-game year.

󰀭 There's always one Year Of event active, which cycles on the second new moon after beginning of winter.

----------------------------------------
󰀏 Added confetti fx fanfarre to Carnival start.
󰀓 Localized strings for event announcements!
󰀛 Fixed crash on Year of the Dragonfly end.
󰀐 Gingerbread pig hunting! Hotfixed for crash if event ended without hunt spawned.
󰀨 Fixed snowballs keep appearing after Winter's Feast
󰀕 Fixed bug loading saved games without properly setting Year of events
󰀏 Halloween trinkets worth candy on Halloween.
󰀛 Many small fixes. Many future improvements mapped.
]]

author = "Monstah"
version = "1.2.5"


api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true

all_clients_require_mod = true
client_only = false

server_filter_tags = {'event', 'season', 'calendar', 'yearly'}

icon_atlas = "calendar.xml"
icon = "calendar.tex"