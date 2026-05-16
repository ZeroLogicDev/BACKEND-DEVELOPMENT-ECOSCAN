-- 1. SOLUSI UNTUK AKUN LAMA (Memasukkan email juga)
INSERT INTO public.profiles (id, email, full_name)
SELECT 
  id, 
  email,
  COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', 'Pengguna EcoScan') as full_name
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles);


-- 2. SOLUSI OTOMATIS UNTUK PENGGUNA BARU (TRIGGER)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    new.id,
    new.email, -- Menyalin email pengguna secara otomatis
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Pengguna EcoScan')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Buat Trigger-nya
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
