﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-5f4b89ce-a7d3-4f1c-8785-bb924c1c45cf]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-5f4b89ce-a7d3-4f1c-8785-bb924c1c45cf] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-5f4b89ce-a7d3-4f1c-8785-bb924c1c45cf]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-5f4b89ce-a7d3-4f1c-8785-bb924c1c45cf] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-5f4b89ce-a7d3-4f1c-8785-bb924c1c45cf') > 0)   DROP SERVICE [SqlQueryNotificationService-5f4b89ce-a7d3-4f1c-8785-bb924c1c45cf]; if (OBJECT_ID('SqlQueryNotificationService-5f4b89ce-a7d3-4f1c-8785-bb924c1c45cf', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-5f4b89ce-a7d3-4f1c-8785-bb924c1c45cf]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-5f4b89ce-a7d3-4f1c-8785-bb924c1c45cf]; END COMMIT TRANSACTION; END