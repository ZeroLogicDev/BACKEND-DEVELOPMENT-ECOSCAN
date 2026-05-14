-- 1. Buat tabel Profil Pengguna (Otomatis terhubung dengan Auth)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  total_points INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Buat tabel Riwayat Scan
CREATE TABLE scan_history (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  class_name TEXT NOT NULL,
  category TEXT NOT NULL,
  confidence NUMERIC NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Aktifkan Row Level Security (RLS) untuk Keamanan
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE scan_history ENABLE ROW LEVEL SECURITY;

-- 4. Buat Kebijakan (Policies) agar user hanya bisa melihat & menambah datanya sendiri
CREATE POLICY "User bisa melihat profilnya sendiri" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "User bisa mengupdate profilnya sendiri" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "User bisa melihat riwayatnya sendiri" ON scan_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "User bisa menambah riwayatnya sendiri" ON scan_history FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. Trigger otomatis: Buat baris di 'profiles' setiap ada user baru yang Register
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
