﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-2c5de3e9-ebdf-4a11-968f-05c4fe3f141a]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-2c5de3e9-ebdf-4a11-968f-05c4fe3f141a] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-2c5de3e9-ebdf-4a11-968f-05c4fe3f141a]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-2c5de3e9-ebdf-4a11-968f-05c4fe3f141a] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-2c5de3e9-ebdf-4a11-968f-05c4fe3f141a') > 0)   DROP SERVICE [SqlQueryNotificationService-2c5de3e9-ebdf-4a11-968f-05c4fe3f141a]; if (OBJECT_ID('SqlQueryNotificationService-2c5de3e9-ebdf-4a11-968f-05c4fe3f141a', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-2c5de3e9-ebdf-4a11-968f-05c4fe3f141a]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-2c5de3e9-ebdf-4a11-968f-05c4fe3f141a]; END COMMIT TRANSACTION; END