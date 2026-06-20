-- Migration: trigger que chama a Edge Function send-trip-notification
-- quando o campo `status` da tabela `trips` é atualizado.

CREATE OR REPLACE FUNCTION notify_trip_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Só dispara se o status realmente mudou
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    PERFORM net.http_post(
      url  := current_setting('app.supabase_url') || '/functions/v1/send-trip-notification',
      body := jsonb_build_object(
        'trip_id',    NEW.id,
        'client_id',  NEW.client_id,
        'new_status', NEW.status,
        'old_status', OLD.status
      ),
      headers := jsonb_build_object(
        'Content-Type',  'application/json',
        'Authorization', 'Bearer ' || current_setting('app.service_role_key')
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_trip_status_change ON trips;
CREATE TRIGGER on_trip_status_change
  AFTER UPDATE OF status ON trips
  FOR EACH ROW
  EXECUTE FUNCTION notify_trip_status_change();
