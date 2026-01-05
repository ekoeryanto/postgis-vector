sumeko/postgis-vector

PostgreSQL 18 + PostGIS + pgvector, dengan auto-enable extension yang aktif secara default dan tetap aman untuk volume lama (runtime ensure).

Image ini dirancang agar cara pakainya tetap seperti postgres resmi, hanya dengan kemampuan tambahan yang pintar dan bisa dikonfigurasi.

⸻

✨ Fitur utama
	•	Base resmi: PostgreSQL 18 + PostGIS (postgis/postgis)
	•	Tambahan: pgvector (dibuild dari source, versi dipin)
	•	Auto-enable extension default ON:
	•	postgis
	•	vector
	•	Runtime detection → extension otomatis dibuat walaupun pakai volume lama
	•	Tetap kompatibel dengan env standar postgres
	•	Multi-arch image: amd64 & arm64

⸻

🏷️ Tags
	•	latest, pg18 → dari branch main
	•	X.Y.Z, X.Y → dari git tag vX.Y.Z

⸻

🚀 Quick start

docker run -d --name db \
  -e POSTGRES_PASSWORD=secret \
  -p 5432:5432 \
  sumeko/postgis-vector:latest

Default behavior:
	•	Extension langsung aktif (postgis, vector)
	•	Target database:
	•	POSTGRES_DB jika diset
	•	fallback ke postgres

⸻

⚙️ Konfigurasi

Matikan semua auto-enable

-e AUTO_ENABLE_EXTENSIONS=false


⸻

Matikan runtime detection (hanya initdb pertama)

-e AUTO_ENABLE_ON_START=false


⸻

Aktifkan hanya pgvector (tanpa PostGIS)

-e AUTO_ENABLE_POSTGIS=false
-e AUTO_ENABLE_PGVECTOR=true


⸻

Target database

Default:

AUTO_ENABLE_DB=__POSTGRES_DB__

Contoh:

-e AUTO_ENABLE_DB=app,analytics

Semua database non-template:

-e AUTO_ENABLE_DB=__ALL__


⸻

Schema extension

-e AUTO_ENABLE_SCHEMA=public


⸻

⚡ Build lebih cepat di jaringan lokal

Image ini berbasis Debian.

Opsi 1 (RECOMMENDED): Proxy (tanpa build-arg)

APT otomatis membaca proxy standar:
	•	http_proxy
	•	https_proxy
	•	no_proxy

Contoh:

export http_proxy=http://proxy.local:3128
export https_proxy=http://proxy.local:3128

docker build -t sumeko/postgis-vector:dev .

Ini adalah cara paling umum & paling disarankan di kantor / kampus / jaringan lokal.

⸻

Opsi 2 (Advanced): Mirror Debian eksplisit

docker build \
  --build-arg APT_MIRROR=http://mirror.kambing.ui.ac.id/debian \
  -t sumeko/postgis-vector:dev .

Contoh mirror Indonesia:
	•	http://mirror.kambing.ui.ac.id/debian
	•	http://kartolo.sby.datautama.net.id/debian

⸻

🧠 Catatan penting
	•	Script di /docker-entrypoint-initdb.d hanya berjalan saat init database pertama (perilaku standar postgres).
	•	Image ini menambahkan runtime ensure yang berjalan setiap container start (jika aktif).
	•	Semua operasi extension bersifat idempotent (CREATE EXTENSION IF NOT EXISTS).
	•	Jika terjadi error saat ensure extension, container tetap jalan (best-effort).

⸻

📄 Lisensi

MIT License
