﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-8fe278eb-9622-4816-afd3-71174cfd7b24]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-8fe278eb-9622-4816-afd3-71174cfd7b24] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-8fe278eb-9622-4816-afd3-71174cfd7b24]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-8fe278eb-9622-4816-afd3-71174cfd7b24] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-8fe278eb-9622-4816-afd3-71174cfd7b24') > 0)   DROP SERVICE [SqlQueryNotificationService-8fe278eb-9622-4816-afd3-71174cfd7b24]; if (OBJECT_ID('SqlQueryNotificationService-8fe278eb-9622-4816-afd3-71174cfd7b24', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-8fe278eb-9622-4816-afd3-71174cfd7b24]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-8fe278eb-9622-4816-afd3-71174cfd7b24]; END COMMIT TRANSACTION; END
