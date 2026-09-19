-- EstateFlow production schema for Supabase
create extension if not exists pgcrypto;

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  reference text unique not null,
  title text not null,
  slug text unique not null,
  description text,
  title_i18n jsonb not null default '{}'::jsonb,
  description_i18n jsonb not null default '{}'::jsonb,
  price numeric(12,2) not null default 0,
  location text not null,
  property_type text,
  status text not null default 'draft' check (status in ('draft','published')),
  bedrooms int,
  bathrooms int,
  built_area numeric,
  useful_area numeric,
  year_built int,
  floor text,
  garage boolean not null default false,
  pool boolean not null default false,
  terrace boolean not null default false,
  garden boolean not null default false,
  lift boolean not null default false,
  sea_view boolean not null default false,
  new_build boolean not null default false,
  bank_owned boolean not null default false,
  featured boolean not null default false,
  main_image text,
  features jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.property_images (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  url text not null,
  storage_path text,
  position int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  email text not null,
  phone text,
  message text not null,
  property_id uuid references public.properties(id) on delete set null,
  property_reference text,
  created_at timestamptz not null default now(),
  status text not null default 'New' check (status in ('New','Contacted','Qualified','Closed'))
);

-- Admin allow-list. Add an authenticated user's UUID here after creating them in
-- Supabase Authentication > Users. Do not use email alone for authorization.
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admin_users where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

alter table public.properties enable row level security;
alter table public.property_images enable row level security;
alter table public.leads enable row level security;
alter table public.admin_users enable row level security;

drop policy if exists "Public read published properties" on public.properties;
create policy "Public read published properties" on public.properties
  for select to anon, authenticated using (status = 'published');

 drop policy if exists "Admins manage properties" on public.properties;
create policy "Admins manage properties" on public.properties
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Public read property images" on public.property_images;
create policy "Public read property images" on public.property_images
  for select to anon, authenticated using (
    exists (select 1 from public.properties p where p.id = property_id and p.status = 'published')
  );

drop policy if exists "Admins manage property images" on public.property_images;
create policy "Admins manage property images" on public.property_images
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Public create leads" on public.leads;
create policy "Public create leads" on public.leads
  for insert to anon, authenticated with check (true);

drop policy if exists "Admins read leads" on public.leads;
create policy "Admins read leads" on public.leads
  for select to authenticated using (public.is_admin());

drop policy if exists "Admins update leads" on public.leads;
create policy "Admins update leads" on public.leads
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Admins delete leads" on public.leads;
create policy "Admins delete leads" on public.leads
  for delete to authenticated using (public.is_admin());

insert into storage.buckets (id, name, public)
values ('property-images', 'property-images', true)
on conflict (id) do update set public = true;

drop policy if exists "Public view property images" on storage.objects;
create policy "Public view property images" on storage.objects
  for select to anon, authenticated using (bucket_id = 'property-images');

drop policy if exists "Admins upload property images" on storage.objects;
create policy "Admins upload property images" on storage.objects
  for insert to authenticated with check (bucket_id = 'property-images' and public.is_admin());

drop policy if exists "Admins update property images" on storage.objects;
create policy "Admins update property images" on storage.objects
  for update to authenticated using (bucket_id = 'property-images' and public.is_admin()) with check (bucket_id = 'property-images' and public.is_admin());

drop policy if exists "Admins delete property images" on storage.objects;
create policy "Admins delete property images" on storage.objects
  for delete to authenticated using (bucket_id = 'property-images' and public.is_admin());

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trigger_set_updated_at on public.properties;
create trigger trigger_set_updated_at before update on public.properties
for each row execute function public.set_updated_at();

insert into public.properties (
  reference,title,slug,description,price,location,property_type,status,bedrooms,bathrooms,
  built_area,useful_area,year_built,floor,garage,pool,terrace,lift,featured,main_image,features
) values (
  'HE-0001', 'Apartment in Torrevieja', 'apartment-torrevieja-he-0001',
  'Sample property for demonstration.', 149000, 'Torrevieja', 'Apartamento', 'published',
  2, 1, 66, 56, 2004, '1st', true, true, true, true, true,
  'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?auto=format&fit=crop&w=1400&q=80',
  '["Communal swimming pool","2 patios","Lift","Optional garage"]'::jsonb
) on conflict (reference) do nothing;
