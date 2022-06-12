SELECT senderid
FROM sender
WHERE sender = coalesce($1, '') AND realname = coalesce($2, '') AND avatarurl = coalesce($3, '')
