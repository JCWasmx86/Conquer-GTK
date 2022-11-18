files = [
    'map.json',
    'metadata.json',
    'players.json',
    'cities.json',
    'background.png',
    'map.png',
    'Astandor.png',
    'Deinitia.png',
    'Insamoria.png',
    'Invaria.png',
    'La uria.png',
    'Onmadispera.png',
    'Onmamorta.png',
    'Samolacrima.png',
    'Sanmaga.png',
    'Valosepulca.png',
]
custom_target(
    'Belenos',
    input: files,
    output: 'belenos.scenario',
    command: [zip, '@OUTPUT0@', '@INPUT@'],
    install: true,
    install_dir: scenario_install_dir,
)

foreach json_file : json_files
    test('test_belenos_' + json_file, json_glib_format, args: files(json_file))
endforeach
