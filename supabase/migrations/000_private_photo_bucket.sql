-- Optional first step for storage-only setup; 001 can also create this bucket.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('flock-photos','flock-photos',false,5242880,array['image/jpeg','image/png','image/webp']) on conflict(id) do nothing;
