ALTER TABLE public.album
    DROP CONSTRAINT album_userid_fkey;
ALTER TABLE public.album
    DROP CONSTRAINT album_videoid_fkey;
ALTER TABLE public.album
    ADD CONSTRAINT album_userid_fkey FOREIGN KEY (userId) REFERENCES public.user (id) ON DELETE CASCADE;
ALTER TABLE public.album
    ADD CONSTRAINT album_videoid_fkey FOREIGN KEY (videoid) REFERENCES public.video (id) ON DELETE CASCADE;
