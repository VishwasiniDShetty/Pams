﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-de4c17ab-f573-4617-8611-3376caf7359e]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-de4c17ab-f573-4617-8611-3376caf7359e] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-de4c17ab-f573-4617-8611-3376caf7359e]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-de4c17ab-f573-4617-8611-3376caf7359e] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-de4c17ab-f573-4617-8611-3376caf7359e') > 0)   DROP SERVICE [SqlQueryNotificationService-de4c17ab-f573-4617-8611-3376caf7359e]; if (OBJECT_ID('SqlQueryNotificationService-de4c17ab-f573-4617-8611-3376caf7359e', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-de4c17ab-f573-4617-8611-3376caf7359e]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-de4c17ab-f573-4617-8611-3376caf7359e]; END COMMIT TRANSACTION; END
