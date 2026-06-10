-- Create a profiles table to store credits and membership tiers
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade not null primary key,
  email text,
  full_name text,
  credits integer default 0 not null,
  membership_tier text default 'free' not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security
alter table public.profiles enable row level security;

-- Create policies
create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Users can update own profile name/details" on public.profiles
  for update using (auth.uid() = id)
  with check (auth.uid() = id);

-- Function to handle new user signup and insert public profile
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, credits, membership_tier)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    0,
    'free'
  );
  return new;
end;
$$ language plpgsql security definer;

-- Trigger to execute the handle_new_user function on signup
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
