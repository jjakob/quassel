/* do all the steps in one transaction, as a partially finished
 * procedure may leave the db in a hard to recover state */
DROP INDEX IF EXISTS sender_index;

/* part 1: update columns */
UPDATE sender
SET realname=''
WHERE realname IS NULL
;

UPDATE sender
SET avatarurl=''
WHERE avatarurl IS NULL
;

/* we can't just change the column constraint like in PostgreSQL
 * so we need to create a new table */
CREATE TABLE sender_new (
       senderid INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
       sender TEXT NOT NULL,
       realname TEXT NOT NULL,
       avatarurl TEXT NOT NULL
);

INSERT INTO sender_new SELECT * FROM sender;

DROP TABLE sender;

ALTER TABLE sender_new RENAME TO sender;

/* part 2: get table of conflict rows */
CREATE TEMP TABLE bad_senderids AS
SELECT good_senderid, bad_senderid
FROM (
	SELECT min(senderid) OVER (
			PARTITION BY
				sender,
				realname,
				avatarurl
		) AS good_senderid,
		senderid AS bad_senderid
	FROM sender
) AS x
WHERE bad_senderid > good_senderid
;

/* part 3: do the changes */
/* we can't disable triggers like on PostgreSQL */
DROP TRIGGER backlog_lastmsgid_update_trigger_update;

UPDATE backlog
SET senderid=bsi.good_senderid
FROM bad_senderids bsi
WHERE backlog.senderid=bsi.bad_senderid
;

DELETE FROM sender
USING bad_senderids bsi
WHERE senderid = bsi.bad_senderid
;

CREATE TRIGGER IF NOT EXISTS backlog_lastmsgid_update_trigger_update
AFTER UPDATE
ON backlog
FOR EACH ROW
    BEGIN
        UPDATE buffer
        SET lastmsgid = new.messageid
        WHERE buffer.bufferid = new.bufferid
            AND buffer.lastmsgid < new.messageid;
    END

CREATE UNIQUE INDEX sender_index
ON sender (sender, realname, avatarurl);
/* SQLite setup does not have any foreign keys like PostgreSQL does ? */
