﻿/****** Object:  Procedure [dbo].[SqlQueryNotificationStoredProcedure-a551c531-2b98-43e3-9461-dec85333a0fc]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SqlQueryNotificationStoredProcedure-a551c531-2b98-43e3-9461-dec85333a0fc] AS BEGIN BEGIN TRANSACTION; RECEIVE TOP(0) conversation_handle FROM [SqlQueryNotificationService-a551c531-2b98-43e3-9461-dec85333a0fc]; IF (SELECT COUNT(*) FROM [SqlQueryNotificationService-a551c531-2b98-43e3-9461-dec85333a0fc] WHERE message_type_name = 'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer') > 0 BEGIN if ((SELECT COUNT(*) FROM sys.services WHERE name = 'SqlQueryNotificationService-a551c531-2b98-43e3-9461-dec85333a0fc') > 0)   DROP SERVICE [SqlQueryNotificationService-a551c531-2b98-43e3-9461-dec85333a0fc]; if (OBJECT_ID('SqlQueryNotificationService-a551c531-2b98-43e3-9461-dec85333a0fc', 'SQ') IS NOT NULL)   DROP QUEUE [SqlQueryNotificationService-a551c531-2b98-43e3-9461-dec85333a0fc]; DROP PROCEDURE [SqlQueryNotificationStoredProcedure-a551c531-2b98-43e3-9461-dec85333a0fc]; END COMMIT TRANSACTION; END