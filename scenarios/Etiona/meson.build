files = [
    'map.json',
    'metadata.json',
    'players.json',
    'cities.json',
    'background.png',
    'map.png',
    'Alpha.png',
    'Andron.png',
    'Deomega.png',
    'Holamorta.png',
    'Initia de aqa.png',
    'Lua.png',
    'Onmaalpha.png',
    'San morir.png',
    'Sol.png',
]
custom_target(
    'Etiona',
    input: files,
    output: 'etiona.scenario',
    command: [zip, '@OUTPUT0@', '@INPUT@'],
    install: true,
    install_dir: scenario_install_dir,
)

foreach json_file : json_files
    test('test_etiona_' + json_file, json_glib_format, args: files(json_file))
endforeach
