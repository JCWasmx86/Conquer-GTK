CREATE TABLE IF NOT EXISTS maps (
	guid TEXT PRIMARY KEY,
	sha256_background TEXT
) STRICT;

CREATE TABLE IF NOT EXISTS clan (
	guid TEXT PRIMARY KEY,
	color TEXT,
	map_uuid TEXT
) STRICT;

CREATE TABLE IF NOT EXISTS city (
	guid TEXT PRIMARY KEY,
	sha256_image TEXT,
	x INT,
	y INT,
	map_uuid TEXT,
	initial_clan TEXT
) STRICT;

CREATE TABLE IF NOT EXISTS game (
	guid TEXT PRIMARY KEY,
	name TEXT,
	map_uuid TEXT
) STRICT;

CREATE TABLE IF NOT EXISTS movement (
	ID INTEGER PRIMARY KEY AUTOINCREMENT,
	round_no INT,
	game_uuid TEXT,
	from_uuid TEXT,
	to_uuid TEXT,
	attack INT,
	success INT
) STRICT;