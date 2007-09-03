
-- returns event_persons that do not speak the language of the event
CREATE OR REPLACE FUNCTION conflict_event_person_language(integer) RETURNS SETOF conflict_event_person AS '
  DECLARE
    cur_conference_id ALIAS FOR $1;
    cur_event RECORD;
    cur_speaker RECORD;
    cur_conflict conflict_event_person%rowtype;
  BEGIN

-- Loop through all event_persons
    FOR cur_speaker IN
      SELECT event_id, person_id, language_id 
        FROM event_person
        INNER JOIN event_role USING (event_role_id)
        INNER JOIN event_role_state USING (event_role_state_id)
        INNER JOIN event USING (event_id)
        INNER JOIN event_state USING (event_state_id)
        WHERE event_role.tag IN (''speaker'', ''moderator'') AND
              event_role_state.tag = ''confirmed'' AND
              event.conference_id = cur_conference_id AND
              event.language_id IS NOT NULL
    LOOP
      IF NOT EXISTS (SELECT 1 FROM person_language WHERE person_id = cur_speaker.person_id AND language_id = cur_speaker.language_id )
      THEN
        cur_conflict.person_id := cur_speaker.person_id;
        cur_conflict.event_id := cur_speaker.event_id;
        RETURN NEXT cur_conflict;
      END IF;
    END LOOP;
    RETURN;
  END;
' LANGUAGE 'plpgsql' RETURNS NULL ON NULL INPUT;
