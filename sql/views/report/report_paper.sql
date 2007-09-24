
CREATE OR REPLACE VIEW view_report_paper AS
  SELECT event_id,
         conference_id,
         title,
         subtitle,
         f_paper,
         (SELECT count(event_attachment_id)
            FROM event_attachment
                 INNER JOIN attachment_type USING (attachment_type_id)
           WHERE event_id = event.event_id AND
                 attachment_type.tag = 'paper')
         AS paper_submitted,
         (SELECT sum(pages)
           FROM event_attachment
                INNER JOIN attachment_type USING (attachment_type_id)
          WHERE event_id = event.event_id AND
                attachment_type.tag = 'paper')
         AS pages
    FROM event
   WHERE event.event_state = 'accepted' AND
         event.event_state_progress = 'confirmed' AND
         event.f_paper = 't'
   ORDER BY lower(title), lower(subtitle)
;

