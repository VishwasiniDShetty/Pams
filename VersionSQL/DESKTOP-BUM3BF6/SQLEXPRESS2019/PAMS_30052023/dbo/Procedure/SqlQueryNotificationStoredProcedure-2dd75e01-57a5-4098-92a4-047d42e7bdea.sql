﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-2dd75e01-57a5-4098-92a4-047d42e7bdea]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-2dd75e01-57a5-4098-92a4-047d42e7bdea] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-2dd75e01-57a5-4098-92a4-047d42e7bdea]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-2dd75e01-57a5-4098-92a4-047d42e7bdea] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-2dd75e01-57a5-4098-92a4-047d42e7bdea') > 0)   DROP SERVICE [SqlQueryNotificationService-2dd75e01-57a5-4098-92a4-047d42e7bdea]; if (OBJECT_ID('SqlQueryNotificationService-2dd75e01-57a5-4098-92a4-047d42e7bdea', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-2dd75e01-57a5-4098-92a4-047d42e7bdea]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-2dd75e01-57a5-4098-92a4-047d42e7bdea]; END COMMIT TRANSACTION; END