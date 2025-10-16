-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.banners (
  ma_banner uuid NOT NULL DEFAULT uuid_generate_v4(),
  hinh_anh text NOT NULL,
  trang_thai boolean DEFAULT true,
  ngay_tao timestamp with time zone DEFAULT now(),
  ngay_cap_nhat timestamp with time zone DEFAULT now(),
  CONSTRAINT banners_pkey PRIMARY KEY (ma_banner)
);
CREATE TABLE public.cart_details (
  ma_chi_tiet_gio_hang uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_gio_hang uuid,
  ma_bien_the_san_pham uuid,
  so_luong integer NOT NULL DEFAULT 1,
  gia_tien_tai_thoi_diem_them numeric NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT cart_details_pkey PRIMARY KEY (ma_chi_tiet_gio_hang),
  CONSTRAINT cart_details_ma_gio_hang_fkey FOREIGN KEY (ma_gio_hang) REFERENCES public.carts(ma_gio_hang),
  CONSTRAINT cart_details_ma_bien_the_san_pham_fkey FOREIGN KEY (ma_bien_the_san_pham) REFERENCES public.product_variants(ma_bien_the)
);
CREATE TABLE public.carts (
  ma_gio_hang uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_nguoi_dung uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT carts_pkey PRIMARY KEY (ma_gio_hang),
  CONSTRAINT carts_ma_nguoi_dung_fkey FOREIGN KEY (ma_nguoi_dung) REFERENCES public.users(id)
);
CREATE TABLE public.categories (
  ma_danh_muc uuid NOT NULL DEFAULT uuid_generate_v4(),
  ten_danh_muc text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT categories_pkey PRIMARY KEY (ma_danh_muc)
);
CREATE TABLE public.chat_messages (
  ma_tin_nhan uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_chat uuid,
  ma_nguoi_gui uuid,
  noi_dung text NOT NULL,
  loai_tin_nhan text DEFAULT 'text'::text,
  thoi_gian_gui timestamp with time zone DEFAULT now(),
  da_doc boolean DEFAULT false,
  ma_tin_nhan_cha uuid,
  CONSTRAINT chat_messages_pkey PRIMARY KEY (ma_tin_nhan),
  CONSTRAINT chat_messages_ma_chat_fkey FOREIGN KEY (ma_chat) REFERENCES public.chats(ma_chat),
  CONSTRAINT chat_messages_ma_nguoi_gui_fkey FOREIGN KEY (ma_nguoi_gui) REFERENCES public.users(id),
  CONSTRAINT chat_messages_ma_tin_nhan_cha_fkey FOREIGN KEY (ma_tin_nhan_cha) REFERENCES public.chat_messages(ma_tin_nhan)
);
CREATE TABLE public.chats (
  ma_chat uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_nguoi_dung_1 uuid,
  ma_nguoi_dung_2 uuid,
  ngay_tao timestamp with time zone DEFAULT now(),
  ngay_cap_nhat timestamp with time zone DEFAULT now(),
  trang_thai boolean DEFAULT true,
  CONSTRAINT chats_pkey PRIMARY KEY (ma_chat),
  CONSTRAINT chats_ma_nguoi_dung_1_fkey FOREIGN KEY (ma_nguoi_dung_1) REFERENCES public.users(id),
  CONSTRAINT chats_ma_nguoi_dung_2_fkey FOREIGN KEY (ma_nguoi_dung_2) REFERENCES public.users(id)
);
CREATE TABLE public.collection_images (
  ma_hinh_anh uuid NOT NULL DEFAULT uuid_generate_v4(),
  duong_dan_anh text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  ma_bo_suu_tap uuid,
  CONSTRAINT collection_images_pkey PRIMARY KEY (ma_hinh_anh),
  CONSTRAINT collection_images_ma_bo_suu_tap_fkey FOREIGN KEY (ma_bo_suu_tap) REFERENCES public.collections(ma_bo_suu_tap)
);
CREATE TABLE public.collections (
  ma_bo_suu_tap uuid NOT NULL DEFAULT uuid_generate_v4(),
  ten_bo_suu_tap text NOT NULL,
  mo_ta text,
  trang_thai boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT collections_pkey PRIMARY KEY (ma_bo_suu_tap)
);
CREATE TABLE public.colors (
  ma_mau uuid NOT NULL DEFAULT uuid_generate_v4(),
  ten_mau text NOT NULL,
  ma_mau_hex text,
  CONSTRAINT colors_pkey PRIMARY KEY (ma_mau)
);
CREATE TABLE public.discounts (
  ma_giam_gia uuid NOT NULL DEFAULT uuid_generate_v4(),
  noi_dung text NOT NULL,
  code text UNIQUE,
  mo_ta text,
  loai_giam_gia USER-DEFINED NOT NULL,
  muc_giam_gia numeric NOT NULL,
  ngay_bat_dau timestamp with time zone NOT NULL,
  ngay_ket_thuc timestamp with time zone NOT NULL,
  trang_thai_kich_hoat boolean DEFAULT true,
  so_luong_ban_dau integer DEFAULT 0,
  so_luong_da_dung integer DEFAULT 0,
  don_gia_toi_thieu numeric,
  CONSTRAINT discounts_pkey PRIMARY KEY (ma_giam_gia)
);
CREATE TABLE public.favorites (
  ma_nguoi_dung uuid NOT NULL,
  ma_san_pham uuid NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT favorites_pkey PRIMARY KEY (ma_san_pham, ma_nguoi_dung),
  CONSTRAINT favorites_ma_nguoi_dung_fkey FOREIGN KEY (ma_nguoi_dung) REFERENCES public.users(id),
  CONSTRAINT favorites_ma_san_pham_fkey FOREIGN KEY (ma_san_pham) REFERENCES public.products(ma_san_pham)
);
CREATE TABLE public.news (
  ma_tin_tuc uuid NOT NULL DEFAULT uuid_generate_v4(),
  tieu_de text NOT NULL,
  noi_dung text NOT NULL,
  hinh_anh text,
  ngay_dang timestamp with time zone DEFAULT now(),
  trang_thai_hien_thi boolean DEFAULT true,
  CONSTRAINT news_pkey PRIMARY KEY (ma_tin_tuc)
);
CREATE TABLE public.notifications (
  ma_thong_bao uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_nguoi_dung uuid,
  tieu_de text NOT NULL,
  noi_dung text NOT NULL,
  loai_thong_bao USER-DEFINED NOT NULL,
  da_doc boolean DEFAULT false,
  thoi_gian_tao timestamp with time zone DEFAULT now(),
  ma_don_hang uuid,
  ma_khuyen_mai uuid,
  du_lieu_bo_sung jsonb,
  CONSTRAINT notifications_pkey PRIMARY KEY (ma_thong_bao),
  CONSTRAINT notifications_ma_nguoi_dung_fkey FOREIGN KEY (ma_nguoi_dung) REFERENCES public.users(id),
  CONSTRAINT notifications_ma_don_hang_fkey FOREIGN KEY (ma_don_hang) REFERENCES public.orders(ma_don_hang),
  CONSTRAINT notifications_ma_khuyen_mai_fkey FOREIGN KEY (ma_khuyen_mai) REFERENCES public.discounts(ma_giam_gia)
);
CREATE TABLE public.order_details (
  ma_chi_tiet_don_hang uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_don_hang uuid,
  ma_bien_the_san_pham uuid,
  thanh_tien numeric NOT NULL,
  so_luong_mua integer NOT NULL,
  CONSTRAINT order_details_pkey PRIMARY KEY (ma_chi_tiet_don_hang),
  CONSTRAINT order_details_ma_don_hang_fkey FOREIGN KEY (ma_don_hang) REFERENCES public.orders(ma_don_hang),
  CONSTRAINT order_details_ma_bien_the_san_pham_fkey FOREIGN KEY (ma_bien_the_san_pham) REFERENCES public.product_variants(ma_bien_the)
);
CREATE TABLE public.order_statuses (
  ma_trang_thai_don_hang uuid NOT NULL DEFAULT uuid_generate_v4(),
  ten_trang_thai text NOT NULL,
  trang_thai_kich_hoat boolean DEFAULT true,
  CONSTRAINT order_statuses_pkey PRIMARY KEY (ma_trang_thai_don_hang)
);
CREATE TABLE public.orders (
  ma_don_hang uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_nguoi_dung uuid,
  ma_giam_gia uuid,
  dia_chi_giao_hang text NOT NULL,
  ghi_chu text,
  ngay_dat_hang timestamp with time zone DEFAULT now(),
  tong_gia_tri_don_hang numeric NOT NULL,
  ly_do_huy_hoan_hang text,
  ma_trang_thai_don_hang uuid,
  CONSTRAINT orders_pkey PRIMARY KEY (ma_don_hang),
  CONSTRAINT orders_ma_nguoi_dung_fkey FOREIGN KEY (ma_nguoi_dung) REFERENCES public.users(id),
  CONSTRAINT orders_ma_giam_gia_fkey FOREIGN KEY (ma_giam_gia) REFERENCES public.discounts(ma_giam_gia),
  CONSTRAINT orders_ma_trang_thai_don_hang_fkey FOREIGN KEY (ma_trang_thai_don_hang) REFERENCES public.order_statuses(ma_trang_thai_don_hang)
);
CREATE TABLE public.product_images (
  ma_hinh_anh uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_san_pham uuid,
  duong_dan_anh text NOT NULL,
  CONSTRAINT product_images_pkey PRIMARY KEY (ma_hinh_anh),
  CONSTRAINT product_images_ma_san_pham_fkey FOREIGN KEY (ma_san_pham) REFERENCES public.products(ma_san_pham)
);
CREATE TABLE public.product_variants (
  ma_bien_the uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_san_pham uuid,
  ma_size uuid,
  ma_mau uuid,
  ton_kho integer DEFAULT 0,
  CONSTRAINT product_variants_pkey PRIMARY KEY (ma_bien_the),
  CONSTRAINT product_variants_ma_san_pham_fkey FOREIGN KEY (ma_san_pham) REFERENCES public.products(ma_san_pham),
  CONSTRAINT product_variants_ma_size_fkey FOREIGN KEY (ma_size) REFERENCES public.sizes(ma_size),
  CONSTRAINT product_variants_ma_mau_fkey FOREIGN KEY (ma_mau) REFERENCES public.colors(ma_mau)
);
CREATE TABLE public.products (
  ma_san_pham uuid NOT NULL DEFAULT uuid_generate_v4(),
  ten_san_pham text NOT NULL,
  mo_ta_san_pham text,
  muc_gia_goc numeric NOT NULL,
  gia_ban numeric NOT NULL,
  so_luong_dat_toi_thieu integer DEFAULT 1,
  trang_thai_hien_thi boolean DEFAULT true,
  ngay_tao_ban_ghi timestamp with time zone DEFAULT now(),
  ngay_sua_ban_ghi timestamp with time zone DEFAULT now(),
  ma_danh_muc uuid,
  ma_bo_suu_tap uuid,
  CONSTRAINT products_pkey PRIMARY KEY (ma_san_pham),
  CONSTRAINT products_ma_danh_muc_fkey FOREIGN KEY (ma_danh_muc) REFERENCES public.categories(ma_danh_muc),
  CONSTRAINT products_ma_bo_suu_tap_fkey FOREIGN KEY (ma_bo_suu_tap) REFERENCES public.collections(ma_bo_suu_tap)
);
CREATE TABLE public.review_images (
  ma_hinh_anh uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_danh_gia uuid,
  duong_dan_anh text NOT NULL,
  thoi_gian_tao timestamp with time zone DEFAULT now(),
  thoi_gian_cap_nhat timestamp with time zone DEFAULT now(),
  CONSTRAINT review_images_pkey PRIMARY KEY (ma_hinh_anh),
  CONSTRAINT review_images_ma_danh_gia_fkey FOREIGN KEY (ma_danh_gia) REFERENCES public.reviews(ma_danh_gia)
);
CREATE TABLE public.reviews (
  ma_danh_gia uuid NOT NULL DEFAULT uuid_generate_v4(),
  ma_nguoi_dung uuid,
  ma_san_pham uuid,
  diem_danh_gia integer CHECK (diem_danh_gia >= 1 AND diem_danh_gia <= 5),
  noi_dung_danh_gia text NOT NULL,
  ma_danh_gia_cha uuid,
  thoi_gian_tao timestamp with time zone DEFAULT now(),
  thoi_gian_cap_nhat timestamp with time zone DEFAULT now(),
  CONSTRAINT reviews_pkey PRIMARY KEY (ma_danh_gia),
  CONSTRAINT reviews_ma_nguoi_dung_fkey FOREIGN KEY (ma_nguoi_dung) REFERENCES public.users(id),
  CONSTRAINT reviews_ma_san_pham_fkey FOREIGN KEY (ma_san_pham) REFERENCES public.products(ma_san_pham),
  CONSTRAINT reviews_ma_danh_gia_cha_fkey FOREIGN KEY (ma_danh_gia_cha) REFERENCES public.reviews(ma_danh_gia)
);
CREATE TABLE public.roles (
  ma_role text NOT NULL,
  ten_role text NOT NULL,
  CONSTRAINT roles_pkey PRIMARY KEY (ma_role)
);
CREATE TABLE public.sizes (
  ma_size uuid NOT NULL DEFAULT uuid_generate_v4(),
  ten_size text NOT NULL UNIQUE,
  CONSTRAINT sizes_pkey PRIMARY KEY (ma_size)
);
CREATE TABLE public.stores (
  ma_cua_hang uuid NOT NULL DEFAULT uuid_generate_v4(),
  ten_cua_hang text NOT NULL,
  dia_chi text NOT NULL,
  so_dien_thoai text NOT NULL,
  trang_thai boolean DEFAULT true,
  CONSTRAINT stores_pkey PRIMARY KEY (ma_cua_hang)
);
CREATE TABLE public.users (
  id uuid NOT NULL,
  ten_nguoi_dung text NOT NULL,
  email text NOT NULL UNIQUE,
  so_dien_thoai text,
  ngay_sinh date,
  gioi_tinh text CHECK (gioi_tinh = ANY (ARRAY['male'::text, 'female'::text, 'other'::text])),
  dia_chi text,
  avatar text,
  ma_role USER-DEFINED DEFAULT 'user'::user_role,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);