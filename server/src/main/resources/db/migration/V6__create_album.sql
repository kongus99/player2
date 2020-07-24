CREATE TABLE public.album
(
    id      SERIAL PRIMARY KEY,
    userId  INTEGER        NOT NULL,
    videoId INTEGER UNIQUE NOT NULL,
    tracks  TEXT,
    FOREIGN KEY (userId) REFERENCES public.user (id),
    FOREIGN KEY (videoId) REFERENCES public.video (id)
);
