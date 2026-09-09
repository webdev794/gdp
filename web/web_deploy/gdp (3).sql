-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 09, 2026 at 01:32 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `gdp`
--

-- --------------------------------------------------------

--
-- Table structure for table `addresses`
--

CREATE TABLE `addresses` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `label` varchar(255) NOT NULL DEFAULT 'Home',
  `name` varchar(120) NOT NULL,
  `line1` varchar(255) NOT NULL,
  `line2` varchar(255) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `state` varchar(60) DEFAULT NULL,
  `postal_code` varchar(12) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `addresses`
--

INSERT INTO `addresses` (`id`, `user_id`, `label`, `name`, `line1`, `line2`, `city`, `state`, `postal_code`, `latitude`, `longitude`, `is_default`, `created_at`, `updated_at`) VALUES
(1, 17, 'Home', 'Testcaresort', '34 Jan Marg', NULL, 'Mohali', 'PB', '160061', 30.7149794, 76.7227993, 1, '2026-09-09 02:28:05', '2026-09-09 02:28:05'),
(2, 15, 'Home', 'Test User', '34 Jan Marg', NULL, 'Mohali', 'PB', '160061', 30.7149794, 76.7227993, 1, '2026-09-09 04:04:43', '2026-09-09 04:04:43');

-- --------------------------------------------------------

--
-- Table structure for table `auth_otps`
--

CREATE TABLE `auth_otps` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `email` varchar(255) NOT NULL,
  `purpose` varchar(255) NOT NULL,
  `code_hash` varchar(255) NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `expires_at` timestamp NULL DEFAULT NULL,
  `last_sent_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `banners`
--

CREATE TABLE `banners` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `image_url` varchar(255) NOT NULL,
  `headline` varchar(255) DEFAULT NULL,
  `category_slug` varchar(255) DEFAULT NULL,
  `link_url` varchar(255) DEFAULT NULL,
  `placement` varchar(255) NOT NULL DEFAULT 'hero',
  `sort_order` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `banners`
--

INSERT INTO `banners` (`id`, `image_url`, `headline`, `category_slug`, `link_url`, `placement`, `sort_order`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'https://cdn.grofers.com/cdn-cgi/image/f=auto,fit=scale-down,q=70,metadata=none,w=2700/layout-engine/2026-01/Frame-1437256605-2-2.jpg', NULL, 'fresh-produce', NULL, 'hero', 1, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(2, 'https://cdn.grofers.com/cdn-cgi/image/f=auto,fit=scale-down,q=70,metadata=none,w=720/layout-engine/2023-07/pharmacy-WEB.jpg', NULL, 'personal-care', NULL, 'strip', 2, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(3, 'https://cdn.grofers.com/cdn-cgi/image/f=auto,fit=scale-down,q=70,metadata=none,w=720/layout-engine/2026-01/pet_crystal_WEB-1.png', NULL, 'home-and-kitchen', NULL, 'strip', 3, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(4, 'https://cdn.grofers.com/cdn-cgi/image/f=auto,fit=scale-down,q=70,metadata=none,w=720/layout-engine/2026-01/baby_crystal_WEB-1.png', NULL, 'baby-care', NULL, 'strip', 4, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49');

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cache`
--

INSERT INTO `cache` (`key`, `value`, `expiration`) VALUES
('gdp-cache-5c785c036466adea360111aa28563bfd556b5fba', 'i:1;', 1788952747),
('gdp-cache-5c785c036466adea360111aa28563bfd556b5fba:timer', 'i:1788952747;', 1788952747),
('gdp-cache-geo:search:10cdb4eb2195350bbedb9efe333e521a', 'a:2:{i:0;a:8:{s:5:\"label\";s:36:\"Mohali, S.A.S. Nagar (Mohali) Tahsil\";s:4:\"full\";s:87:\"Mohali, S.A.S. Nagar (Mohali) Tahsil, Sahibzada Ajit Singh Nagar, Punjab, 140062, India\";s:5:\"line1\";s:64:\"Mohali, S.A.S. Nagar (Mohali) Tahsil, Sahibzada Ajit Singh Nagar\";s:4:\"city\";s:6:\"Mohali\";s:5:\"state\";s:6:\"Punjab\";s:11:\"postal_code\";s:6:\"140062\";s:3:\"lat\";d:30.6908804;s:3:\"lon\";d:76.7114879;}i:1;a:8:{s:5:\"label\";s:34:\"Sahibzada Ajit Singh Nagar, Punjab\";s:4:\"full\";s:41:\"Sahibzada Ajit Singh Nagar, Punjab, India\";s:5:\"line1\";s:41:\"Sahibzada Ajit Singh Nagar, Punjab, India\";s:4:\"city\";s:26:\"Sahibzada Ajit Singh Nagar\";s:5:\"state\";s:6:\"Punjab\";s:11:\"postal_code\";s:0:\"\";s:3:\"lat\";d:30.6488449;s:3:\"lon\";d:76.7412738;}}', 1789023796),
('gdp-cache-geo:search:f5b077e12c3d6147e345fdec766bfac3', 'a:2:{i:0;a:8:{s:5:\"label\";s:32:\"Ludhiana, Ludhiana (West) Tahsil\";s:4:\"full\";s:65:\"Ludhiana, Ludhiana (West) Tahsil, Ludhiana, Punjab, 141001, India\";s:5:\"line1\";s:42:\"Ludhiana, Ludhiana (West) Tahsil, Ludhiana\";s:4:\"city\";s:8:\"Ludhiana\";s:5:\"state\";s:6:\"Punjab\";s:11:\"postal_code\";s:6:\"141001\";s:3:\"lat\";d:30.9090157;s:3:\"lon\";d:75.851601;}i:1;a:8:{s:5:\"label\";s:16:\"Ludhiana, Punjab\";s:4:\"full\";s:23:\"Ludhiana, Punjab, India\";s:5:\"line1\";s:23:\"Ludhiana, Punjab, India\";s:4:\"city\";s:8:\"Ludhiana\";s:5:\"state\";s:6:\"Punjab\";s:11:\"postal_code\";s:0:\"\";s:3:\"lat\";d:30.789407;s:3:\"lon\";d:75.8269724;}}', 1789024009),
('gdp-cache-setting:branding', 'a:1:{s:1:\"v\";a:9:{s:10:\"store_name\";s:8:\"Grocerly\";s:7:\"tagline\";s:26:\"Fresh groceries, less fuss\";s:8:\"logo_url\";N;s:11:\"favicon_url\";s:83:\"http://127.0.0.1:8000/storage/products/IylK58VcMqgCgj81gvBdM7HMnHi9XTQAiM9oKlEP.jpg\";s:5:\"theme\";s:5:\"light\";s:12:\"layout_width\";s:5:\"boxed\";s:11:\"color_brand\";s:7:\"#1f7a3d\";s:12:\"color_accent\";s:7:\"#ffd23f\";s:13:\"color_heading\";s:7:\"#18211c\";}}', 2104297308),
('gdp-cache-setting:checkout_fees', 'a:1:{s:7:\"missing\";b:1;}', 2104296063),
('gdp-cache-setting:cod_enabled', 'a:1:{s:7:\"missing\";b:1;}', 2104296063),
('gdp-cache-setting:footer', 'a:1:{s:1:\"v\";a:5:{s:9:\"copyright\";s:18:\"© {year} Grocerly\";s:13:\"app_store_url\";s:40:\"https://apps.apple.com/app/grocerly-demo\";s:14:\"play_store_url\";s:63:\"https://play.google.com/store/apps/details?id=com.grocerly.demo\";s:7:\"socials\";a:5:{s:8:\"facebook\";s:29:\"https://facebook.com/grocerly\";s:1:\"x\";s:22:\"https://x.com/grocerly\";s:9:\"instagram\";s:30:\"https://instagram.com/grocerly\";s:8:\"linkedin\";s:41:\"https://www.linkedin.com/company/grocerly\";s:7:\"youtube\";s:33:\"https://www.youtube.com/@grocerly\";}s:5:\"links\";a:0:{}}}', 2104297180),
('gdp-cache-setting:payments', 'a:1:{s:7:\"missing\";b:1;}', 2104296062),
('gdp-cache-setting:rider_auto_assign', 'a:1:{s:7:\"missing\";b:1;}', 2104297300);

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `carts`
--

CREATE TABLE `carts` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `carts`
--

INSERT INTO `carts` (`id`, `user_id`, `created_at`, `updated_at`) VALUES
(1, 17, '2026-09-09 02:28:05', '2026-09-09 02:28:05'),
(2, 15, '2026-09-09 04:04:42', '2026-09-09 04:04:42');

-- --------------------------------------------------------

--
-- Table structure for table `cart_items`
--

CREATE TABLE `cart_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `cart_id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `product_variant_id` bigint(20) UNSIGNED DEFAULT NULL,
  `quantity` int(10) UNSIGNED NOT NULL,
  `unit_price_cents` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `slug`, `description`, `image_url`, `is_active`, `sort_order`, `created_at`, `updated_at`) VALUES
