/* do all the steps in one transaction, as a partially finished
 * procedure may leave the db in a hard to recover state */
DROP INDEX IF EXISTS sender_sender_realname_avatarurl_uindex;

/* part 1: update columns */
UPDATE sender
SET realname=''
WHERE realname IS NULL
;

UPDATE sender
SET avatarurl=''
WHERE avatarurl IS NULL
;

ALTER TABLE sender ALTER realname SET NOT NULL;
ALTER TABLE sender ALTER avatarurl SET NOT NULL;

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
ALTER TABLE backlog DISABLE TRIGGER ALL;
ALTER TABLE sender DISABLE TRIGGER ALL;

UPDATE backlog
SET senderid=bsi.good_senderid
FROM bad_senderids bsi
WHERE backlog.senderid=bsi.bad_senderid
;

DELETE FROM sender
USING bad_senderids bsi
WHERE senderid = bsi.bad_senderid
;

ALTER TABLE backlog ENABLE TRIGGER ALL;
ALTER TABLE sender ENABLE TRIGGER ALL;

REINDEX TABLE sender;
REINDEX TABLE backlog;

CREATE UNIQUE INDEX sender_sender_realname_avatarurl_uindex
ON sender USING btree (sender, realname, avatarurl);
