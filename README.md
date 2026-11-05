# Redlight Autoparts

App e-commerce pyès machin pou mache Ayisyen — **Flutter** (app kliyan mobile + panel admin web) ak **Supabase** (auth, Postgres, storage).

## Stack

- **Mobile (kliyan)** : Flutter — Android + iOS, tèm sombre (nwa/rouj/blan)
- **Web & PWA (kliyan + admin)** : Flutter Web — menm codebase, responsive sou tout ekran (telefòn, tablèt, laptop, desktop), PWA enstalab ak logo sou telefòn, deplwaman Vercel ultra-rapid
- **Admin Panel** : `/admin` avèk jesyon pwodwi, kategori, kòmand, ofri, retrè, ak dokiman legal
- **Backend** : Supabase (Auth, Postgres, Storage, Realtime)
- **State** : Riverpod · **Navigation** : GoRouter · **Icons** : Lucide · **Font** : DM Sans
- **Lang** : 4 lang — Français (default), Kreyòl ayisyen, English, Español.
  Premye lanse → ekran seleksyon lang; apre → Pwofil → Lang. Tout UI chanje otomatikman.

## 1. Prerequi

- Flutter SDK stable (teste ak 3.47.4)
- Yon pwoj Supabase (gratis sou supabase.com)

## 2. Mete backend la kanpe (Supabase)

Nan Supabase Dashboard → **SQL Editor**, egzekite fichye yo **nan lòd**: (05_seed sèlman si ou vle demo; 06_commerce apre 04_admin)

| Fichye | Sa li fè |
|---|---|
| `supabase/01_schema.sql` | Kreye tab yo (categories, products, orders, order_items, admin_users) + triggers `updated_at` |
| `supabase/02_rls.sql` | Aktive RLS + fonksyon `is_admin()` + `place_order()` (kòmand atomik ak verifikasyon stock) |
| `supabase/03_storage.sql` | Bucket `product-images` (lekti piblik, ekriti admin sèlman) |
| `supabase/04_admin.sql` | ⚠️ **Ranplase `EMAIL_ADMIN_LA@example.com`** ak email admin ou anvan egzekite |
| `supabase/05_seed.sql` | 5 kategori + 13 pwodwi demo (`is_demo = true`) — **demo sèlman, pa pou pwodiksyon** |
| `supabase/06_commerce.sql` | Peman PLOP PLOP, retrè, legal docs, stock/pri sèvè, logo storage, RLS pwofòse |
| `supabase/07_delete_demo.sql` | Retire pwodwi/kategori demo |
| `supabase/README.md` | Secrets, webhook, Google, retrè ak tès deplwaman |

Apre sa, nan **Authentication → Users**, kreye itilizatè admin ou a (menm email ak 04_admin.sql).

> Tip: pou demo a, ou ka dezaktive "Confirm email" nan **Authentication → Sign In / Providers** pou login mache touswit san verifye imèl.

## 3. Konfigirasyon

Kopye `.env.example` → `.env` epi mete kle ou yo (Supabase Dashboard → Project Settings → API):

```
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_ANON_KEY=votre-anon-key
```

Oswa pase yo ak `--dart-define` (san fichye .env).

## 4. Lanse

```bash
flutter pub get

# App kliyan (telefòn / emulatè)
flutter run

# Panel admin (web)
flutter run -d chrome --web-port 3000 \
  --dart-define=SUPABASE_URL=https://votre-projet.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=votre-anon-key
```

- App kliyan: `/` (lang → onboarding → auth/envite → home → katalòg → panyen → checkout → kòmand)
- Panel admin: `/#/admin` — login admin, dashboard, jesyon pwodwi/kategori/kòmand

### Icon + APK release

Icon yo jenere depi `assets/images/logo.jpeg` (logo a nan rasin repo a). Pou rejenere:

```bash
dart run flutter_launcher_icons
```

Pou yon APK release (sonje mete vrè kle Supabase nan `.env` avan):

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

## 5. Retire done demo yo

Lè ou pare pou vrè done:

```sql
-- egzekite supabase/07_delete_demo.sql nan SQL Editor
```

Pwodwi admin kreye gen `is_demo = false`, yo pa afekte. Katalòg piblik la pa montre demo apre `06_commerce.sql`.

## PLOP PLOP

Peman yo pa janm anrejistre `client_secret` nan app la. Sèl sèvis Edge `commerce` pale ak PLOP PLOP; gade `supabase/README.md` pou secrets, webhook URL, aktivasyon Google ak retrè.

## Estrikti

```
lib/
├── main.dart / app.dart     ← bootstrap + GoRouter (routes kliyan vs /admin)
├── core/                    ← theme, konstan, widgets (glass nav, kat pwodwi, shimmer)
├── l10n/                    ← app_strings.dart — tout tèks UI nan 4 lang
├── features/                ← language, onboarding, auth, home, catalog,
│   │                          product_detail, cart, checkout, orders,
│   │                          profile (ak seleksyon lang), favorites
│   └── admin/               ← login, dashboard, products/categories/orders managers
├── models/                  ← Product, Category, AppOrder, CartItem, AppUser
├── services/                ← supabase, auth, product, order, local store
└── providers/               ← Riverpod providers
```

Powered by Cvisual.
