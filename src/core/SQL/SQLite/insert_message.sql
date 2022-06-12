INSERT INTO backlog (time, bufferid, type, flags, senderid, senderprefixes, message)
VALUES (:time, :bufferid, :type, :flags,
	(SELECT senderid FROM sender WHERE sender = coalesce(:sender, '') AND realname = coalesce(:realname, '') AND avatarurl = coalesce(:avatarurl, '')),
	:senderprefixes, :message
)
