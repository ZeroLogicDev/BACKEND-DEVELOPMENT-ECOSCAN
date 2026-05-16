-- 1. Berikan hak akses dasar untuk role 'authenticated'
GRANT ALL ON TABLE public.scan_history TO authenticated;
GRANT ALL ON TABLE public.profiles TO authenticated;

-- 2. Aktifkan Row Level Security (RLS) agar aman
ALTER TABLE public.scan_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Buat aturan (Policies) agar user hanya bisa melihat & menambah data milik mereka sendiri
-- Untuk tabel scan_history
CREATE POLICY "Enable insert for authenticated users only" ON public.scan_history FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Enable read access for own history" ON public.scan_history FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Untuk tabel profiles
CREATE POLICY "Enable read access for own profile" ON public.profiles FOR SELECT TO authenticated USING (auth.uid() = id);
CREATE POLICY "Enable update for own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