(1, 'Fruits & Vegetables', 'fresh-produce', NULL, '/img/cat/fresh-produce.png', 1, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(2, 'Dairy, Bread & Eggs', 'dairy-and-eggs', NULL, '/img/cat/dairy-and-eggs.png', 1, 2, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(3, 'Atta, Rice & Dal', 'pantry-staples', NULL, '/img/cat/pantry-staples.png', 1, 3, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(4, 'Snacks & Munchies', 'snacks-and-munchies', NULL, '/img/cat/snacks-and-munchies.png', 1, 4, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(5, 'Cold Drinks & Juices', 'beverages', NULL, '/img/cat/beverages.png', 1, 5, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(6, 'Bakery & Biscuits', 'bakery-and-breads', NULL, '/img/cat/bakery-and-breads.png', 1, 6, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(7, 'Breakfast & Instant Food', 'breakfast-and-cereal', NULL, '/img/cat/breakfast-and-cereal.png', 1, 7, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(8, 'Sweet Tooth', 'sweets-and-chocolate', NULL, '/img/cat/sweets-and-chocolate.png', 1, 8, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(9, 'Chicken, Meat & Fish', 'meat-and-seafood', NULL, '/img/cat/meat-and-seafood.png', 1, 9, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(10, 'Frozen Foods', 'frozen-foods', NULL, '/img/cat/frozen-foods.png', 1, 10, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(11, 'Tea, Coffee & Health Drink', 'tea-and-coffee', NULL, '/img/cat/tea-and-coffee.png', 1, 11, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(12, 'Sauces & Spreads', 'sauces-and-spreads', NULL, '/img/cat/sauces-and-spreads.png', 1, 12, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(13, 'Cleaning Essentials', 'cleaning-essentials', NULL, '/img/cat/cleaning-essentials.png', 1, 13, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(14, 'Personal Care', 'personal-care', NULL, '/img/cat/personal-care.png', 1, 14, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(15, 'Baby Care', 'baby-care', NULL, '/img/cat/baby-care.png', 1, 15, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(16, 'Home & Office', 'home-and-kitchen', NULL, '/img/cat/home-and-kitchen.png', 1, 16, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(17, 'Paan Corner', 'paan-corner', NULL, '/img/cat/paan-corner.png', 1, 17, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(18, 'Pharma & Wellness', 'pharma-wellness', NULL, '/img/cat/pharma-wellness.png', 1, 18, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(19, 'Organic & Premium', 'organic-premium', NULL, '/img/cat/organic-premium.png', 1, 19, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(20, 'Pet Care', 'pet-care', NULL, '/img/cat/pet-care.png', 1, 20, '2026-09-09 01:12:49', '2026-09-09 01:12:49');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` varchar(255) NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `home_tiles`
--

CREATE TABLE `home_tiles` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `category_slug` varchar(255) DEFAULT NULL,
  `link_url` varchar(255) DEFAULT NULL,
  `sort_order` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `home_tiles`
--

INSERT INTO `home_tiles` (`id`, `title`, `image_url`, `category_slug`, `link_url`, `sort_order`, `is_active`, `created_at`, `updated_at`) VALUES
(1, NULL, NULL, 'fresh-produce', NULL, 1, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(2, NULL, NULL, 'dairy-and-eggs', NULL, 2, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(3, NULL, NULL, 'pantry-staples', NULL, 3, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(4, NULL, NULL, 'snacks-and-munchies', NULL, 4, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(5, NULL, NULL, 'beverages', NULL, 5, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(6, NULL, NULL, 'bakery-and-breads', NULL, 6, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(7, NULL, NULL, 'breakfast-and-cereal', NULL, 7, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(8, NULL, NULL, 'sweets-and-chocolate', NULL, 8, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(9, NULL, NULL, 'meat-and-seafood', NULL, 9, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(10, NULL, NULL, 'frozen-foods', NULL, 10, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(11, NULL, NULL, 'tea-and-coffee', NULL, 11, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(12, NULL, NULL, 'sauces-and-spreads', NULL, 12, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(13, NULL, NULL, 'cleaning-essentials', NULL, 13, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(14, NULL, NULL, 'personal-care', NULL, 14, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(15, NULL, NULL, 'baby-care', NULL, 15, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(16, NULL, NULL, 'home-and-kitchen', NULL, 16, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(17, NULL, NULL, 'paan-corner', NULL, 17, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(18, NULL, NULL, 'pharma-wellness', NULL, 18, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(19, NULL, NULL, 'organic-premium', NULL, 19, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(20, NULL, NULL, 'pet-care', NULL, 20, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49');

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` smallint(5) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000000_create_users_table', 1),
(2, '0001_01_01_000001_create_cache_table', 1),
(3, '0001_01_01_000002_create_jobs_table', 1),
(4, '2026_09_04_054409_create_personal_access_tokens_table', 1),
(5, '2026_09_04_060000_create_categories_table', 1),
(6, '2026_09_04_060001_create_products_table', 1),
(7, '2026_09_04_070000_create_carts_table', 1),
(8, '2026_09_04_070001_create_cart_items_table', 1),
(9, '2026_09_04_080000_create_orders_table', 1),
(10, '2026_09_04_080001_create_order_items_table', 1),
(11, '2026_09_04_090000_create_addresses_table', 1),
(12, '2026_09_04_100000_add_stripe_payment_intent_to_orders_table', 1),
(13, '2026_09_04_110000_create_stripe_events_table', 1),
(14, '2026_09_04_120000_add_is_admin_to_users_table', 1),
(15, '2026_09_04_130000_add_courier_name_to_orders_table', 1),
(16, '2026_09_04_140000_create_auth_otps_table', 1),
(17, '2026_09_04_150000_create_stores_table', 1),
(18, '2026_09_04_150001_add_geo_to_addresses_table', 1),
(19, '2026_09_07_120000_create_settings_table', 1),
(20, '2026_09_07_120001_add_payment_method_to_orders_table', 1),
(21, '2026_09_07_140000_add_fee_breakdown_to_orders_table', 1),
(22, '2026_09_07_160000_create_product_variants_table', 1),
(23, '2026_09_07_160001_add_variant_to_cart_items_table', 1),
(24, '2026_09_07_160002_add_variant_to_order_items_table', 1),
(25, '2026_09_07_180000_relax_address_text_columns', 1),
(26, '2026_09_07_190000_add_delivery_instructions_to_orders_table', 1),
(27, '2026_09_07_200000_rename_preparing_status_to_packing', 1),
(28, '2026_09_07_210000_add_stripe_refund_id_to_orders_table', 1),
(29, '2026_09_07_220000_create_support_threads_table', 1),
(30, '2026_09_07_220001_create_support_messages_table', 1),
(31, '2026_09_07_220002_create_order_refunds_table', 1),
(32, '2026_09_07_230000_add_last_staff_message_at_to_support_threads', 1),
(33, '2026_09_07_240000_add_is_rider_to_users_table', 1),
(34, '2026_09_07_240001_add_delivery_partner_to_orders_table', 1),
(35, '2026_09_07_250000_add_phone_to_users_table', 1),
(36, '2026_09_07_260000_create_banners_table', 1),
(37, '2026_09_07_270000_create_home_tiles_table', 1),
(38, '2026_09_07_280000_create_pages_table', 1),
(39, '2026_09_08_090000_add_placement_to_banners_table', 1),
(40, '2026_09_08_100000_add_compare_at_price_to_products_and_variants', 1),
(41, '2026_09_08_110000_add_compare_at_price_to_order_items_table', 1),
(42, '2026_09_08_120000_add_sections_to_pages_table', 1),
(43, '2026_09_08_130000_add_banner_image_to_pages_table', 1),
(44, '2026_09_08_140000_add_stripe_customer_id_to_users_table', 1),
(45, '2026_09_09_120000_create_store_inventory_table', 2),
(46, '2026_09_09_130000_add_store_id_to_orders_table', 2),
(47, '2026_09_09_140000_add_rider_profile_and_stores', 2),
(48, '2026_09_09_150000_drop_legacy_product_store_scope', 2),
(49, '2026_09_09_160000_add_delivery_confirmation_to_orders', 3),
(50, '2026_09_09_170000_create_rider_reviews_table', 4),
(51, '2026_09_09_180000_add_chat_rating_to_support_threads', 5);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `store_id` bigint(20) UNSIGNED DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending_payment',
  `delivered_at` timestamp NULL DEFAULT NULL,
  `delivery_verified` tinyint(1) DEFAULT NULL,
  `delivery_note` varchar(300) DEFAULT NULL,
  `delivery_code` varchar(8) DEFAULT NULL,
  `delivery_code_expires_at` timestamp NULL DEFAULT NULL,
  `courier_name` varchar(255) DEFAULT NULL,
  `delivery_partner_id` bigint(20) UNSIGNED DEFAULT NULL,
  `payment_status` varchar(255) NOT NULL DEFAULT 'pending',
  `payment_method` varchar(255) NOT NULL DEFAULT 'card',
  `stripe_payment_intent_id` varchar(255) DEFAULT NULL,
  `stripe_refund_id` varchar(255) DEFAULT NULL,
  `refunded_amount_cents` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `subtotal_cents` int(10) UNSIGNED NOT NULL,
  `tax_cents` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `delivery_fee_cents` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `handling_fee_cents` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `small_cart_fee_cents` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `total_cents` int(10) UNSIGNED NOT NULL,
  `delivery_address` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`delivery_address`)),
  `delivery_instructions` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `user_id`, `store_id`, `status`, `delivered_at`, `delivery_verified`, `delivery_note`, `delivery_code`, `delivery_code_expires_at`, `courier_name`, `delivery_partner_id`, `payment_status`, `payment_method`, `stripe_payment_intent_id`, `stripe_refund_id`, `refunded_amount_cents`, `subtotal_cents`, `tax_cents`, `delivery_fee_cents`, `handling_fee_cents`, `small_cart_fee_cents`, `total_cents`, `delivery_address`, `delivery_instructions`, `created_at`, `updated_at`) VALUES
(3, 17, 1, 'completed', '2026-09-09 05:02:14', 0, 'handover', NULL, NULL, 'Sam Rider', 16, 'paid', 'card', 'pi_3UDgOR0B2YCt230S19KF65rm', NULL, 0, 2076, 184, 299, 99, 0, 2658, '{\"id\":1,\"user_id\":17,\"label\":\"Home\",\"name\":\"Testcaresort\",\"line1\":\"34 Jan Marg\",\"line2\":null,\"city\":\"Mohali\",\"state\":\"PB\",\"postal_code\":\"160061\",\"latitude\":30.7149794,\"longitude\":76.7227993,\"is_default\":true,\"created_at\":\"2026-09-09T07:58:05.000000Z\",\"updated_at\":\"2026-09-09T07:58:05.000000Z\",\"phone\":\"9888888888\"}', NULL, '2026-09-09 02:28:06', '2026-09-09 05:08:19'),
(4, 15, 1, 'pending_payment', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'pending', 'card', 'pi_3UDhtx0B2YCt230S04mttzuf', NULL, 0, 519, 46, 299, 99, 199, 1162, '{\"id\":2,\"user_id\":15,\"label\":\"Home\",\"name\":\"Test User\",\"line1\":\"34 Jan Marg\",\"line2\":null,\"city\":\"Mohali\",\"state\":\"PB\",\"postal_code\":\"160061\",\"latitude\":30.7149794,\"longitude\":76.7227993,\"is_default\":true,\"created_at\":\"2026-09-09T09:34:43.000000Z\",\"updated_at\":\"2026-09-09T09:34:43.000000Z\",\"phone\":\"+15551234567\"}', NULL, '2026-09-09 04:04:44', '2026-09-09 04:04:45');

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `product_variant_id` bigint(20) UNSIGNED DEFAULT NULL,
  `product_name` varchar(255) NOT NULL,
  `sku` varchar(255) NOT NULL,
  `variant_label` varchar(255) DEFAULT NULL,
  `quantity` int(10) UNSIGNED NOT NULL,
  `unit_price_cents` int(10) UNSIGNED NOT NULL,
  `compare_at_price_cents` int(10) UNSIGNED DEFAULT NULL,
  `line_total_cents` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`id`, `order_id`, `product_id`, `product_variant_id`, `product_name`, `sku`, `variant_label`, `quantity`, `unit_price_cents`, `compare_at_price_cents`, `line_total_cents`, `created_at`, `updated_at`) VALUES
(1, 3, 8, NULL, 'Greek Yogurt', 'GDP-PROD-010', NULL, 4, 519, 649, 2076, '2026-09-09 02:28:06', '2026-09-09 02:28:06'),
(2, 4, 8, NULL, 'Greek Yogurt', 'GDP-PROD-010', NULL, 1, 519, 649, 519, '2026-09-09 04:04:44', '2026-09-09 04:04:44');

-- --------------------------------------------------------

--
-- Table structure for table `order_refunds`
--

CREATE TABLE `order_refunds` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `support_thread_id` bigint(20) UNSIGNED DEFAULT NULL,
  `created_by` bigint(20) UNSIGNED DEFAULT NULL,
  `amount_cents` int(10) UNSIGNED NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `stripe_refund_id` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `pages`
--

CREATE TABLE `pages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `slug` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `banner_image` varchar(255) DEFAULT NULL,
  `content` longtext DEFAULT NULL,
  `sections` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`sections`)),
  `is_published` tinyint(1) NOT NULL DEFAULT 1,
  `show_in_footer` tinyint(1) NOT NULL DEFAULT 1,
  `footer_group` varchar(255) NOT NULL DEFAULT 'useful_links',
  `sort_order` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `pages`
--

INSERT INTO `pages` (`id`, `slug`, `title`, `banner_image`, `content`, `sections`, `is_published`, `show_in_footer`, `footer_group`, `sort_order`, `created_at`, `updated_at`) VALUES
(1, 'about', 'About Us', NULL, 'Grocerly delivers everyday groceries and household essentials to your door, fast.', '[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/about-hero.jpg\",\"heading\":\"Groceries at your door in minutes\",\"text\":\"Grocerly is a demo storefront for fast local grocery delivery \\u2014 fresh produce, pantry staples and household essentials, picked and delivered from a store near you.\",\"button_label\":\"Start shopping\",\"button_url\":\"#\\/\"},{\"type\":\"stats\",\"heading\":\"Grocerly by the numbers\",\"items\":[{\"title\":\"~10 min\",\"text\":\"Average delivery time\"},{\"title\":\"20+\",\"text\":\"Categories in stock\"},{\"title\":\"4.8 \\/ 5\",\"text\":\"Average order rating\"},{\"title\":\"Every morning\",\"text\":\"Fresh restocks\"}]},{\"type\":\"feature_grid\",\"heading\":\"Why shop with us\",\"items\":[{\"title\":\"10-minute delivery\",\"text\":\"Orders leave the nearest store within minutes of checkout.\"},{\"title\":\"Real prices\",\"text\":\"Everyday low prices with discounts shown clearly \\u2014 no surprises at checkout.\"},{\"title\":\"Fresh every day\",\"text\":\"Produce and dairy are restocked each morning.\"},{\"title\":\"Easy returns\",\"text\":\"Raise an issue from your order history and get a fast refund.\"}]},{\"type\":\"steps\",\"heading\":\"How it works\",\"items\":[{\"title\":\"Fill your basket\",\"text\":\"Browse the aisles and add what you need. Prices and offers are shown upfront.\"},{\"title\":\"Check out in a tap\",\"text\":\"Pay by card or cash on delivery \\u2014 the fee and ETA are confirmed before you pay.\"},{\"title\":\"We pick and pack\",\"text\":\"Your order is assembled at the nearest store within minutes.\"},{\"title\":\"Delivered to your door\",\"text\":\"Track it on the way; hand over cash on arrival if you chose that.\"}]},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/about-story.jpg\",\"image_side\":\"left\",\"heading\":\"Our story\",\"markdown\":\"Grocerly started as a single neighbourhood store and now runs a small network of local hubs.\\n\\nThis whole site is a **demo build** \\u2014 every page here, including this one, is editable in **Admin -> Pages** using drag-and-drop sections.\"},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/about-hero.jpg\",\"image_side\":\"right\",\"heading\":\"From local stores, not a warehouse\",\"markdown\":\"We stock and dispatch from small hubs inside your neighbourhood, so produce travels metres, not miles.\\n\\nShorter journeys mean fresher food, less packaging and a delivery rider who can be at your door before the kettle boils.\"},{\"type\":\"quote\",\"text\":\"I ordered eggs and coriander at 8pm and it was at my door before I had finished chopping the onions. Genuinely faster than walking to the corner shop.\",\"author\":\"Priya M. \\u2014 early tester\"},{\"type\":\"feature_grid\",\"heading\":\"On the roadmap\",\"items\":[{\"title\":\"Scheduled delivery\",\"text\":\"Pick a future time slot, not just \\u201cas soon as possible\\u201d.\"},{\"title\":\"More neighbourhoods\",\"text\":\"New store hubs opening across the city through the year.\"},{\"title\":\"Loyalty perks\",\"text\":\"Rewards and member pricing for regulars, coming soon.\"}]},{\"type\":\"cta\",\"heading\":\"Hungry already?\",\"text\":\"Browse thousands of items and check out in under a minute.\",\"button_label\":\"Shop now\",\"button_url\":\"#\\/\"}]', 1, 1, 'company', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(2, 'blog', 'Blog', NULL, 'Recipes, seasonal picks and a look behind the delivery promise.', '[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"heading\":\"The Grocerly Blog\",\"text\":\"Recipes, seasonal picks and a look behind the 10-minute delivery promise.\"},{\"type\":\"feature_grid\",\"heading\":\"Latest posts\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get groceries to you in 10 minutes\",\"text\":\"A look under the hood of the delivery promise \\u2014 from stocked hubs to planned routes.\",\"link_url\":\"#\\/p\\/blog-10-minute-delivery\"},{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 weeknight dinners in under 20 minutes\",\"text\":\"Five ingredients or fewer, on the table before the news finishes.\",\"link_url\":\"#\\/p\\/blog-weeknight-dinners\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"What\'s in season this month\",\"text\":\"The produce that is cheapest, freshest and best right now \\u2014 and how to use it.\",\"link_url\":\"#\\/p\\/blog-seasonal-produce\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 easy ways to waste less food\",\"text\":\"Small habits that cut your grocery bill and your bin at the same time.\",\"link_url\":\"#\\/p\\/blog-less-food-waste\"}]},{\"type\":\"stats\",\"heading\":\"The blog so far\",\"items\":[{\"title\":\"4\",\"text\":\"Posts published\"},{\"title\":\"~5 min\",\"text\":\"Average read\"},{\"title\":\"Weekly\",\"text\":\"New posts (soon)\"},{\"title\":\"0\",\"text\":\"Sponsored posts\"}]},{\"type\":\"feature_grid\",\"heading\":\"Browse by topic\",\"items\":[{\"title\":\"Recipes\",\"text\":\"Quick, real-food cooking with what is in the aisles this week.\"},{\"title\":\"Seasonal\",\"text\":\"What to buy now and why it tastes better.\"},{\"title\":\"Behind the scenes\",\"text\":\"How the store hubs, picking and routing actually work.\"},{\"title\":\"Sustainability\",\"text\":\"Less waste, less packaging, shorter journeys.\"}]},{\"type\":\"quote\",\"text\":\"Short, useful and no fluff \\u2014 I actually cooked two of the weeknight recipes the same evening I read them.\",\"author\":\"Alex R. \\u2014 newsletter subscriber\"},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"image_side\":\"right\",\"heading\":\"Write for us\",\"markdown\":\"Got a fast recipe, a market tip or a strong opinion about tinned tomatoes? We publish guest posts.\\n\\nEmail **hello@grocerly.example** with a two-line pitch. This is a demo build, so treat these as sample posts you can replace in **Admin -> Pages**.\"},{\"type\":\"rich_text\",\"markdown\":\"**Editorial note** \\u2014 nothing here is sponsored. Product mentions are picked by the writer, and prices and availability shown in posts can change.\"},{\"type\":\"cta\",\"heading\":\"Get new posts by email\",\"text\":\"A subscribe box is coming soon \\u2014 for now, check back weekly for the next one.\"}]', 1, 1, 'company', 2, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(3, 'blog-10-minute-delivery', 'How we get groceries to you in 10 minutes', NULL, 'A look under the hood of the Grocerly delivery promise.', '[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"heading\":\"How we get groceries to you in 10 minutes\",\"text\":\"From stocked neighbourhood hubs to routes built for your street \\u2014 a look under the hood.\"},{\"type\":\"stats\",\"heading\":\"The promise in numbers\",\"items\":[{\"title\":\"under 10 min\",\"text\":\"Typical door-to-door\"},{\"title\":\"3+\",\"text\":\"Pickers on one basket at peak\"},{\"title\":\"Every line\",\"text\":\"Scanned before it leaves\"},{\"title\":\"Live ETA\",\"text\":\"Shown before you pay\"}]},{\"type\":\"rich_text\",\"markdown\":\"### It starts with the store, not a warehouse\\nInstead of one big depot on the edge of town, we run small stocked hubs inside neighbourhoods. When your order lands, the picker is already a few metres from the shelf.\\n\\n### Picking in parallel\\nThe moment you check out, your list is split across the aisles so several people pack it at once. Chilled and frozen items are grabbed last so they stay cold.\\n\\n### Short, planned routes\\nRiders leave with a route that already accounts for one-way streets and building access, so the last hundred metres don\'t eat the time we just saved.\\n\\n### What can slow it down\\nHeavy weather, a very large basket, or an address we can\'t place on the map. You\'ll always see a live ETA before you pay, and it updates if something changes.\"},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/about-story.jpg\",\"image_side\":\"left\",\"heading\":\"Why a hub beats a warehouse\",\"markdown\":\"A warehouse on the ring road is efficient for lorries, not for you.\\n\\nOur hubs carry a tighter range \\u2014 the few thousand things people actually reorder \\u2014 a short walk from where you live. Less range on the shelf, far less distance to your door.\"},{\"type\":\"feature_grid\",\"heading\":\"What we optimise for\",\"items\":[{\"title\":\"Distance\",\"text\":\"Metres from shelf to door, not miles.\"},{\"title\":\"Parallel picking\",\"text\":\"Several people pack one order at once.\"},{\"title\":\"Cold chain\",\"text\":\"Chilled and frozen items are grabbed last.\"},{\"title\":\"Route quality\",\"text\":\"One-way streets and door access, solved before the rider leaves.\"}]},{\"type\":\"steps\",\"heading\":\"The ten minutes, step by step\",\"items\":[{\"title\":\"0:00 \\u2014 Order placed\",\"text\":\"Your list appears on the hub\'s screen and is split by aisle.\"},{\"title\":\"0:30 \\u2014 Picking starts\",\"text\":\"Several pickers work in parallel; chilled items come last.\"},{\"title\":\"3:00 \\u2014 Packed and checked\",\"text\":\"A second person scans every line against your order.\"},{\"title\":\"4:00 \\u2014 Rider dispatched\",\"text\":\"With a route built for your street, not just your postcode.\"},{\"title\":\"~10:00 \\u2014 At your door\",\"text\":\"Hand over cash now if you chose cash on delivery.\"}]},{\"type\":\"quote\",\"text\":\"The rider messaged when he was outside and waited while I found change. Felt like a neighbour dropping something round, not a courier.\",\"author\":\"Dan K. \\u2014 Camberwell\"},{\"type\":\"rich_text\",\"markdown\":\"### A few things people ask\\n**Can I add to an order after checkout?** Not once picking starts \\u2014 but you can place a second order, and if it\'s within a few minutes we try to send them out together.\\n\\n**What if I\'m not in?** The rider calls, then waits a couple of minutes. Undelivered orders come back to the hub and we refund or retry.\\n\\n**Do you deliver everywhere?** Only inside a hub\'s range for now. Enter your address on the home page to check.\"},{\"type\":\"cta\",\"heading\":\"See how fast it lands for you\",\"text\":\"Enter your address and add a few items to get a live ETA.\",\"button_label\":\"Start shopping\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 weeknight dinners in under 20 minutes\",\"text\":\"Five ingredients or fewer, on the table fast.\",\"link_url\":\"#\\/p\\/blog-weeknight-dinners\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"What\'s in season this month\",\"text\":\"Cheaper, fresher, and it tastes better.\",\"link_url\":\"#\\/p\\/blog-seasonal-produce\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 easy ways to waste less food\",\"text\":\"Cut your bill and your bin at once.\",\"link_url\":\"#\\/p\\/blog-less-food-waste\"}]}]', 1, 0, 'blog', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(4, 'blog-weeknight-dinners', '5 weeknight dinners in under 20 minutes', NULL, 'Five ingredients or fewer, on the table before the news finishes.', '[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"heading\":\"5 weeknight dinners in under 20 minutes\",\"text\":\"Five ingredients or fewer, minimal washing up, on the table fast.\"},{\"type\":\"rich_text\",\"markdown\":\"Keep a few basics in and any of these comes together in the time it takes rice to cook.\\n\\n1. **Garlic butter pasta** \\u2014 pasta, butter, garlic, parmesan, black pepper. Reserve a little pasta water to bring it together.\\n2. **Chickpea & spinach curry** \\u2014 tinned chickpeas, curry paste, coconut milk, spinach. Simmer 10 minutes, serve with rice or bread.\\n3. **Egg fried rice** \\u2014 cold cooked rice, eggs, spring onion, soy, frozen peas. High heat, keep it moving.\\n4. **Halloumi & tomato traybake** \\u2014 halloumi, cherry tomatoes, olive oil, oregano. 15 minutes at 220\\u00b0C.\\n5. **Tuna & white bean salad** \\u2014 tinned tuna, cannellini beans, red onion, lemon, olive oil. No cooking at all.\"},{\"type\":\"stats\",\"heading\":\"Why this works on a weeknight\",\"items\":[{\"title\":\"5 or fewer\",\"text\":\"Ingredients per recipe\"},{\"title\":\"~15 min\",\"text\":\"Hands-on time\"},{\"title\":\"1 pan\",\"text\":\"For most of them\"},{\"title\":\"0\",\"text\":\"Special equipment\"}]},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"image_side\":\"right\",\"heading\":\"Swap with the seasons\",\"markdown\":\"Every recipe above takes a swap. Spinach becomes chard or kale. Cherry tomatoes become any tomato, halved. Chickpeas become butter beans.\\n\\nCook whatever is cheap and good that week and the method still works.\"},{\"type\":\"feature_grid\",\"heading\":\"Keep these in the cupboard\",\"items\":[{\"title\":\"Dried pasta & rice\",\"text\":\"The base of three of the five above.\"},{\"title\":\"Tinned beans & tomatoes\",\"text\":\"Instant protein and a sauce in one tin.\"},{\"title\":\"Coconut milk & curry paste\",\"text\":\"A 10-minute curry any night.\"},{\"title\":\"Olive oil, garlic, lemon\",\"text\":\"Turns plain ingredients into a meal.\"}]},{\"type\":\"steps\",\"heading\":\"Get faster every week\",\"items\":[{\"title\":\"Prep in batches\",\"text\":\"Chop onion and garlic for two nights at a time.\"},{\"title\":\"Cook rice ahead\",\"text\":\"Cold rice is better for fried rice anyway.\"},{\"title\":\"Always double it\",\"text\":\"Tomorrow\'s lunch, sorted.\"}]},{\"type\":\"rich_text\",\"markdown\":\"### Make it a meal\\nRound any of these out with a bag of salad, some bread, or a piece of fruit. None of them need a starter.\"},{\"type\":\"quote\",\"text\":\"I stopped ordering takeaway on Tuesdays. The chickpea curry is genuinely faster than opening the app.\",\"author\":\"Meera S.\"},{\"type\":\"cta\",\"heading\":\"Stock the basics\",\"text\":\"Add the cupboard staples to your next order in a couple of taps.\",\"button_label\":\"Shop staples\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get groceries to you in 10 minutes\",\"text\":\"A look under the hood of the delivery promise.\",\"link_url\":\"#\\/p\\/blog-10-minute-delivery\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"What\'s in season this month\",\"text\":\"The produce worth buying right now.\",\"link_url\":\"#\\/p\\/blog-seasonal-produce\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 easy ways to waste less food\",\"text\":\"Small habits, smaller bin.\",\"link_url\":\"#\\/p\\/blog-less-food-waste\"}]}]', 1, 0, 'blog', 2, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(5, 'blog-seasonal-produce', 'What\'s in season this month', NULL, 'The produce that is cheapest, freshest and best right now.', '[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"heading\":\"What\'s in season this month\",\"text\":\"Buy with the seasons: cheaper, fresher, and it simply tastes better.\"},{\"type\":\"rich_text\",\"markdown\":\"Produce that\'s in season hasn\'t travelled far or sat in storage, so it costs less and tastes more like itself.\\n\\n### Vegetables to reach for\\nLeafy greens, carrots, beetroot, cabbage, leeks and squash are all at their best and their cheapest.\\n\\n### Fruit worth buying\\nApples, pears and citrus are crisp and well priced. Berries are better frozen this time of year.\"},{\"type\":\"stats\",\"heading\":\"Why buy in season\",\"items\":[{\"title\":\"Lower\",\"text\":\"Price when supply is high\"},{\"title\":\"Shorter\",\"text\":\"Time from field to shelf\"},{\"title\":\"Better\",\"text\":\"Flavour and texture\"},{\"title\":\"Less\",\"text\":\"Packaging and cold storage\"}]},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"image_side\":\"left\",\"heading\":\"Cook it simply\",\"markdown\":\"In-season produce doesn\'t need much done to it. Roast it, dress it with lemon and oil, or drop it in a soup.\\n\\nThe less you do, the more it tastes of itself.\"},{\"type\":\"feature_grid\",\"heading\":\"A rough month-by-month\",\"items\":[{\"title\":\"Late winter\",\"text\":\"Citrus, leeks, cabbage, stored apples.\"},{\"title\":\"Spring\",\"text\":\"Asparagus, spring greens, new potatoes, rhubarb.\"},{\"title\":\"Summer\",\"text\":\"Tomatoes, courgettes, berries, stone fruit.\"},{\"title\":\"Autumn\",\"text\":\"Squash, mushrooms, pears, root veg.\"}]},{\"type\":\"feature_grid\",\"heading\":\"Three ways to use a glut\",\"items\":[{\"title\":\"Roast a tray\",\"text\":\"Any root veg, olive oil, salt, 30 minutes. Eats hot or cold all week.\"},{\"title\":\"Make a soup base\",\"text\":\"Onion, carrot, celery, stock. Freezes in portions.\"},{\"title\":\"Quick pickle\",\"text\":\"Vinegar, sugar, salt over sliced veg. Ready by dinner.\"}]},{\"type\":\"rich_text\",\"markdown\":\"### What about frozen and tinned\\nFrozen peas, spinach, berries and sweetcorn are picked and frozen at their peak \\u2014 often better than \\\"fresh\\\" that has travelled a week. Tinned tomatoes and beans are pantry gold.\"},{\"type\":\"quote\",\"text\":\"Started shopping the \'in season\' shelf and my veg bill dropped without me trying.\",\"author\":\"Tomasz W.\"},{\"type\":\"cta\",\"heading\":\"Shop fresh produce\",\"text\":\"See what your nearest store has in today.\",\"button_label\":\"Browse produce\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get groceries to you in 10 minutes\",\"text\":\"From stocked hubs to planned routes.\",\"link_url\":\"#\\/p\\/blog-10-minute-delivery\"},{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 weeknight dinners in under 20 minutes\",\"text\":\"Fast, cheap, five ingredients.\",\"link_url\":\"#\\/p\\/blog-weeknight-dinners\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 easy ways to waste less food\",\"text\":\"Buy less, bin less.\",\"link_url\":\"#\\/p\\/blog-less-food-waste\"}]}]', 1, 0, 'blog', 3, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(6, 'blog-less-food-waste', '7 easy ways to waste less food', NULL, 'Small habits that cut your grocery bill and your bin at the same time.', '[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"heading\":\"7 easy ways to waste less food\",\"text\":\"Small habits that cut your grocery bill and your bin at the same time.\"},{\"type\":\"rich_text\",\"markdown\":\"1. **Shop your fridge first.** Plan two meals around what\'s already there before you order.\\n2. **Order little and often.** Fast delivery means you don\'t need to over-buy fresh food.\\n3. **Learn the labels.** \\\"Best before\\\" is about quality; \\\"use by\\\" is about safety.\\n4. **Store it right.** Herbs in water, potatoes in the dark, bread in the freezer.\\n5. **Cook once, eat twice.** Make a bit extra and label it for later.\\n6. **Keep a \\\"use me first\\\" shelf.** One spot in the fridge for things on the edge.\\n7. **Freeze the odds and ends.** Overripe fruit for smoothies, veg scraps for stock.\"},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"image_side\":\"right\",\"heading\":\"The \'use me first\' shelf\",\"markdown\":\"Pick one shelf in the fridge \\u2014 eye level is best \\u2014 for anything close to the edge.\\n\\nEveryone in the house checks it before opening a new pack. It\'s the single habit that moves the needle most.\"},{\"type\":\"steps\",\"heading\":\"A two-minute weekly reset\",\"items\":[{\"title\":\"Look\",\"text\":\"Scan the fridge and note what needs using.\"},{\"title\":\"Plan\",\"text\":\"Pin two meals to those items.\"},{\"title\":\"Top up\",\"text\":\"Order only the gaps.\"}]},{\"type\":\"stats\",\"heading\":\"What waste actually costs\",\"items\":[{\"title\":\"~1 in 5\",\"text\":\"Bags of shopping binned, on average\"},{\"title\":\"Fresh food\",\"text\":\"The category wasted most\"},{\"title\":\"A month\",\"text\":\"How often a full reset helps\"},{\"title\":\"Planning\",\"text\":\"The thing that fixes it\"}]},{\"type\":\"feature_grid\",\"heading\":\"Store it so it lasts\",\"items\":[{\"title\":\"Herbs\",\"text\":\"Stems in a glass of water, a loose bag over the top.\"},{\"title\":\"Bread\",\"text\":\"Freeze half the loaf the day you get it.\"},{\"title\":\"Potatoes & onions\",\"text\":\"Cool, dark, and not right next to each other.\"},{\"title\":\"Leafy greens\",\"text\":\"Wrapped in a dry cloth, not left soaking.\"}]},{\"type\":\"rich_text\",\"markdown\":\"### Cook the scraps\\nVegetable ends and herb stalks go in a stock bag in the freezer. Overripe bananas get peeled and frozen for smoothies or bread. Stale bread becomes croutons or breadcrumbs.\"},{\"type\":\"quote\",\"text\":\"Ordering smaller amounts more often was the fix. I don\'t buy a week of salad and watch half of it wilt any more.\",\"author\":\"Priya M.\"},{\"type\":\"cta\",\"heading\":\"Plan this week\",\"text\":\"Build a short list around what you already have.\",\"button_label\":\"Start a list\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get groceries to you in 10 minutes\",\"text\":\"Why fast delivery means buying less.\",\"link_url\":\"#\\/p\\/blog-10-minute-delivery\"},{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 weeknight dinners in under 20 minutes\",\"text\":\"Use what you have, fast.\",\"link_url\":\"#\\/p\\/blog-weeknight-dinners\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"What\'s in season this month\",\"text\":\"Buy well, waste less.\",\"link_url\":\"#\\/p\\/blog-seasonal-produce\"}]}]', 1, 0, 'blog', 4, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(7, 'contact', 'Contact us', '/img/pages/contact-banner.jpg', '**For any query about an order, your account or the service, use the addresses and contact details below. For the fastest help with a specific order, open it in your account and tap \"Get help\" so it reaches the team with the order already attached.**\n\n## Registered office\n\nGrocerly Retail Private Limited\n\n4th Floor, Market House, 12 Commerce Road\n\nCityville, State 100001, India\n\n## Corporate office\n\nGrocerly Retail Private Limited\n\nTower B, Riverside Business Park, 88 Harbour Avenue\n\nMetro City, State 400001, India\n\n## Contact details\n\n**Customer support:** support@grocerly.example — replies within a few hours, every day 8am to 10pm.\n\n**Phone:** +91 00000 00000 — for urgent delivery issues only.\n\n**Press and partnerships:** hello@grocerly.example\n\n## Grievance Officer\n\nIn line with the Consumer Protection (E-Commerce) Rules, 2020, complaints can be sent to our Grievance Officer.\n\n**Name:** Grievance Officer, Grocerly Retail Private Limited\n\n**Email:** grievance@grocerly.example\n\n**Address:** 4th Floor, Market House, 12 Commerce Road, Cityville, State 100001, India\n\nWe acknowledge every complaint within 48 hours and aim to resolve it within one month of receipt.\n\n## Company details\n\n**Legal entity:** Grocerly Retail Private Limited\n\n**CIN:** U00000XX2020PTC000000\n\n**GSTIN:** 00AAAAA0000A0Z0\n\n**Registered address:** 4th Floor, Market House, 12 Commerce Road, Cityville, State 100001, India\n\n---\n\n*This is placeholder contact information for a demo store. Replace the entity name, addresses, identifiers and officer details in Admin -> Pages before going live.*', '[]', 1, 1, 'company', 3, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(8, 'faqs', 'FAQs', NULL, 'Quick answers about delivery, payments and returns.', '[{\"type\":\"hero\",\"heading\":\"Frequently asked questions\",\"text\":\"Answers about delivery, payments, refunds and your account. Tap a question to see the full answer.\"},{\"type\":\"faq\",\"heading\":\"Orders & delivery\",\"items\":[{\"title\":\"How long does delivery take?\",\"text\":\"Most orders arrive within the time window shown at checkout \\u2014 often around 10 minutes. Weather, a large basket or building access can add a little time, and your live ETA updates if anything changes.\"},{\"title\":\"Do you deliver to my area?\",\"text\":\"Enter your address on the home page. If we deliver there you can start shopping straight away; if not, we\'ll say so and note your interest for when we expand.\"},{\"title\":\"Is there a minimum order?\",\"text\":\"There is no strict minimum, but a very small basket may carry a small-cart fee, which is always shown before you pay. Larger orders often qualify for free delivery.\"},{\"title\":\"Can I add items after placing an order?\",\"text\":\"Not once picking has started. You can place a second order, and if it is within a few minutes we will try to send both together.\"},{\"title\":\"What if I am not home when the rider arrives?\",\"text\":\"The rider calls and waits a couple of minutes. If delivery cannot be completed, the order returns to the store and we refund it or arrange a retry.\"}]},{\"type\":\"faq\",\"heading\":\"Payments\",\"items\":[{\"title\":\"How can I pay?\",\"text\":\"By card through our payment provider, or by cash on delivery where that option is shown at checkout.\"},{\"title\":\"Is it safe to save my card?\",\"text\":\"Card details are handled by our PCI-compliant payment provider and are never stored on Grocerly servers. We keep only a reference and the payment status.\"},{\"title\":\"When am I charged?\",\"text\":\"For card orders, at checkout. For cash on delivery, you pay the rider the full amount on hand-over.\"},{\"title\":\"My payment failed but money was deducted \\u2014 what now?\",\"text\":\"A failed-payment hold is usually released by your bank within a few working days. If no order was created, no purchase was made. Contact support with the order time if it does not clear.\"}]},{\"type\":\"faq\",\"heading\":\"Refunds & returns\",\"items\":[{\"title\":\"How do I report a missing or wrong item?\",\"text\":\"Open the order in your account and tap **Get help**. Tell us which items were affected; we review and, where appropriate, refund or replace them.\"},{\"title\":\"How long do refunds take?\",\"text\":\"Approved refunds go to your original payment method. Card refunds can take several working days to appear, depending on your bank. Cash-on-delivery refunds are made by a method we agree with you.\"},{\"title\":\"Can I return groceries I\'ve changed my mind about?\",\"text\":\"Perishable items generally cannot be returned once delivered. For unopened non-perishable items, contact support within a reasonable time.\"},{\"title\":\"Can I cancel an order?\",\"text\":\"Yes, until it leaves the store. After that, cancellation may not be possible \\u2014 contact support and we will help where we can.\"}]},{\"type\":\"faq\",\"heading\":\"Your account\",\"items\":[{\"title\":\"How do I sign in?\",\"text\":\"Use the email-code option, or set a password and sign in with your email and password. Staff accounts sign in on a separate admin page.\"},{\"title\":\"How do I change my address or phone number?\",\"text\":\"Edit them in your account. The details on an order that is already placed are frozen at the time you placed it.\"},{\"title\":\"How do I delete my account?\",\"text\":\"Contact support or email privacy@grocerly.example. The Privacy Policy explains what happens to your data.\"},{\"title\":\"I am not getting order updates.\",\"text\":\"Check the email address on your account and your spam folder. You can always see live status on the order in your account.\"}]},{\"type\":\"cta\",\"heading\":\"Still need help?\",\"text\":\"Open the order in your account and tap \\u201cGet help\\u201d \\u2014 it reaches support with the order already attached.\"}]', 1, 1, 'help', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(9, 'privacy', 'Privacy Policy', NULL, 'Grocerly Retail Private Limited (**\"Grocerly\"**, **\"we\"**, **\"us\"** or **\"our\"**) is committed to protecting your privacy. This Privacy Policy explains what information we collect when you use the Grocerly website and app (the **\"Platform\"**), how we use it, who we share it with, and the choices you have.\n\nBy using the Platform you agree to the practices described in this Policy. If you do not agree, please do not use the Platform.\n\n**Effective date:** this is a demo document — set a real date before going live.\n\n## 1. Information we collect\n\n### 1.1 Information you give us\n\n- **Account information** — your name, email address and phone number when you register or place an order.\n- **Delivery information** — the addresses you save, delivery instructions, and the contact number for a given order.\n- **Order information** — the items you buy, order value, and any issues or refunds you raise.\n- **Communications** — messages you send us through support chat or email.\n\n### 1.2 Information we collect automatically\n\n- **Device and usage data** — device type, browser, operating system, IP address, pages viewed and actions taken on the Platform.\n- **Approximate location** — derived from your address or, with your permission, your device, to check whether we deliver to you and to estimate delivery times.\n- **Cookies and similar technologies** — see Section 4.\n\n### 1.3 Information from third parties\n\n- **Payment status** from our payment processor. We never receive your full card number.\n- **Fraud and risk signals** from providers that help us keep accounts secure.\n\nWe do **not** knowingly collect sensitive personal data, and we ask that you do not send it to us.\n\n## 2. How we use your information\n\nWe use your information to:\n\n- create and manage your account;\n- process, pack and deliver your orders, and handle returns and refunds;\n- share the details a delivery rider needs — your name, address and phone — so your order can reach you;\n- provide customer support and respond to your queries;\n- detect, prevent and investigate fraud, abuse and security incidents;\n- improve the Platform, our range and our delivery operations;\n- send you service messages such as order updates and security notices; and\n- send you offers and updates **only if you have opted in**, which you can stop at any time.\n\n## 3. Payment information\n\nCard payments are processed by our third-party payment processor. Your card details are entered on their secure systems and are **not stored on Grocerly servers**. We retain only a payment reference and the status of the transaction.\n\n## 4. Cookies and similar technologies\n\nWe use:\n\n- **Essential cookies and local storage** to keep you signed in and remember your cart and chosen location. The Platform does not work properly without these.\n- **Analytics** to understand which features are used so we can improve them.\n\nYou can clear or block cookies in your browser settings; some parts of the Platform may then stop working.\n\n## 5. How we share information\n\nWe share information only as described here:\n\n- **Delivery partners** — the name, address, phone number and order contents needed to deliver your order.\n- **Service providers** — payment processing, hosting, communications, mapping and analytics providers who process data on our instructions.\n- **Legal and safety** — where required by law, court order or a government request, or to protect the rights, property or safety of Grocerly, our customers or the public.\n- **Business transfers** — if Grocerly is involved in a merger, acquisition or sale of assets, your information may be transferred, subject to this Policy.\n\nWe do **not** sell your personal information.\n\n## 6. Data retention\n\nWe keep your information for as long as your account is active and for a reasonable period afterwards to meet legal, tax, accounting and dispute-resolution requirements. When it is no longer needed we delete or anonymise it.\n\n## 7. Your rights and choices\n\nDepending on where you live, you may have the right to:\n\n- **access** the personal information we hold about you;\n- **correct** information that is inaccurate — you can edit your profile and addresses in your account;\n- **delete** your account and associated personal information;\n- **object to or restrict** certain processing; and\n- **withdraw consent** for marketing at any time.\n\nTo exercise any of these, contact us using the details in Section 12. We may need to verify your identity before acting on a request.\n\n## 8. Security\n\nWe use technical and organisational measures to protect your information, including encryption in transit (HTTPS / TLS), access controls that limit staff and rider access to what they need, and revocable sign-in tokens. No method of transmission or storage is completely secure, so we cannot guarantee absolute security.\n\n## 9. Children\n\nThe Platform is not directed at children below the age required to form a binding contract where they live, and we do not knowingly collect their personal information. If you believe a child has provided us information, contact us and we will delete it.\n\n## 10. Third-party links\n\nThe Platform may link to third-party sites and services. We are not responsible for their privacy practices; please read their policies.\n\n## 11. International transfers\n\nYour information may be processed in countries other than the one you live in. Where we transfer information across borders, we use appropriate safeguards as required by applicable law.\n\n## 12. Grievance Officer and contact\n\nFor questions about this Policy or to exercise your rights, contact:\n\nGrievance Officer, Grocerly Retail Private Limited\n\nEmail: privacy@grocerly.example\n\nAddress: 4th Floor, Market House, 12 Commerce Road, Cityville, State 100001, India\n\nIn line with the Consumer Protection (E-Commerce) Rules, 2020, we acknowledge complaints within 48 hours and aim to resolve them within one month of receipt.\n\n## 13. Changes to this Policy\n\nWe may update this Policy from time to time. If we make material changes we will post the updated Policy on the Platform and, where appropriate, notify you. The **Effective date** above shows when it last changed.\n\n---\n\n*This is placeholder text for a demo store. Replace it with a privacy policy prepared and reviewed by your legal team, and set a real effective date, entity details and contact information in Admin -> Pages.*', '[]', 1, 1, 'legal', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(10, 'terms', 'Terms of Service', NULL, 'These Terms of Service (**\"Terms\"**) govern your use of the Grocerly website and app (the **\"Platform\"**), operated by Grocerly Retail Private Limited (**\"Grocerly\"**, **\"we\"**, **\"us\"** or **\"our\"**). By creating an account, placing an order or otherwise using the Platform, you agree to these Terms and to our Privacy Policy. If you do not agree, do not use the Platform.\n\n**Effective date:** this is a demo document — set a real date before going live.\n\n## 1. Eligibility and your account\n\n- You must be old enough to form a legally binding contract where you live, and not barred from receiving our services under applicable law.\n- You must provide accurate, current and complete account and delivery information, and keep it up to date.\n- You are responsible for activity that happens under your account and for keeping your sign-in credentials secure. Tell us promptly if you suspect unauthorised use.\n- We may refuse, suspend or close an account for a breach of these Terms, suspected fraud or abuse, or where required by law.\n\n## 2. The service\n\nThe Platform lets you order groceries and household items from a nearby store for delivery. Product range, images, pricing and delivery areas vary by location and change over time. Nothing on the Platform is an offer; your order is an offer to buy, which we accept when we confirm it.\n\n## 3. Orders, pricing and availability\n\n- Prices, taxes, delivery fees and any other charges are shown before you confirm an order. Totals are calculated and confirmed by our servers at checkout.\n- Product weights and pack sizes are approximate. Substitutions are only made with your agreement.\n- If an item is unavailable, mispriced or ordered in quantities we consider abnormal, we may cancel all or part of the order and refund the affected amount.\n- Promotional prices and offers are subject to their own terms and may be withdrawn at any time.\n\n## 4. Payment\n\n- You can pay by card through our third-party payment processor, or by cash on delivery where that option is shown.\n- Card details are entered on the payment processor\'s systems and are **not stored on Grocerly servers**.\n- For cash-on-delivery orders, the full amount is due to the delivery rider on hand-over.\n- If a payment fails or is reversed, we may cancel the order or suspend your account until it is resolved.\n\n## 5. Delivery\n\n- We deliver only to addresses within a serviceable area. Enter your address on the Platform to check.\n- Delivery time estimates are indicative and may be affected by weather, traffic, demand or access to your building.\n- Someone must be available to receive the order at the address. If delivery cannot be completed after reasonable attempts, the order may be returned and a cancellation fee or a partial refund may apply.\n- Risk in the goods passes to you on delivery.\n\n## 6. Cancellations and refunds\n\n- You may cancel an order until it leaves the store. After that, cancellation may not be possible.\n- Approved refunds are made to your original payment method. Card refunds may take several business days to appear, depending on your bank.\n- For missing, damaged or incorrect items, raise an issue from your order history within a reasonable time so we can review and, where appropriate, refund or replace.\n\n## 7. Acceptable use\n\nYou agree not to:\n\n- use the Platform for any unlawful, fraudulent or harmful purpose;\n- interfere with or disrupt the Platform, its servers or networks, or attempt to gain unauthorised access;\n- scrape, copy or harvest data from the Platform except as expressly permitted;\n- resell products bought through the Platform, or place orders you do not intend to pay for or receive;\n- abuse promotions, referral schemes or the refund process; or\n- upload or transmit anything unlawful, defamatory, infringing or malicious.\n\n## 8. Intellectual property\n\nThe Platform, including its content, design, logos and software, is owned by Grocerly or its licensors and is protected by intellectual-property laws. We grant you a limited, non-exclusive, non-transferable, revocable licence to use the Platform for its intended purpose. All other rights are reserved.\n\n## 9. User content\n\nIf you submit content — such as support messages, feedback or ratings — you grant us a non-exclusive, worldwide, royalty-free licence to use it to operate and improve the service. You are responsible for the content you submit and confirm you have the right to submit it.\n\n## 10. Third-party services\n\nThe Platform relies on and may link to third-party services (for example payments, mapping and messaging). Their terms and policies apply to your use of those services, and we are not responsible for them.\n\n## 11. Disclaimers\n\nThe Platform and all products and services are provided on an **\"as is\"** and **\"as available\"** basis. To the fullest extent permitted by law, we disclaim all warranties, express or implied, including merchantability, fitness for a particular purpose and non-infringement. We do not warrant that the Platform will be uninterrupted, error-free or secure.\n\n## 12. Limitation of liability\n\nTo the fullest extent permitted by law, Grocerly and its officers, employees and partners will not be liable for any indirect, incidental, special, consequential or punitive damages, or for loss of profits, data or goodwill, arising from your use of the Platform. Our total liability for any claim relating to an order will not exceed the amount you paid for that order.\n\n## 13. Indemnity\n\nYou agree to indemnify and hold Grocerly harmless from claims, losses and expenses (including reasonable legal fees) arising from your breach of these Terms or your misuse of the Platform.\n\n## 14. Suspension and termination\n\nWe may suspend or terminate your access to the Platform at any time for a breach of these Terms, suspected fraud or abuse, or where required by law. You may stop using the Platform and close your account at any time. Sections that by their nature should survive termination will do so.\n\n## 15. Changes to these Terms\n\nWe may update these Terms from time to time. Material changes will be posted on the Platform and, where appropriate, notified to you. Continued use of the Platform after changes take effect means you accept the updated Terms.\n\n## 16. Governing law and disputes\n\nThese Terms are governed by the laws of India, without regard to conflict-of-law rules. Subject to any mandatory consumer-protection rights you have where you live, the courts at Metro City, India will have jurisdiction over disputes arising from these Terms.\n\n## 17. Grievance Officer and contact\n\nFor complaints or questions about these Terms, contact:\n\nGrievance Officer, Grocerly Retail Private Limited\n\nEmail: grievance@grocerly.example\n\nAddress: 4th Floor, Market House, 12 Commerce Road, Cityville, State 100001, India\n\nIn line with the Consumer Protection (E-Commerce) Rules, 2020, we acknowledge complaints within 48 hours and aim to resolve them within one month of receipt.\n\n## 18. General\n\n- **Entire agreement** — these Terms and the Privacy Policy are the entire agreement between you and Grocerly regarding the Platform.\n- **Severability** — if any provision is held unenforceable, the rest remains in effect.\n- **No waiver** — our failure to enforce a provision is not a waiver of it.\n- **Assignment** — you may not assign these Terms; we may assign them in connection with a merger, acquisition or sale of assets.\n- **Force majeure** — we are not liable for delays or failures caused by events beyond our reasonable control.\n\n---\n\n*This is placeholder text for a demo store. Replace it with terms of service prepared and reviewed by your legal team, and set a real effective date, entity details, governing law and contact information in Admin -> Pages.*', '[]', 1, 1, 'legal', 2, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(11, 'security', 'Security', '/img/pages/security-banner.jpg', 'Grocerly Retail Private Limited (**\"Grocerly\"**) takes the security of our customers and their data seriously. We value the work of security researchers and welcome reports of vulnerabilities in our website, app and infrastructure.\n\nThis page sets out how to report a security issue to us and what you can expect in return.\n\n**Effective date:** this is a demo document — set a real date before going live.\n\n## Our commitment\n\nIf you make a good-faith effort to comply with this policy during your research, we will:\n\n- work with you to understand and validate your report;\n- keep you informed of our progress towards a fix;\n- not pursue or support legal action against you for accidental, good-faith violations of this policy; and\n- credit you, with your permission, once the issue is resolved.\n\nActivities carried out in a manner consistent with this policy will be considered authorised conduct, and we will not treat them as a breach of our Terms of Service.\n\n## Guidelines\n\nPlease:\n\n- only test against accounts and data that you own or have explicit permission to use;\n- stop testing and report immediately if you encounter customer data, and do not access, modify, save, transfer or disclose it;\n- give us a reasonable time to investigate and fix an issue before disclosing it publicly, and coordinate any disclosure with us;\n- provide enough detail for us to reproduce the issue; and\n- make every effort to avoid privacy violations, data loss and service disruption.\n\nPlease do **not**:\n\n- run automated scanners against production, or any test that degrades or disrupts our services (including denial-of-service, brute force at volume, or spam);\n- use social engineering, phishing, or physical attempts against our staff, riders, offices or infrastructure;\n- attempt to access, download or exfiltrate data that is not yours;\n- publicly disclose a vulnerability before we have confirmed it is fixed; or\n- demand payment as a condition of disclosure.\n\n## In scope\n\n- Our customer website and web app\n- Our customer mobile apps\n- APIs that serve the above\n\n## Out of scope\n\nThe following generally do **not** qualify on their own, unless you can show a concrete, exploitable security impact:\n\n- Missing security headers, cookie flags, or best-practice hardening with no demonstrated exploit\n- Self-XSS, or issues requiring a fully compromised device or browser\n- Clickjacking on pages with no sensitive state-changing actions\n- Rate-limiting or brute-force concerns on non-authentication endpoints\n- Reports from automated tools without a working proof of concept\n- SPF / DKIM / DMARC configuration, or email spoofing of non-existent addresses\n- Outdated library versions with no proven vulnerability in our usage\n- Denial-of-service, resource-exhaustion, or volumetric findings\n- Social engineering, or physical security of our premises\n\n## How to report\n\nEmail **security@grocerly.example** with:\n\n1. a clear description of the vulnerability and the affected URL, endpoint or app screen;\n2. step-by-step instructions to reproduce it;\n3. a proof of concept (script, request, screenshots or a short video); and\n4. your assessment of the impact and any suggested remediation.\n\nOne issue per report, please. If you need to share sensitive details, ask us for a secure channel.\n\n## What happens next\n\n- **Acknowledgement** — we aim to confirm receipt within 3 working days.\n- **Triage** — we validate the report and assign a severity, and will ask for more detail if needed.\n- **Fix** — remediation time depends on severity and complexity; we will keep you updated.\n- **Closure** — we let you know when the issue is resolved and confirm any credit.\n\n## Recognition\n\nWith your consent, we are happy to acknowledge researchers who report valid, previously unknown issues. Grocerly does not currently run a paid bug-bounty programme; any reward is at our discretion.\n\n## Contact\n\nSecurity reports: **security@grocerly.example**\n\nFor anything else, see the [Contact](/#/p/contact) page.\n\n---\n\n*This is placeholder text for a demo store. Replace it with a responsible-disclosure policy reviewed by your security and legal teams, and set real scope, contact details and an effective date in Admin -> Pages.*', '[]', 1, 1, 'legal', 3, '2026-09-09 01:12:49', '2026-09-09 01:12:49');

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(3, 'App\\Models\\User', 15, 'perf', '1742ce0507afa61a40d31fd5fca454a93b1c4397af0d3e042dce47d9a8f7844e', '[\"*\"]', '2026-09-09 01:17:35', NULL, '2026-09-09 01:17:32', '2026-09-09 01:17:35'),
(7, 'App\\Models\\User', 17, 'customer', '456796337ac1d836c1154146175b25528d58aa7869bfca580ba29b1ab373a31f', '[\"*\"]', '2026-09-09 02:28:52', NULL, '2026-09-09 02:25:33', '2026-09-09 02:28:52'),
(10, 'App\\Models\\User', 16, 'customer', '8fdc9fbafcf3cc942fa134edea164a87468fca875fef8adbfae8365b4d8b5978', '[\"*\"]', '2026-09-09 02:32:40', NULL, '2026-09-09 02:30:45', '2026-09-09 02:32:40'),
(13, 'App\\Models\\User', 16, 'customer', '523f28e36ce4c3be8307320ea60a0c0841c1fc7e81651b87ec1e01981c665d10', '[\"*\"]', '2026-09-09 02:39:14', NULL, '2026-09-09 02:34:07', '2026-09-09 02:39:14'),
(22, 'App\\Models\\User', 15, 'customer', '627484f294e8d64c723d024582e22b0da0c6171aa824c074bc73176d11e3e62e', '[\"*\"]', '2026-09-09 04:52:26', NULL, '2026-09-09 04:38:35', '2026-09-09 04:52:26'),
(23, 'App\\Models\\User', 16, 'customer', '08d1476873ee76edd238f947b8a6bdbd95cb51de55064f6b7d3c3bc320b861f5', '[\"*\"]', '2026-09-09 04:49:30', NULL, '2026-09-09 04:49:14', '2026-09-09 04:49:30'),
(24, 'App\\Models\\User', 17, 'customer', '6e1418b75405dd71aa8656e2f5be0a721a725fe04e35b439acb002c868e89d16', '[\"*\"]', NULL, NULL, '2026-09-09 04:49:42', '2026-09-09 04:49:42'),
(26, 'App\\Models\\User', 16, 'customer', 'c3b22b30312f4efc2bb46da67896d60c0d98db74594c81755f414c6ad747ac4a', '[\"*\"]', '2026-09-09 04:50:17', NULL, '2026-09-09 04:50:11', '2026-09-09 04:50:17'),
(30, 'App\\Models\\User', 16, 'customer', 'eb7d0f829f0baef7af1b3bce1329714c8ee8a291d5505cd0beb45b5c0ffd7832', '[\"*\"]', '2026-09-09 05:00:53', NULL, '2026-09-09 05:00:19', '2026-09-09 05:00:53'),
(31, 'App\\Models\\User', 17, 'customer', '89f81e8cded777c546d7c26df2bc9dbfc01377b9cd6cf375ee8b5bae8706f96e', '[\"*\"]', NULL, NULL, '2026-09-09 05:01:05', '2026-09-09 05:01:05'),
(33, 'App\\Models\\User', 16, 'customer', 'b764b4d49406f5204ebe19b541f51eb693911e74fc35417979818a55fd025eb6', '[\"*\"]', '2026-09-09 05:02:15', NULL, '2026-09-09 05:01:27', '2026-09-09 05:02:15'),
(34, 'App\\Models\\User', 17, 'customer', 'a85cabe67ba928751616ade687760bd7ab810ded65534a0187eba48c74805962', '[\"*\"]', NULL, NULL, '2026-09-09 05:02:22', '2026-09-09 05:02:22'),
(43, 'App\\Models\\User', 16, 'customer', '7ad55327f05f20fe77067321d1627f177278d02d0976f8944b107220872de1d3', '[\"*\"]', '2026-09-09 05:36:35', NULL, '2026-09-09 05:36:30', '2026-09-09 05:36:35'),
(44, 'App\\Models\\User', 16, 'customer', '2ddb9ca2b6232a706c01fbd5889d70ba430949dbe50242e19a0707f8b6738849', '[\"*\"]', '2026-09-09 05:36:49', NULL, '2026-09-09 05:36:47', '2026-09-09 05:36:49'),
(46, 'App\\Models\\User', 15, 'customer', '31ff584f229acde2ea4313df1563f0d2bd31e3d28b232ec562f8db6f09d95933', '[\"*\"]', '2026-09-09 06:01:29', NULL, '2026-09-09 05:48:08', '2026-09-09 06:01:29');

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `sku` varchar(255) NOT NULL,
  `price_cents` int(10) UNSIGNED NOT NULL,
  `compare_at_price_cents` int(10) UNSIGNED DEFAULT NULL,
  `inventory_quantity` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `image_url` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`id`, `category_id`, `name`, `slug`, `description`, `sku`, `price_cents`, `compare_at_price_cents`, `inventory_quantity`, `image_url`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 'Organic Bananas', 'organic-bananas', NULL, 'GDP-PROD-001', 299, NULL, 100, 'https://www.themealdb.com/images/ingredients/Banana-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(2, 1, 'Gala Apples', 'gala-apples', NULL, 'GDP-PROD-002', 449, 561, 100, 'https://www.themealdb.com/images/ingredients/Apples-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(3, 1, 'Baby Spinach', 'baby-spinach', NULL, 'GDP-PROD-007', 349, NULL, 100, 'https://www.themealdb.com/images/ingredients/Spinach-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(4, 1, 'Roma Tomatoes', 'roma-tomatoes', NULL, 'GDP-PROD-008', 279, NULL, 100, 'https://www.themealdb.com/images/ingredients/Tomato-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(5, 1, 'Hass Avocados', 'hass-avocados', NULL, 'GDP-PROD-009', 599, NULL, 100, 'https://www.themealdb.com/images/ingredients/Avocado-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(6, 2, 'Large Brown Eggs', 'large-brown-eggs', NULL, 'GDP-PROD-003', 599, NULL, 100, 'https://www.themealdb.com/images/ingredients/Egg-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(7, 2, 'Whole Milk', 'whole-milk', NULL, 'GDP-PROD-004', 429, NULL, 100, 'https://www.themealdb.com/images/ingredients/Milk-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(8, 2, 'Greek Yogurt', 'greek-yogurt', NULL, 'GDP-PROD-010', 519, 649, 95, 'https://www.themealdb.com/images/ingredients/Yogurt-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 04:04:44'),
(9, 2, 'Sharp Cheddar', 'sharp-cheddar', NULL, 'GDP-PROD-011', 649, NULL, 100, 'https://www.themealdb.com/images/ingredients/Cheddar%20Cheese-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(10, 2, 'Unsalted Butter', 'unsalted-butter', NULL, 'GDP-PROD-012', 399, NULL, 100, 'https://www.themealdb.com/images/ingredients/Butter-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(11, 3, 'Long Grain Rice', 'long-grain-rice', NULL, 'GDP-PROD-005', 699, NULL, 100, 'https://www.themealdb.com/images/ingredients/Rice-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(12, 3, 'Pasta', 'pasta', NULL, 'GDP-PROD-006', 249, NULL, 100, 'https://www.themealdb.com/images/ingredients/Spaghetti-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(13, 3, 'Extra Virgin Olive Oil', 'extra-virgin-olive-oil', NULL, 'GDP-PROD-013', 899, NULL, 100, 'https://www.themealdb.com/images/ingredients/Olive%20Oil-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(14, 3, 'Rolled Oats', 'rolled-oats', NULL, 'GDP-PROD-014', 459, NULL, 100, 'https://www.themealdb.com/images/ingredients/Oats-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(15, 3, 'Peanut Butter', 'peanut-butter', NULL, 'GDP-PROD-015', 549, NULL, 100, 'https://www.themealdb.com/images/ingredients/Peanut%20Butter-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(16, 4, 'Salted Potato Chips', 'salted-potato-chips', NULL, 'GDP-PROD-016', 199, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(17, 4, 'Butter Popcorn', 'butter-popcorn', NULL, 'GDP-PROD-017', 249, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(18, 4, 'Roasted Trail Mix', 'roasted-trail-mix', NULL, 'GDP-PROD-018', 549, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(19, 5, 'Orange Juice', 'orange-juice', NULL, 'GDP-PROD-019', 399, NULL, 100, 'https://www.themealdb.com/images/ingredients/Orange-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(20, 5, 'Sparkling Water', 'sparkling-water', NULL, 'GDP-PROD-020', 149, NULL, 100, 'https://www.themealdb.com/images/ingredients/Water-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(21, 5, 'Cola 6-Pack', 'cola-6-pack', NULL, 'GDP-PROD-021', 499, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(22, 6, 'Sourdough Loaf', 'sourdough-loaf', NULL, 'GDP-PROD-022', 449, NULL, 100, 'https://www.themealdb.com/images/ingredients/Bread-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(23, 6, 'Burger Buns', 'burger-buns', NULL, 'GDP-PROD-023', 279, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(24, 6, 'Butter Croissants', 'butter-croissants', NULL, 'GDP-PROD-024', 399, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(25, 7, 'Corn Flakes', 'corn-flakes', NULL, 'GDP-PROD-025', 429, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(26, 7, 'Honey Granola', 'honey-granola', NULL, 'GDP-PROD-026', 549, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(27, 7, 'Pancake Mix', 'pancake-mix', NULL, 'GDP-PROD-027', 389, NULL, 100, 'https://www.themealdb.com/images/ingredients/Flour-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(28, 8, 'Dark Chocolate Bar', 'dark-chocolate-bar', NULL, 'GDP-PROD-028', 299, 374, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(29, 8, 'Choc Chip Cookies', 'choc-chip-cookies', NULL, 'GDP-PROD-029', 349, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(30, 8, 'Gummy Bears', 'gummy-bears', NULL, 'GDP-PROD-030', 199, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(31, 9, 'Chicken Breast', 'chicken-breast', NULL, 'GDP-PROD-031', 899, NULL, 100, 'https://www.themealdb.com/images/ingredients/Chicken-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(32, 9, 'Salmon Fillet', 'salmon-fillet', NULL, 'GDP-PROD-032', 1299, NULL, 100, 'https://www.themealdb.com/images/ingredients/Salmon-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(33, 9, 'Pork Sausages', 'pork-sausages', NULL, 'GDP-PROD-033', 649, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(34, 10, 'Frozen Peas', 'frozen-peas', NULL, 'GDP-PROD-034', 249, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(35, 10, 'Vanilla Ice Cream', 'vanilla-ice-cream', NULL, 'GDP-PROD-035', 549, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(36, 10, 'Crispy Fries', 'crispy-fries', NULL, 'GDP-PROD-036', 399, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(37, 11, 'Ground Coffee', 'ground-coffee', NULL, 'GDP-PROD-037', 899, NULL, 100, 'https://www.themealdb.com/images/ingredients/Coffee-Medium.png', 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(38, 11, 'Green Tea Bags', 'green-tea-bags', NULL, 'GDP-PROD-038', 449, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(39, 11, 'Masala Chai', 'masala-chai', NULL, 'GDP-PROD-039', 399, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(40, 12, 'Tomato Ketchup', 'tomato-ketchup', NULL, 'GDP-PROD-040', 249, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(41, 12, 'Mayonnaise', 'mayonnaise', NULL, 'GDP-PROD-041', 329, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(42, 12, 'Strawberry Jam', 'strawberry-jam', NULL, 'GDP-PROD-042', 299, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(43, 13, 'Dish Soap', 'dish-soap', NULL, 'GDP-PROD-043', 279, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(44, 13, 'Laundry Detergent', 'laundry-detergent', NULL, 'GDP-PROD-044', 899, 1124, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(45, 13, 'Surface Cleaner', 'surface-cleaner', NULL, 'GDP-PROD-045', 349, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(46, 14, 'Shampoo', 'shampoo', NULL, 'GDP-PROD-046', 549, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(47, 14, 'Toothpaste', 'toothpaste', NULL, 'GDP-PROD-047', 199, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(48, 14, 'Hand Soap', 'hand-soap', NULL, 'GDP-PROD-048', 249, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(49, 15, 'Diapers Value Pack', 'diapers-value-pack', NULL, 'GDP-PROD-049', 1499, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(50, 15, 'Baby Wipes', 'baby-wipes', NULL, 'GDP-PROD-050', 299, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(51, 15, 'Baby Lotion', 'baby-lotion', NULL, 'GDP-PROD-051', 449, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(52, 16, 'Paper Towels', 'paper-towels', NULL, 'GDP-PROD-052', 399, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(53, 16, 'Trash Bags', 'trash-bags', NULL, 'GDP-PROD-053', 349, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(54, 16, 'Aluminium Foil', 'aluminium-foil', NULL, 'GDP-PROD-054', 299, NULL, 100, NULL, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49');

-- --------------------------------------------------------

--
-- Table structure for table `product_variants`
--

CREATE TABLE `product_variants` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `label` varchar(255) NOT NULL,
  `sku` varchar(255) NOT NULL,
  `price_cents` int(10) UNSIGNED NOT NULL,
  `compare_at_price_cents` int(10) UNSIGNED DEFAULT NULL,
  `inventory_quantity` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `image_url` varchar(255) DEFAULT NULL,
  `sort_order` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `product_variants`
--

INSERT INTO `product_variants` (`id`, `product_id`, `label`, `sku`, `price_cents`, `compare_at_price_cents`, `inventory_quantity`, `image_url`, `sort_order`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 7, '500 ml', 'GDP-PROD-004-500', 249, NULL, 80, NULL, 1, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(2, 7, '1 L', 'GDP-PROD-004-1000', 429, NULL, 60, NULL, 2, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(3, 7, '2 L', 'GDP-PROD-004-2000', 799, NULL, 30, NULL, 3, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(4, 11, '1 kg', 'GDP-PROD-005-1KG', 699, NULL, 50, NULL, 1, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49'),
(5, 11, '5 kg', 'GDP-PROD-005-5KG', 3199, NULL, 15, NULL, 2, 1, '2026-09-09 01:12:49', '2026-09-09 01:12:49');

-- --------------------------------------------------------

--
-- Table structure for table `rider_reviews`
--

CREATE TABLE `rider_reviews` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `rider_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `rating` tinyint(3) UNSIGNED NOT NULL,
  `comment` text DEFAULT NULL,
  `source` varchar(16) NOT NULL DEFAULT 'delivery',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rider_reviews`
--

INSERT INTO `rider_reviews` (`id`, `order_id`, `rider_id`, `user_id`, `rating`, `comment`, `source`, `created_at`, `updated_at`) VALUES
(1, 3, 16, 17, 5, NULL, 'chat', '2026-09-09 05:42:37', '2026-09-09 05:42:37');

-- --------------------------------------------------------

--
-- Table structure for table `rider_store`
--

CREATE TABLE `rider_store` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `store_id` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `sessions`
--

INSERT INTO `sessions` (`id`, `user_id`, `ip_address`, `user_agent`, `payload`, `last_activity`) VALUES
('UTbg5UPwPiWkoC54ywTxGtgu03viEwtrup5vfuf8', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36 Edg/152.0.0.0', 'eyJfdG9rZW4iOiJjM0RBT05GUWNJb1FPTWl3WElPTTJsY0hCbTh0TUtHZUR0dU54WllzIiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cL2xvY2FsaG9zdDo4MDAwIiwicm91dGUiOm51bGx9LCJfZmxhc2giOnsib2xkIjpbXSwibmV3IjpbXX19', 1788953496),
('VbUeTGNJe0w12iJenDsJSM2ByZjaYiW3lC3tldpR', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36 Edg/152.0.0.0', 'eyJfdG9rZW4iOiJpZFl1WTh3Y09tUUQ4SlhJZVNYaGhHRURIamVodU1oSGFjTm1wY3h5IiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cL2xvY2FsaG9zdDo4MDAwIiwicm91dGUiOm51bGx9LCJfZmxhc2giOnsib2xkIjpbXSwibmV3IjpbXX19', 1788940289);

-- --------------------------------------------------------

--
-- Table structure for table `settings`
--

CREATE TABLE `settings` (
  `key` varchar(255) NOT NULL,
  `value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`value`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `settings`
--

INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('branding', '{\"v\":{\"store_name\":\"Grocerly\",\"tagline\":\"Fresh groceries, less fuss\",\"logo_url\":null,\"favicon_url\":\"http:\\/\\/127.0.0.1:8000\\/storage\\/products\\/IylK58VcMqgCgj81gvBdM7HMnHi9XTQAiM9oKlEP.jpg\",\"theme\":\"light\",\"layout_width\":\"boxed\",\"color_brand\":\"#1f7a3d\",\"color_accent\":\"#ffd23f\",\"color_heading\":\"#18211c\"}}', '2026-09-09 01:31:48', '2026-09-09 01:31:48'),
('footer', '{\"v\":{\"copyright\":\"\\u00a9 {year} Grocerly\",\"app_store_url\":\"https:\\/\\/apps.apple.com\\/app\\/grocerly-demo\",\"play_store_url\":\"https:\\/\\/play.google.com\\/store\\/apps\\/details?id=com.grocerly.demo\",\"socials\":{\"facebook\":\"https:\\/\\/facebook.com\\/grocerly\",\"x\":\"https:\\/\\/x.com\\/grocerly\",\"instagram\":\"https:\\/\\/instagram.com\\/grocerly\",\"linkedin\":\"https:\\/\\/www.linkedin.com\\/company\\/grocerly\",\"youtube\":\"https:\\/\\/www.youtube.com\\/@grocerly\"},\"links\":[]}}', '2026-09-09 01:12:49', '2026-09-09 01:12:49');

-- --------------------------------------------------------

--
-- Table structure for table `stores`
--

CREATE TABLE `stores` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL DEFAULT 'Main Store',
  `line1` varchar(255) NOT NULL,
  `line2` varchar(255) DEFAULT NULL,
  `city` varchar(100) NOT NULL,
  `state` varchar(60) NOT NULL,
  `postal_code` varchar(12) NOT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `delivery_radius_km` smallint(5) UNSIGNED NOT NULL DEFAULT 5,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `stores`
--

INSERT INTO `stores` (`id`, `name`, `line1`, `line2`, `city`, `state`, `postal_code`, `latitude`, `longitude`, `delivery_radius_km`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 'Caresort Solutions', 'C-86, Pannu Tower 4th Floor', 'Phase 7, Industrial Area', 'Sahibzada Ajit Singh Nagar', 'Punjab', '160055', 30.6908804, 76.7114879, 5, 1, '2026-09-09 01:33:16', '2026-09-09 01:33:16'),
(2, 'The Royal Majestic', 'chowk, 200 Feet Rd, near Phullanwal', 'Passi Nagar', 'Ludhiana', 'Punjab', '141013', 30.9090157, 75.8516010, 5, 1, '2026-09-09 01:36:49', '2026-09-09 01:36:49');

-- --------------------------------------------------------

--
-- Table structure for table `store_inventory`
--

CREATE TABLE `store_inventory` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `store_id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `product_variant_id` bigint(20) UNSIGNED DEFAULT NULL,
  `quantity` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `is_stocked` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `store_inventory`
--

INSERT INTO `store_inventory` (`id`, `store_id`, `product_id`, `product_variant_id`, `quantity`, `is_stocked`, `created_at`, `updated_at`) VALUES
(1, 1, 54, NULL, 50, 1, '2026-09-09 04:21:55', '2026-09-09 04:21:55');

-- --------------------------------------------------------

--
-- Table structure for table `stripe_events`
--

CREATE TABLE `stripe_events` (
  `id` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `processed_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `support_messages`
--

CREATE TABLE `support_messages` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `support_thread_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `is_staff` tinyint(1) NOT NULL DEFAULT 0,
  `body` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `support_messages`
--

INSERT INTO `support_messages` (`id`, `support_thread_id`, `user_id`, `is_staff`, `body`, `created_at`, `updated_at`) VALUES
(1, 1, NULL, 0, 'Support request opened — item missing.', '2026-09-09 02:28:35', '2026-09-09 02:28:35'),
(2, 1, 17, 0, 'Hi', '2026-09-09 02:28:35', '2026-09-09 02:28:35'),
(3, 1, 15, 1, 'Hi', '2026-09-09 02:39:52', '2026-09-09 02:39:52'),
(4, 1, 15, 1, 'We have noticed that your order is just packed and ready to be delivered. Please elaborate your issue.', '2026-09-09 02:40:31', '2026-09-09 02:40:31'),
(5, 2, NULL, 0, 'Your delivery rider started a chat about order #3.', '2026-09-09 04:34:33', '2026-09-09 04:34:33'),
(6, 2, 16, 1, 'Hi, I have picked up order.', '2026-09-09 04:34:46', '2026-09-09 04:34:46'),
(7, 2, 17, 0, 'Ok.', '2026-09-09 05:00:07', '2026-09-09 05:00:07'),
(8, 1, 15, 1, 'Delivered.', '2026-09-09 05:07:13', '2026-09-09 05:07:13');

-- --------------------------------------------------------

--
-- Table structure for table `support_threads`
--

CREATE TABLE `support_threads` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `order_id` bigint(20) UNSIGNED DEFAULT NULL,
  `issue_type` varchar(255) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'open',
  `last_message_at` timestamp NULL DEFAULT NULL,
  `last_staff_message_at` timestamp NULL DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `rating` tinyint(3) UNSIGNED DEFAULT NULL,
  `rating_comment` text DEFAULT NULL,
  `rated_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `support_threads`
--

INSERT INTO `support_threads` (`id`, `user_id`, `order_id`, `issue_type`, `status`, `last_message_at`, `last_staff_message_at`, `resolved_at`, `rating`, `rating_comment`, `rated_at`, `created_at`, `updated_at`) VALUES
(1, 17, NULL, 'item_missing', 'resolved', '2026-09-09 05:07:13', '2026-09-09 05:07:13', '2026-09-09 05:11:44', 5, 'got order.', '2026-09-09 05:47:54', '2026-09-09 02:28:35', '2026-09-09 05:47:54'),
(2, 17, 3, 'delivery', 'resolved', '2026-09-09 05:00:07', '2026-09-09 04:34:46', '2026-09-09 05:11:32', NULL, NULL, NULL, '2026-09-09 04:34:33', '2026-09-09 05:11:32');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `stripe_customer_id` varchar(255) DEFAULT NULL,
  `is_admin` tinyint(1) NOT NULL DEFAULT 0,
  `is_rider` tinyint(1) NOT NULL DEFAULT 0,
  `rider_is_active` tinyint(1) NOT NULL DEFAULT 1,
  `rider_rating_avg` decimal(3,2) DEFAULT NULL,
  `rider_rating_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `rider_base_address` varchar(255) DEFAULT NULL,
  `rider_base_lat` decimal(10,7) DEFAULT NULL,
  `rider_base_lng` decimal(10,7) DEFAULT NULL,
  `rider_last_lat` decimal(10,7) DEFAULT NULL,
  `rider_last_lng` decimal(10,7) DEFAULT NULL,
  `rider_last_located_at` timestamp NULL DEFAULT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `phone`, `stripe_customer_id`, `is_admin`, `is_rider`, `rider_is_active`, `rider_rating_avg`, `rider_rating_count`, `rider_base_address`, `rider_base_lat`, `rider_base_lng`, `rider_last_lat`, `rider_last_lng`, `rider_last_located_at`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(15, 'Test User', 'test@example.com', '+15551234567', 'cus_VEAEdiTnuYPjHz', 1, 0, 1, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-09 01:12:48', '$2y$12$skX3B4/nh5s/002bOYkfZ.uO5eeXCokTCYPh.8Q.Z28wpSnfcUDvy', NULL, '2026-09-09 01:12:48', '2026-09-09 04:04:45'),
(16, 'Sam Rider', 'rider@example.com', NULL, NULL, 0, 1, 1, 5.00, 1, NULL, NULL, NULL, NULL, NULL, NULL, '2026-09-09 01:12:48', '$2y$12$skX3B4/nh5s/002bOYkfZ.uO5eeXCokTCYPh.8Q.Z28wpSnfcUDvy', NULL, '2026-09-09 01:12:48', '2026-09-09 05:42:37'),
(17, 'Testcaresort', 'testcaresort@outlook.com', '9888888888', 'cus_VE8eecdx05e2pN', 0, 0, 1, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '$2y$12$skX3B4/nh5s/002bOYkfZ.uO5eeXCokTCYPh.8Q.Z28wpSnfcUDvy', NULL, '2026-09-09 02:25:33', '2026-09-09 02:28:06'),
(18, 'New Ride', 'new_ride@example.com', NULL, NULL, 0, 1, 1, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '$2y$12$kvtzqkILF65K1f7Zekch8ux7wHqhyNNSBFQG0zutKPpuhtETcpLZe', NULL, '2026-09-09 05:14:36', '2026-09-09 05:49:57'),
(19, 'Ride Example', 'ride_example@gmail.com', NULL, NULL, 0, 1, 1, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '$2y$12$s8TjsvlZWoF3ROrlOuTM2ucqQDyws.3wK9rRNdYSEe4Y6x/JnNos2', NULL, '2026-09-09 05:15:06', '2026-09-09 05:50:12');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `addresses`
--
ALTER TABLE `addresses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `addresses_user_id_is_default_index` (`user_id`,`is_default`);

--
-- Indexes for table `auth_otps`
--
ALTER TABLE `auth_otps`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `auth_otps_email_purpose_unique` (`email`,`purpose`);

--
-- Indexes for table `banners`
--
ALTER TABLE `banners`
  ADD PRIMARY KEY (`id`),
  ADD KEY `banners_is_active_sort_order_index` (`is_active`,`sort_order`);

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_expiration_index` (`expiration`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`),
  ADD KEY `cache_locks_expiration_index` (`expiration`);

--
-- Indexes for table `carts`
--
ALTER TABLE `carts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `carts_user_id_unique` (`user_id`);

--
-- Indexes for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `cart_items_cart_id_product_id_product_variant_id_unique` (`cart_id`,`product_id`,`product_variant_id`),
  ADD KEY `cart_items_product_id_foreign` (`product_id`),
  ADD KEY `cart_items_product_variant_id_foreign` (`product_variant_id`),
  ADD KEY `cart_items_cart_id_index` (`cart_id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `categories_slug_unique` (`slug`),
  ADD KEY `categories_is_active_index` (`is_active`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`),
  ADD KEY `failed_jobs_connection_queue_failed_at_index` (`connection`,`queue`,`failed_at`);

--
-- Indexes for table `home_tiles`
--
ALTER TABLE `home_tiles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `home_tiles_is_active_sort_order_index` (`is_active`,`sort_order`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `orders_stripe_payment_intent_id_unique` (`stripe_payment_intent_id`),
  ADD KEY `orders_user_id_foreign` (`user_id`),
  ADD KEY `orders_status_index` (`status`),
  ADD KEY `orders_payment_status_index` (`payment_status`),
  ADD KEY `orders_payment_method_index` (`payment_method`),
  ADD KEY `orders_delivery_partner_id_foreign` (`delivery_partner_id`),
  ADD KEY `orders_store_id_foreign` (`store_id`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_items_order_id_foreign` (`order_id`),
  ADD KEY `order_items_product_id_foreign` (`product_id`),
  ADD KEY `order_items_product_variant_id_foreign` (`product_variant_id`);

--
-- Indexes for table `order_refunds`
--
ALTER TABLE `order_refunds`
  ADD PRIMARY KEY (`id`),
  ADD KEY `order_refunds_order_id_foreign` (`order_id`),
  ADD KEY `order_refunds_support_thread_id_foreign` (`support_thread_id`),
  ADD KEY `order_refunds_created_by_foreign` (`created_by`);

--
-- Indexes for table `pages`
--
ALTER TABLE `pages`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `pages_slug_unique` (`slug`),
  ADD KEY `pages_is_published_show_in_footer_sort_order_index` (`is_published`,`show_in_footer`,`sort_order`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  ADD KEY `personal_access_tokens_expires_at_index` (`expires_at`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `products_slug_unique` (`slug`),
  ADD UNIQUE KEY `products_sku_unique` (`sku`),
  ADD KEY `products_category_id_foreign` (`category_id`),
  ADD KEY `products_is_active_index` (`is_active`);

--
-- Indexes for table `product_variants`
--
ALTER TABLE `product_variants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `product_variants_sku_unique` (`sku`),
  ADD KEY `product_variants_product_id_sort_order_index` (`product_id`,`sort_order`),
  ADD KEY `product_variants_is_active_index` (`is_active`);

--
-- Indexes for table `rider_reviews`
--
ALTER TABLE `rider_reviews`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `rider_reviews_order_id_unique` (`order_id`),
  ADD KEY `rider_reviews_user_id_foreign` (`user_id`),
  ADD KEY `rider_reviews_rider_id_created_at_index` (`rider_id`,`created_at`);

--
-- Indexes for table `rider_store`
--
ALTER TABLE `rider_store`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `rider_store_user_id_store_id_unique` (`user_id`,`store_id`),
  ADD KEY `rider_store_store_id_foreign` (`store_id`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `settings`
--
ALTER TABLE `settings`
  ADD PRIMARY KEY (`key`);

--
-- Indexes for table `stores`
--
ALTER TABLE `stores`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `store_inventory`
--
ALTER TABLE `store_inventory`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `store_inventory_store_id_product_id_product_variant_id_unique` (`store_id`,`product_id`,`product_variant_id`),
  ADD KEY `store_inventory_product_variant_id_foreign` (`product_variant_id`),
  ADD KEY `store_inventory_product_id_store_id_index` (`product_id`,`store_id`);

--
-- Indexes for table `stripe_events`
--
ALTER TABLE `stripe_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `stripe_events_type_index` (`type`);

--
-- Indexes for table `support_messages`
--
ALTER TABLE `support_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `support_messages_user_id_foreign` (`user_id`),
  ADD KEY `support_messages_support_thread_id_id_index` (`support_thread_id`,`id`);

--
-- Indexes for table `support_threads`
--
ALTER TABLE `support_threads`
  ADD PRIMARY KEY (`id`),
  ADD KEY `support_threads_user_id_foreign` (`user_id`),
  ADD KEY `support_threads_order_id_foreign` (`order_id`),
  ADD KEY `support_threads_status_index` (`status`),
  ADD KEY `support_threads_last_message_at_index` (`last_message_at`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `addresses`
--
ALTER TABLE `addresses`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `auth_otps`
--
ALTER TABLE `auth_otps`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `banners`
--
ALTER TABLE `banners`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `carts`
--
ALTER TABLE `carts`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `cart_items`
--
ALTER TABLE `cart_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `home_tiles`
--
ALTER TABLE `home_tiles`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `order_refunds`
--
ALTER TABLE `order_refunds`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pages`
--
ALTER TABLE `pages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=47;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=55;

--
-- AUTO_INCREMENT for table `product_variants`
--
ALTER TABLE `product_variants`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `rider_reviews`
--
ALTER TABLE `rider_reviews`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `rider_store`
--
ALTER TABLE `rider_store`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stores`
--
ALTER TABLE `stores`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `store_inventory`
--
ALTER TABLE `store_inventory`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `support_messages`
--
ALTER TABLE `support_messages`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `support_threads`
--
ALTER TABLE `support_threads`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `addresses`
--
ALTER TABLE `addresses`
  ADD CONSTRAINT `addresses_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `carts`
--
ALTER TABLE `carts`
  ADD CONSTRAINT `carts_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `cart_items`
--
ALTER TABLE `cart_items`
  ADD CONSTRAINT `cart_items_cart_id_foreign` FOREIGN KEY (`cart_id`) REFERENCES `carts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `cart_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `cart_items_product_variant_id_foreign` FOREIGN KEY (`product_variant_id`) REFERENCES `product_variants` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_delivery_partner_id_foreign` FOREIGN KEY (`delivery_partner_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `orders_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `orders_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `order_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `order_items_product_variant_id_foreign` FOREIGN KEY (`product_variant_id`) REFERENCES `product_variants` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `order_refunds`
--
ALTER TABLE `order_refunds`
  ADD CONSTRAINT `order_refunds_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `order_refunds_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `order_refunds_support_thread_id_foreign` FOREIGN KEY (`support_thread_id`) REFERENCES `support_threads` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_category_id_foreign` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `product_variants`
--
ALTER TABLE `product_variants`
  ADD CONSTRAINT `product_variants_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `rider_reviews`
--
ALTER TABLE `rider_reviews`
  ADD CONSTRAINT `rider_reviews_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rider_reviews_rider_id_foreign` FOREIGN KEY (`rider_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rider_reviews_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `rider_store`
--
ALTER TABLE `rider_store`
  ADD CONSTRAINT `rider_store_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `rider_store_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `store_inventory`
--
ALTER TABLE `store_inventory`
  ADD CONSTRAINT `store_inventory_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `store_inventory_product_variant_id_foreign` FOREIGN KEY (`product_variant_id`) REFERENCES `product_variants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `store_inventory_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `support_messages`
--
ALTER TABLE `support_messages`
  ADD CONSTRAINT `support_messages_support_thread_id_foreign` FOREIGN KEY (`support_thread_id`) REFERENCES `support_threads` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `support_messages_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `support_threads`
--
ALTER TABLE `support_threads`
  ADD CONSTRAINT `support_threads_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `support_threads_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
