﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-0b42fb02-ffbd-4cce-9672-1a32fdf4dc11]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-0b42fb02-ffbd-4cce-9672-1a32fdf4dc11] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-0b42fb02-ffbd-4cce-9672-1a32fdf4dc11]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-0b42fb02-ffbd-4cce-9672-1a32fdf4dc11] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-0b42fb02-ffbd-4cce-9672-1a32fdf4dc11') > 0)   DROP SERVICE [SqlQueryNotificationService-0b42fb02-ffbd-4cce-9672-1a32fdf4dc11]; if (OBJECT_ID('SqlQueryNotificationService-0b42fb02-ffbd-4cce-9672-1a32fdf4dc11', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-0b42fb02-ffbd-4cce-9672-1a32fdf4dc11]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-0b42fb02-ffbd-4cce-9672-1a32fdf4dc11]; END COMMIT TRANSACTION; END