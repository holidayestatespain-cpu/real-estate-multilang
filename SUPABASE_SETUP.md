# Conectar Supabase y ver el proyecto

## 1. Crear el proyecto
1. Entra en https://supabase.com/dashboard y crea un proyecto gratuito.
2. En **Project Settings > API**, copia `Project URL` y `anon public key`.
3. En **SQL Editor**, pega y ejecuta todo `supabase/schema.sql`.

## 2. Crear el administrador
1. Ve a **Authentication > Users > Add user**.
2. Crea el correo y una contraseña fuerte para el administrador.
3. Copia el UUID del usuario creado.
4. En SQL Editor ejecuta:

```sql
insert into public.admin_users (user_id)
values ('PEGA-AQUI-EL-UUID-DEL-USUARIO');
```

El panel solo autoriza a usuarios cuyo UUID esté en `admin_users`.

## 3. Ejecutar localmente

```bash
npm install
cp .env.example .env.local
```

Edita `.env.local` con:

```env
NEXT_PUBLIC_SUPABASE_URL=https://tu-proyecto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=tu-anon-public-key
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

No pongas `SUPABASE_SERVICE_ROLE_KEY` en código del navegador ni la subas a GitHub. Para el frontend público no hace falta.

```bash
npm run dev
```

Abre:
- http://localhost:3000/es
- http://localhost:3000/en
- http://localhost:3000/admin/login

## 4. Publicar gratis en Vercel

1. Entra en https://vercel.com/new.
2. Importa `holidayestatespain-cpu/real-estate-multilang`.
3. Añade en **Environment Variables**:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `NEXT_PUBLIC_SITE_URL` con la URL de Vercel
4. Pulsa **Deploy**.

Después de desplegar, añade el dominio de Vercel en Supabase en **Authentication > URL Configuration** como `Site URL` y añade también la URL de callback si se solicita.

## Estado actual

El repositorio contiene la estructura pública y el esquema seguro de Supabase. La pantalla de login y los formularios todavía necesitan conectarse a `supabase.auth` y a las tablas para que el CRUD sea completamente operativo; no uses el panel de demostración como sistema de producción hasta completar esa conexión.
