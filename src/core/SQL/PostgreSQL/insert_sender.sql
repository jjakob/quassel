INSERT INTO sender (sender, realname, avatarurl)
VALUES (COALESCE($1, ''), COALESCE($2, ''), COALESCE($3,''))
RETURNING senderid
