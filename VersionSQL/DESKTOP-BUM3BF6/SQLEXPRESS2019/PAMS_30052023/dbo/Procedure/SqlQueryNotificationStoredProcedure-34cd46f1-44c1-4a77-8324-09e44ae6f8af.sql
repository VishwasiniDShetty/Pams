﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-34cd46f1-44c1-4a77-8324-09e44ae6f8af]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-34cd46f1-44c1-4a77-8324-09e44ae6f8af] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-34cd46f1-44c1-4a77-8324-09e44ae6f8af]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-34cd46f1-44c1-4a77-8324-09e44ae6f8af] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-34cd46f1-44c1-4a77-8324-09e44ae6f8af') > 0)   DROP SERVICE [SqlQueryNotificationService-34cd46f1-44c1-4a77-8324-09e44ae6f8af]; if (OBJECT_ID('SqlQueryNotificationService-34cd46f1-44c1-4a77-8324-09e44ae6f8af', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-34cd46f1-44c1-4a77-8324-09e44ae6f8af]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-34cd46f1-44c1-4a77-8324-09e44ae6f8af]; END COMMIT TRANSACTION; END
