-- Algeria 360 AI Database Schema Extension
-- Supports national destinations (El Oued, Ghardaïa, Djanet, Algiers, etc.) and AI RAG context.

CREATE TABLE IF NOT EXISTS public.destinations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    wilaya TEXT NOT NULL,
    description TEXT,
    history TEXT,
    culture TEXT,
    best_time TEXT,
    duration TEXT,
    activities JSONB DEFAULT '[]'::jsonb,
    image_url TEXT,
    vr_url TEXT,
    ar_enabled BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Add destination_id to places table if not exists
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='places' and column_name='destination_id') THEN
        ALTER TABLE public.places ADD COLUMN destination_id UUID REFERENCES public.destinations(id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='places' and column_name='history') THEN
        ALTER TABLE public.places ADD COLUMN history TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='places' and column_name='ar_url') THEN
        ALTER TABLE public.places ADD COLUMN ar_url TEXT;
    END IF;
END $$;

-- Insert core national destinations including Souf (El Oued) as flagship
INSERT INTO public.destinations (name, wilaya, description, history, culture, best_time, duration, is_featured, image_url)
VALUES 
('وادي سوف (Souf360)', 'وادي سوف', 'مدينة الألف قبة وقبة، عاصمة الواحات والرمال الذهبية في الصحراء الكبرى.', 'تاريخ عريق مرتبط بطرق القوافل الصحراوية ونظام الري الفريد (الغيت).', 'تراث ثقافي غني، صناعات تقليدية، ومعمار فريد مبني بالجبس والقباب.', 'من أكتوبر إلى أبريل', '3 أيام', true, 'https://cwbenhuiextfoiyfboxo.supabase.co/storage/v1/object/public/images/places/souf_oasis.jpg'),
('غرداية (مزاب)', 'غرداية', 'جوهرة ميزاب العمارة الصحراوية الفريدة المسجلة في اليونسكو.', 'تأسست في القرن الحادي عشر الميلادي على يد الإباضية.', 'مجتمع عريق متكاتف يحافظ على تقاليد عمرانية واجتماعية أصيلة.', 'من أكتوبر إلى مارس', 'يومان', true, 'https://cwbenhuiextfoiyfboxo.supabase.co/storage/v1/object/public/images/places/ghardaia.jpg'),
('جانت (تاسيلي ناجير)', 'إليزي / جانت', 'متحف طبيعي مفتوح للرسوم الحجرية العهد القديم ورمال تدرارت.', 'مهد الحضارات البشرية الأولى في الصحراء الكبرى.', 'ثقافة الطوارق الأصيلة وتقاليد الطبخ الصحراوي العريق.', 'من نوفمبر إلى فبرير', '4 أ أيام', true, 'https://cwbenhuiextfoiyfboxo.supabase.co/storage/v1/object/public/images/places/djanet.jpg'),
('الجزائر العاصمة', 'الجزائر', 'البهجة، مدينة البيضاء والقصبة العريقة المطلة على المتوسط.', 'تاريخ ممتد منذ العهد العثماني والفينيقي مع معمار القصبة الشهير.', 'تنوع ثقافي وفني ومعماري فريد يمزج الأصالة بالحداثة.', 'طوال العام', 'يومان', true, 'https://cwbenhuiextfoiyfboxo.supabase.co/storage/v1/object/public/images/places/algiers.jpg')
ON CONFLICT DO NOTHING;
