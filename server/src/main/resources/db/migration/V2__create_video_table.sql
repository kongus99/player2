CREATE TABLE public.video
(
    id       SERIAL PRIMARY KEY,
    title    VARCHAR NOT NULL,
    videoUrl VARCHAR NOT NULL
);

DROP TABLE public.link;
