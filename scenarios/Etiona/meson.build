files = [
    'map.json',
    'metadata.json',
    'players.json',
    'cities.json',
    'background.png',
    'map.png',
    'medieval.png',
    'medieval(1).png',
    'monument.png',
    'moscow.png',
    'stadt1.png',
    'stadt2.png',
    'stadt3.png',
    'stadt4.png',
    'stadt5.png',
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