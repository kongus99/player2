CREATE TABLE public.user
(
    id         SERIAL PRIMARY KEY,
    name       VARCHAR UNIQUE NOT NULL,
    email      VARCHAR UNIQUE NOT NULL,
    hash       VARCHAR UNIQUE NOT NULL,
    last_login TIMESTAMP      NOT NULL
);
