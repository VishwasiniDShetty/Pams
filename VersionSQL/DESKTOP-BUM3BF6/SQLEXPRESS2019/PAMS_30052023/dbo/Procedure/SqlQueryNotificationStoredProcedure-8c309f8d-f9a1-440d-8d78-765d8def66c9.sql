﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-8c309f8d-f9a1-440d-8d78-765d8def66c9]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-8c309f8d-f9a1-440d-8d78-765d8def66c9] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-8c309f8d-f9a1-440d-8d78-765d8def66c9]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-8c309f8d-f9a1-440d-8d78-765d8def66c9] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-8c309f8d-f9a1-440d-8d78-765d8def66c9') > 0)   DROP SERVICE [SqlQueryNotificationService-8c309f8d-f9a1-440d-8d78-765d8def66c9]; if (OBJECT_ID('SqlQueryNotificationService-8c309f8d-f9a1-440d-8d78-765d8def66c9', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-8c309f8d-f9a1-440d-8d78-765d8def66c9]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-8c309f8d-f9a1-440d-8d78-765d8def66c9]; END COMMIT TRANSACTION; END
