﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-150bddd3-e5ea-411b-ae95-ed06dafc5eee]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-150bddd3-e5ea-411b-ae95-ed06dafc5eee] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-150bddd3-e5ea-411b-ae95-ed06dafc5eee]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-150bddd3-e5ea-411b-ae95-ed06dafc5eee] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-150bddd3-e5ea-411b-ae95-ed06dafc5eee') > 0)   DROP SERVICE [SqlQueryNotificationService-150bddd3-e5ea-411b-ae95-ed06dafc5eee]; if (OBJECT_ID('SqlQueryNotificationService-150bddd3-e5ea-411b-ae95-ed06dafc5eee', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-150bddd3-e5ea-411b-ae95-ed06dafc5eee]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-150bddd3-e5ea-411b-ae95-ed06dafc5eee]; END COMMIT TRANSACTION; END