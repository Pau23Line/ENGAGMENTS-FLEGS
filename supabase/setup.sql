-- =====================================================================
--  Engagements Promo F&L — base de données (Supabase)
--  À coller UNE FOIS dans Supabase > SQL Editor > New query > Run.
--
--  AVANT DE LANCER : remplacez CHANGEZ-MOI (tout en bas, étape 5)
--  par votre code magasin, celui que vous donnerez aux collègues.
-- =====================================================================

-- 1. Chiffrement du code magasin
create extension if not exists pgcrypto with schema extensions;

-- 2. Tables
--    docs : toutes les données de l'app (engagements, récaps, météo),
--           une ligne par élément, rangée par "collection".
create table if not exists public.docs (
  collection text        not null,
  id         text        not null,
  data       jsonb       not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (collection, id)
);

--    app_secret : le code magasin, stocké chiffré (jamais en clair).
create table if not exists public.app_secret (
  id        int  primary key default 1 check (id = 1),
  code_hash text not null
);

-- 3. Personne ne lit ni n'écrit les tables directement :
--    tout passe par les fonctions ci-dessous, qui vérifient le code.
alter table public.docs       enable row level security;
alter table public.app_secret enable row level security;
revoke all on public.docs, public.app_secret from public;
do $$ begin
  execute 'revoke all on public.docs, public.app_secret from anon, authenticated';
exception when undefined_object then null; end $$;

-- 4. Fonctions appelées par l'app
create or replace function public._check_code(p_code text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare h text;
begin
  select code_hash into h from public.app_secret where id = 1;
  if h is null or p_code is null or length(p_code) = 0 or crypt(p_code, h) <> h then
    perform pg_sleep(0.5);  -- ralentit les essais au hasard
    raise exception 'code_invalide' using errcode = '28000';
  end if;
end $$;

create or replace function public.app_load(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform public._check_code(p_code);
  return coalesce(
    (select jsonb_agg(jsonb_build_object(
              'collection', collection, 'id', id, 'data', data, 'updated_at', updated_at)
            order by collection, id)
       from public.docs),
    '[]'::jsonb);
end $$;

create or replace function public.app_save(p_code text, p_collection text, p_id text, p_data jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare r public.docs;
begin
  perform public._check_code(p_code);
  if p_collection not in ('engagements', 'recaps', 'meteo') then
    raise exception 'collection_inconnue' using errcode = '22023';
  end if;
  if p_id !~ '^[A-Za-z0-9_.:@+~-]{1,100}$' then
    raise exception 'identifiant_invalide' using errcode = '22023';
  end if;
  if p_data is null or jsonb_typeof(p_data) <> 'object' or pg_column_size(p_data) > 200000 then
    raise exception 'donnees_invalides' using errcode = '22023';
  end if;
  insert into public.docs as d (collection, id, data, updated_at)
       values (p_collection, p_id, p_data, now())
  on conflict (collection, id) do update
       set data = excluded.data, updated_at = now()
  returning * into r;
  return jsonb_build_object('collection', r.collection, 'id', r.id, 'data', r.data, 'updated_at', r.updated_at);
end $$;

create or replace function public.app_delete(p_code text, p_collection text, p_id text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  perform public._check_code(p_code);
  delete from public.docs where collection = p_collection and id = p_id;
end $$;

revoke all on function public._check_code(text) from public;
revoke all on function public.app_load(text) from public;
revoke all on function public.app_save(text, text, text, jsonb) from public;
revoke all on function public.app_delete(text, text, text) from public;
do $$ begin
  execute 'revoke all on function public._check_code(text) from anon, authenticated';
  execute 'grant execute on function public.app_load(text) to anon, authenticated';
  execute 'grant execute on function public.app_save(text, text, text, jsonb) to anon, authenticated';
  execute 'grant execute on function public.app_delete(text, text, text) to anon, authenticated';
exception when undefined_object then null; end $$;

-- 5. LE CODE MAGASIN : remplacez CHANGEZ-MOI par votre code (gardez les apostrophes).
--    Pour le changer plus tard, relancez seulement cette ligne avec le nouveau code.
insert into public.app_secret (id, code_hash)
     values (1, extensions.crypt('CHANGEZ-MOI', extensions.gen_salt('bf')))
on conflict (id) do update set code_hash = excluded.code_hash;

-- 6. Reprise des données de l'ancienne app (météo de la semaine 44, relevés)
insert into public.docs (collection, id, data) values
('meteo', '2026-W44', '{"semaine":"2026-W44","ville":"Maisons-Alfort","type":"releve","source":"Relevés Paris-Montsouris (previmet.com)","majLe":"2026-11-01T14:44:00.000Z","jours":[{"date":"2026-10-27","j":"Mar","ciel":"Couvert","tmin":13,"tmax":16,"pluie":0.8},{"date":"2026-10-28","j":"Mer","ciel":"Soleil","tmin":8,"tmax":16,"pluie":0.2},{"date":"2026-10-29","j":"Jeu","ciel":"Soleil","tmin":7,"tmax":16,"pluie":0},{"date":"2026-10-30","j":"Ven","ciel":"Soleil","tmin":7,"tmax":16,"pluie":0.2},{"date":"2026-10-31","j":"Sam","ciel":"Soleil","tmin":7,"tmax":15,"pluie":0.2}]}'::jsonb)
on conflict (collection, id) do nothing;
