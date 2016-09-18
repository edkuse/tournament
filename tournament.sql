-- Table definitions for the tournament project.
--
-- Put your SQL 'create table' statements in this file; also 'create view'
-- statements if you choose to use it.
--
-- You can write comments in this file by starting them with two dashes, like
-- these lines here.


--
-- Main table of players
--
CREATE TABLE player (
	id serial,
	name varchar(100) not null,
	primary key (id)
);


--
-- Table of matches played and players win/loss record
--
CREATE TABLE match (
	id serial,
	winner int not null references player(id),
	loser int references player(id),
	primary key (id)
);


--
-- View to retrieve player count of matches and wins
--
CREATE OR REPLACE VIEW records AS
SELECT a.id player_id,
	a.name player_nm,
	COUNT(b.winner) wins,
	COUNT(b.id) + COUNT(c.id) matches
FROM player a
LEFT JOIN match b ON a.id = b.winner
LEFT JOIN match c ON a.id = c.loser
GROUP BY a.id, a.name;


--
-- View to form swiss pairings of players for matches.
-- Use the records view and using PostgreSQL window functions, 
-- match up odd numbered players with even numbered based on sorted
-- order of wins
--
CREATE OR REPLACE VIEW pairings AS
SELECT player1_id,
	player1_nm,
	player2_id,
	player2_nm
FROM (
	SELECT player_id player1_id,
		player_nm player1_nm,
		LEAD(player_id, 1) OVER(ORDER BY rn) player2_id,
		LEAD(player_nm, 1) OVER(ORDER BY rn) player2_nm,
		rn
	FROM (
		SELECT player_id,
			player_nm,
			wins,
			matches,
			ROW_NUMBER() OVER (ORDER BY wins DESC) rn
		FROM records
	) a
) b
WHERE (rn % 2) <> 0; -- Only need to get half (odd) rows to pair with even
