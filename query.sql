SELECT
  host || ':' || disk || '/' || filename AS filepath
FROM
  stack_files
WHERE
  det_id = 112;
