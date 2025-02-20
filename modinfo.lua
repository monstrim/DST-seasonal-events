--[[		Created by: Monstah		]]

name = "Yearly Seasonal Events"
description = [[
Special Events (Hallowed Eve, Summer Cawnival and Winter's Feast) happen every in-game year.
There's always one Year Of event active, which cycles on the second new moon after beginning of winter.

NOTE: Doesn't work with caves (and, I presume, multiplayer): the events are correctly started, but the players' tech level doesn't change, so you can't build the special structures. Latest update at least won't crash with caves :) Still working on it.
]]

author = "Monstah"
version = "1.0.1"


api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
dst_compatible = true

all_clients_require_mod = true --we now push HUD events, and the HUD (it seems) needs to be created client-side
-- TODO: events aren't really pushing? Also, tech levels must be pushed.
client_only = false

server_filter_tags = {'event', 'season', 'calendar', 'yearly'}

icon_atlas = "calendar.xml"
icon = "calendar.tex"