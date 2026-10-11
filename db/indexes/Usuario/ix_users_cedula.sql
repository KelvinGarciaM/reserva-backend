USE reservasdbV2;
GO

/* users: soporta la FK hacia recepcionista */
CREATE NONCLUSTERED INDEX ix_users_cedula
    ON dbo.users (cedula);
GO
