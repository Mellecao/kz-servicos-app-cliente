-- Migration: adiciona coluna fcm_token na tabela users
-- Armazena o token FCM do dispositivo do cliente para envio de push notifications.
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS fcm_token TEXT;
