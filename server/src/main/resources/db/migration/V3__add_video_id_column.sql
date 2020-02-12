ALTER TABLE video
    ADD COLUMN video_url_id VARCHAR UNIQUE;
--
UPDATE video
SET video_url_id=replace(videourl, 'https://www.youtube.com/watch?v=', '')
WHERE true;
--
ALTER TABLE video
    ALTER COLUMN video_url_id SET NOT NULL;
--
CREATE UNIQUE INDEX video_url_id_idx ON video (video_url_id);


