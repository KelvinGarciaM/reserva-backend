USE reservasdbV2;
GO

CREATE OR ALTER TRIGGER dbo.trg_users_updated_at
ON dbo.users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE u
    SET updated_at = GETDATE()
    FROM dbo.users AS u
    INNER JOIN inserted AS i
        ON u.id = i.id;
END;
GO