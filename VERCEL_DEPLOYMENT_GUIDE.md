# Gid Deplwaman Vercel & PWA pou Redlight Autoparts

Dokiman sa a eksplike kijan Vercel ap jwenn dosye aplikasyon an dirèkteman, kijan pou deplwaye l pou l chaje rapid anpil, epi kijan PWA (Progressive Web App) a mache sou telefòn itilizatè yo.

---

## 1. Kijan Vercel jwenn dosye Aplikasyon an (Zero Configuration)

Repo a deja konfigire pou Vercel jwenn aplikasyon an san ou pa bezwen modifye anyen konplike:

1. **Dosye pwodiksyon an**: `build/web` gen tout aplikasyon Web la deja konpile avèk CanvasKit, Service Worker, logo, ak paj HTML yo.
2. **`vercel.json` nan rasin lan**:
   ```json
   {
     "version": 2,
     "outputDirectory": "build/web",
     "cleanUrls": true,
     "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
   }
   ```
3. **`package.json`**: Gen script `"build"` otomatik ki enfòme Vercel pou l sèvi dosye `build/web` la dirèkteman.

### Opsyon Deplwaman sou Vercel Dashboard:
- **Root Directory**: Kite l sou `./` (rasin pwojè a). Vercel ap itilize `build/web` otomatikman gras a `vercel.json`.
- Si ou vle mete Root Directory dirèkteman sou `build/web` nan Vercel, li gen pwòp `vercel.json` pa l tou ki pare pou sa.
- **Build Command**: Pa bezwen anyen (kite l vid oswa default).
- **Output Directory**: `build/web` (oswa `.` si ou te chwazi `build/web` kòm Root Directory).

---

## 2. Kijan nou fè aplikasyon an chaje rapid sou Web (Performance Boost)

Pou anpeche aplikasyon an pran tan oswa montre yon ekran nwa/blan pandan telechajman an:

1. **Splash Screen Imedya an CSS pi**:
   - Olye yon ekran vid pandan navigatè a ap telechaje JavaScript la, yon bèl ekran nwa avèk logo Redlight k ap klere, non "REDLIGHT AUTOPARTS", ak yon bar pwogrè rouj parèt **nan mwens pase 50 milisegond**.
   - Kou Flutter fin pare, splash la disparèt avèk yon bèl animasyon fondu (`fade-out`).
2. **Cache Headers 1 An (Immutable)**:
   - Fichye `.js`, `.wasm`, imaj, polis ak CanvasKit yo genyen header `Cache-Control: public, max-age=31536000, immutable`.
   - Sa vle di yon fwa yon moun louvri sit la yon premye fwa, dezyèm fwa a li ouvri **enstantaneman** san li pa retelechaje anyen nan rezo a!
3. **Service Worker Entegre**:
   - Pèmèt kach lokal e menm fonksyonman offline sou rezo ki fèb.

---

## 3. Fonksyonalite PWA (Progressive Web App)

PWA a pèmèt nenpòt moun ki vizite sit la sou telefòn li (Android oswa iPhone) ka enstale l tankou yon vrè aplikasyon natif:

1. **Banyè Enstalasyon Entelijan**:
   - Lè yon moun louvri sit la sou Chrome sou Android, yon banyè anba parèt otomatikman:
     **"Redlight Autoparts — Enstale app la sou telefòn ou"** avèk yon bouton rouj **"Enstale"**.
   - Lè li klike sou "Enstale", sistèm Android la mande l konfimasyon epi mete icon Redlight la sou ekran akèy telefòn li!
2. **Sipò pou iPhone & iPad (iOS Safari)**:
   - iOS pa sipòte èd memwa otomatik la, kidonk yon ti banyè èd ap parèt sou Safari:
     *"Peze bouton Pataje (Share) ⎋ epi chwazi 'Ajoute sou ekran akèy' ➕"*.
3. **Mòd Standalone**:
   - Kou moun nan louvri app a depi sou ekran telefòn li, li ouvri san bar URL navigatè a, an plen ekran, egzakteman tankou yon aplikasyon telechaje sou Play Store oswa App Store!

---

## 4. Adaptabilite Responsive sou tout Ekran

Tout ekran nan app la (ni Boutik Kliyan an, ni Panel Admin nan) adapte sou:
- **Telefòn (320px - 650px)**: 1-2 kolòn, navigasyon anba `GlassNavBar` santre (max 520px), bouton gwo ase pou dwèt.
- **Tablèt (650px - 1024px)**: 3-4 kolòn pwodwi, 2 kolòn kategori, bèl Layout santre, `GlassNavBar` ki pa janm lonje sou tout lajè tablèt la.
- **Laptop & Desktop (>= 1024px)**:
  - **Boutik Kliyan**: Header Web elegant anwo avèk logo, onglet navigasyon, seleksyon lang, mòd sombre/clè, ak bouton Admin.
  - **Panel Admin**: Sidebar fiks sou bò goch (240px) avèk kontni pwòp sou bò dwat san okenn debòdman (`RenderFlex overflow`).
  - **Panyen (Cart)**: Layout 2 kolòn (lis pwodwi sou goch, rezime kòmand sou dwat).
  - **Fich Pwodwi**: Layout adaptif santre.
