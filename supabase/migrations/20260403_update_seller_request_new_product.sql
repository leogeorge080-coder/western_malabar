drop function if exists public.seller_request_new_product;

create function public.seller_request_new_product(
  _product_name text,
  _slug text default null,
  _category_id uuid default null,
  _brand_id uuid default null,
  _description text default null,
  _barcode text default null,
  _requested_image_url text default null,
  _requested_price_cents integer default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_active_seller(auth.uid()) then
    raise exception 'Seller access inactive';
  end if;

  if _product_name is null or trim(_product_name) = '' then
    raise exception 'Product name is required';
  end if;

  if _requested_price_cents is null or _requested_price_cents <= 0 then
    raise exception 'Requested price is required';
  end if;

  insert into public.seller_product_requests (
    seller_id,
    product_name,
    normalized_name,
    slug,
    category_id,
    brand_id,
    description,
    barcode,
    requested_image_url,
    requested_price_cents,
    status,
    duplicate_status,
    duplicate_confidence,
    issue_flags,
    created_at
  )
  values (
    auth.uid(),
    trim(_product_name),
    lower(trim(_product_name)),
    nullif(trim(_slug), ''),
    _category_id,
    _brand_id,
    nullif(trim(_description), ''),
    nullif(trim(_barcode), ''),
    nullif(trim(_requested_image_url), ''),
    _requested_price_cents,
    'pending',
    'unchecked',
    0,
    '[]'::jsonb,
    now()
  );
end;
$$;

revoke all on function public.seller_request_new_product(text, text, uuid, uuid, text, text, text, integer) from public;
grant execute on function public.seller_request_new_product(text, text, uuid, uuid, text, text, text, integer) to authenticated;
