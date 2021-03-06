
CREATE OR REPLACE VIEW view_person_rating AS
  SELECT
    person_rating.person_id,
    person_rating.evaluator_id,
    person_rating.speaker_quality,
    person_rating.competence,
    person_rating.remark,
    person_rating.eval_time,
    view_person.name
  FROM
    person_rating
    INNER JOIN view_person ON (person_rating.evaluator_id = view_person.person_id)
  WHERE
    person_rating.speaker_quality IS NOT NULL OR
    person_rating.competence IS NOT NULL OR
    person_rating.remark IS NOT NULL
  ORDER BY person_rating.eval_time DESC
;

