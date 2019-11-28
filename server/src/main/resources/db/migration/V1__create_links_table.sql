CREATE TABLE public.link (
  id SERIAL PRIMARY KEY,
  date TIMESTAMP NOT NULL,
  target VARCHAR NOT NULL
);

CREATE INDEX link_date_index ON public.link (date);
