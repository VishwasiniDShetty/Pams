﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-d3ff90c4-8606-423c-a03e-9ae20a8fe227]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-d3ff90c4-8606-423c-a03e-9ae20a8fe227] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-d3ff90c4-8606-423c-a03e-9ae20a8fe227]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-d3ff90c4-8606-423c-a03e-9ae20a8fe227] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-d3ff90c4-8606-423c-a03e-9ae20a8fe227') > 0)   DROP SERVICE [SqlQueryNotificationService-d3ff90c4-8606-423c-a03e-9ae20a8fe227]; if (OBJECT_ID('SqlQueryNotificationService-d3ff90c4-8606-423c-a03e-9ae20a8fe227', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-d3ff90c4-8606-423c-a03e-9ae20a8fe227]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-d3ff90c4-8606-423c-a03e-9ae20a8fe227]; END COMMIT TRANSACTION; END
