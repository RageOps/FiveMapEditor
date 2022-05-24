fx_version 'cerulean'
game 'gta5'

ui_page 'html/index.html'

client_scripts {
    'client/client.lua',
    'client/object_streamer.lua',
}

server_scripts {
    'server/server.lua',
    'server/xml.lua', -- It's here because io is serversided now
    'server/object_loader.lua',
}

files {
    'html/*.*',
}

local function object_entry(data)
	files(data)
	object_file(data)
end

object_entry 'addon-maps/AirportTrack.xml'
object_entry 'addon-maps/DocksTrack.xml'
object_entry 'addon-maps/FormulaOne.xml'
object_entry 'addon-maps/MassiveTrack.xml'
object_entry 'addon-maps/SandyShores.xml'
object_entry 'addon-maps/Zancudo.xml'