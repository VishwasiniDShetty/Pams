﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-bb4ec6d0-34c4-4fdb-8097-df8f6dbd50bc]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-bb4ec6d0-34c4-4fdb-8097-df8f6dbd50bc] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-bb4ec6d0-34c4-4fdb-8097-df8f6dbd50bc]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-bb4ec6d0-34c4-4fdb-8097-df8f6dbd50bc] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-bb4ec6d0-34c4-4fdb-8097-df8f6dbd50bc') > 0)   DROP SERVICE [SqlQueryNotificationService-bb4ec6d0-34c4-4fdb-8097-df8f6dbd50bc]; if (OBJECT_ID('SqlQueryNotificationService-bb4ec6d0-34c4-4fdb-8097-df8f6dbd50bc', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-bb4ec6d0-34c4-4fdb-8097-df8f6dbd50bc]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-bb4ec6d0-34c4-4fdb-8097-df8f6dbd50bc]; END COMMIT TRANSACTION; END