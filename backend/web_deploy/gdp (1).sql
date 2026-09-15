
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `gdp` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;

USE `gdp`;
DROP TABLE IF EXISTS `addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `addresses` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
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
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `addresses_user_id_is_default_index` (`user_id`,`is_default`),
  CONSTRAINT `addresses_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `addresses` WRITE;
/*!40000 ALTER TABLE `addresses` DISABLE KEYS */;
INSERT INTO `addresses` VALUES (1,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,1,'2026-09-09 02:28:05','2026-09-09 02:28:05'),(2,15,'Home','Test User','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,1,'2026-09-09 04:04:43','2026-09-09 04:04:43'),(3,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-10 05:14:36','2026-09-10 05:14:36'),(4,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-10 05:14:44','2026-09-10 05:14:44'),(5,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-10 07:25:56','2026-09-10 07:25:56'),(6,15,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-10 07:27:16','2026-09-10 07:27:16'),(7,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-10 23:19:31','2026-09-10 23:19:31'),(8,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-11 00:16:43','2026-09-11 00:16:43'),(9,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-11 02:15:09','2026-09-11 02:15:09'),(10,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-11 02:16:32','2026-09-11 02:16:32'),(11,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-11 02:26:55','2026-09-11 02:26:55'),(12,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-11 02:27:11','2026-09-11 02:27:11'),(13,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-11 02:51:54','2026-09-11 02:51:54'),(14,15,'Home','Test User','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-11 04:19:57','2026-09-11 04:19:57'),(15,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-11 04:35:06','2026-09-11 04:35:06'),(16,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-11 07:31:04','2026-09-11 07:31:04'),(17,17,'Home','Testcaresort','34 Jan Marg',NULL,'Mohali','PB','160061',30.7149794,76.7227993,0,'2026-09-14 06:14:06','2026-09-14 06:14:06');
/*!40000 ALTER TABLE `addresses` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `auth_otps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auth_otps` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `purpose` varchar(255) NOT NULL,
  `code_hash` varchar(255) NOT NULL,
  `attempts` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `expires_at` timestamp NULL DEFAULT NULL,
  `last_sent_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_otps_email_purpose_unique` (`email`,`purpose`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `auth_otps` WRITE;
/*!40000 ALTER TABLE `auth_otps` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_otps` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `banners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `banners` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `image_url` varchar(255) NOT NULL,
  `headline` varchar(255) DEFAULT NULL,
  `category_slug` varchar(255) DEFAULT NULL,
  `link_url` varchar(255) DEFAULT NULL,
  `placement` varchar(255) NOT NULL DEFAULT 'hero',
  `sort_order` int(10) unsigned NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `banners_is_active_sort_order_index` (`is_active`,`sort_order`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `banners` WRITE;
/*!40000 ALTER TABLE `banners` DISABLE KEYS */;
INSERT INTO `banners` VALUES (1,'/storage/products/k6QEhTv4qkr8iRWjC8pmtA6dscPBDgVE4F6KfUv2.png',NULL,'mobiles-smartphones',NULL,'hero',1,1,'2026-09-09 01:12:49','2026-09-14 23:42:23'),(2,'/storage/products/IT7BJ7r9I1BDJedkfQFO9oOpHFsz6dbUIjqc8v9p.png',NULL,'personal-care-electronics',NULL,'strip',2,1,'2026-09-09 01:12:49','2026-09-14 23:23:56'),(3,'/storage/products/SP6cbTpeV7pzv5gQhy82ASn7aLBAYcHUzKZWbBMt.png',NULL,'office-electronics',NULL,'strip',3,1,'2026-09-09 01:12:49','2026-09-14 23:42:23'),(4,'/storage/products/MNJkvZ4zGLm8fLGPhLWQDCnVkzq9aZZYoyKfwSS3.png',NULL,'kids-and-baby-tech',NULL,'strip',4,1,'2026-09-09 01:12:49','2026-09-14 23:23:56');
/*!40000 ALTER TABLE `banners` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` bigint(20) NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `cache` WRITE;
/*!40000 ALTER TABLE `cache` DISABLE KEYS */;
INSERT INTO `cache` VALUES ('gdp-cache-5c785c036466adea360111aa28563bfd556b5fba','i:2;',1789449400),('gdp-cache-5c785c036466adea360111aa28563bfd556b5fba:timer','i:1789449400;',1789449400),('gdp-cache-f153c56c8683a66a6decfec398620934d9417085','i:1;',1789364563),('gdp-cache-f153c56c8683a66a6decfec398620934d9417085:timer','i:1789364563;',1789364563),('gdp-cache-f1abd670358e036c31296e66b3b66c382ac00812','i:1;',1789028312),('gdp-cache-f1abd670358e036c31296e66b3b66c382ac00812:timer','i:1789028312;',1789028312),('gdp-cache-geo:search:10cdb4eb2195350bbedb9efe333e521a','a:2:{i:0;a:8:{s:5:\"label\";s:36:\"Mohali, S.A.S. Nagar (Mohali) Tahsil\";s:4:\"full\";s:87:\"Mohali, S.A.S. Nagar (Mohali) Tahsil, Sahibzada Ajit Singh Nagar, Punjab, 140062, India\";s:5:\"line1\";s:64:\"Mohali, S.A.S. Nagar (Mohali) Tahsil, Sahibzada Ajit Singh Nagar\";s:4:\"city\";s:6:\"Mohali\";s:5:\"state\";s:6:\"Punjab\";s:11:\"postal_code\";s:6:\"140062\";s:3:\"lat\";d:30.6908804;s:3:\"lon\";d:76.7114879;}i:1;a:8:{s:5:\"label\";s:34:\"Sahibzada Ajit Singh Nagar, Punjab\";s:4:\"full\";s:41:\"Sahibzada Ajit Singh Nagar, Punjab, India\";s:5:\"line1\";s:41:\"Sahibzada Ajit Singh Nagar, Punjab, India\";s:4:\"city\";s:26:\"Sahibzada Ajit Singh Nagar\";s:5:\"state\";s:6:\"Punjab\";s:11:\"postal_code\";s:0:\"\";s:3:\"lat\";d:30.6488449;s:3:\"lon\";d:76.7412738;}}',1789023796),('gdp-cache-geo:search:f5b077e12c3d6147e345fdec766bfac3','a:2:{i:0;a:8:{s:5:\"label\";s:32:\"Ludhiana, Ludhiana (West) Tahsil\";s:4:\"full\";s:65:\"Ludhiana, Ludhiana (West) Tahsil, Ludhiana, Punjab, 141001, India\";s:5:\"line1\";s:42:\"Ludhiana, Ludhiana (West) Tahsil, Ludhiana\";s:4:\"city\";s:8:\"Ludhiana\";s:5:\"state\";s:6:\"Punjab\";s:11:\"postal_code\";s:6:\"141001\";s:3:\"lat\";d:30.9090157;s:3:\"lon\";d:75.851601;}i:1;a:8:{s:5:\"label\";s:16:\"Ludhiana, Punjab\";s:4:\"full\";s:23:\"Ludhiana, Punjab, India\";s:5:\"line1\";s:23:\"Ludhiana, Punjab, India\";s:4:\"city\";s:8:\"Ludhiana\";s:5:\"state\";s:6:\"Punjab\";s:11:\"postal_code\";s:0:\"\";s:3:\"lat\";d:30.789407;s:3:\"lon\";d:75.8269724;}}',1789024009),('gdp-cache-secure_access_grant:15','s:64:\"7c18d8479034c3ab86ba657036d640736a4ad722ff90d500be9b4aba8020b421\";',1789029153),('gdp-cache-setting:branding','a:1:{s:1:\"v\";a:9:{s:10:\"store_name\";s:7:\"NexTech\";s:7:\"tagline\";s:36:\"Navigate to the Future of Technology\";s:8:\"logo_url\";N;s:11:\"favicon_url\";s:62:\"/storage/products/UwbDkyfQGw98w7hhx7hlPcFS1Cw9VZfnz06klnyk.jpg\";s:5:\"theme\";s:5:\"light\";s:12:\"layout_width\";s:4:\"full\";s:11:\"color_brand\";s:7:\"#2563EB\";s:12:\"color_accent\";s:7:\"#F97316\";s:13:\"color_heading\";s:7:\"#0F172A\";}}',2104749424),('gdp-cache-setting:checkout_fees','a:1:{s:1:\"v\";a:9:{s:13:\"delivery_mode\";s:5:\"fixed\";s:18:\"delivery_fee_cents\";i:299;s:23:\"delivery_near_fee_cents\";i:199;s:22:\"delivery_far_fee_cents\";i:599;s:29:\"free_delivery_threshold_cents\";i:3500;s:18:\"handling_fee_cents\";i:99;s:20:\"small_cart_fee_cents\";i:199;s:20:\"small_cart_min_cents\";i:1000;s:12:\"tax_rate_bps\";i:887;}}',2104405010),('gdp-cache-setting:cod_enabled','a:1:{s:1:\"v\";b:1;}',2104405009),('gdp-cache-setting:footer','a:1:{s:1:\"v\";a:6:{s:9:\"copyright\";s:17:\"© {year} nextech\";s:4:\"note\";s:143:\"NexTech is a demo storefront. Prices, delivery estimates and content pages are illustrative and set by the store operator in the admin console.\";s:13:\"app_store_url\";s:40:\"https://apps.apple.com/app/grocerly-demo\";s:14:\"play_store_url\";s:63:\"https://play.google.com/store/apps/details?id=com.grocerly.demo\";s:7:\"socials\";a:5:{s:8:\"facebook\";s:29:\"https://facebook.com/grocerly\";s:1:\"x\";s:22:\"https://x.com/grocerly\";s:9:\"instagram\";s:30:\"https://instagram.com/grocerly\";s:8:\"linkedin\";s:41:\"https://www.linkedin.com/company/grocerly\";s:7:\"youtube\";s:33:\"https://www.youtube.com/@grocerly\";}s:5:\"links\";a:0:{}}}',2104744961),('gdp-cache-setting:home_notice','a:1:{s:7:\"missing\";b:1;}',2104726258),('gdp-cache-setting:payments','a:1:{s:7:\"missing\";b:1;}',2104296062),('gdp-cache-setting:rider_auto_assign','a:1:{s:7:\"missing\";b:1;}',2104297300);
/*!40000 ALTER TABLE `cache` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` bigint(20) NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `cache_locks` WRITE;
/*!40000 ALTER TABLE `cache_locks` DISABLE KEYS */;
/*!40000 ALTER TABLE `cache_locks` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `cart_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `cart_items` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `cart_id` bigint(20) unsigned NOT NULL,
  `product_id` bigint(20) unsigned NOT NULL,
  `product_variant_id` bigint(20) unsigned DEFAULT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `unit_price_cents` int(10) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cart_items_cart_id_product_id_product_variant_id_unique` (`cart_id`,`product_id`,`product_variant_id`),
  KEY `cart_items_product_id_foreign` (`product_id`),
  KEY `cart_items_product_variant_id_foreign` (`product_variant_id`),
  KEY `cart_items_cart_id_index` (`cart_id`),
  CONSTRAINT `cart_items_cart_id_foreign` FOREIGN KEY (`cart_id`) REFERENCES `carts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `cart_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `cart_items_product_variant_id_foreign` FOREIGN KEY (`product_variant_id`) REFERENCES `product_variants` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `cart_items` WRITE;
/*!40000 ALTER TABLE `cart_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `cart_items` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `carts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `carts` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `carts_user_id_unique` (`user_id`),
  CONSTRAINT `carts_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `carts` WRITE;
/*!40000 ALTER TABLE `carts` DISABLE KEYS */;
INSERT INTO `carts` VALUES (1,17,'2026-09-09 02:28:05','2026-09-09 02:28:05'),(2,15,'2026-09-09 04:04:42','2026-09-09 04:04:42');
/*!40000 ALTER TABLE `carts` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `categories` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` int(10) unsigned NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `categories_slug_unique` (`slug`),
  KEY `categories_is_active_index` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` VALUES (1,'Mobiles & Smartphones','mobiles-smartphones',NULL,'/img/cat/mobiles-smartphones.webp',1,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(2,'Laptops & Computers','laptops-computers',NULL,'/img/cat/laptops-computers.webp',1,2,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(3,'Audio & Headphones','audio-headphones',NULL,'/img/cat/audio-headphones.jpg',1,3,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(4,'Mobile Accessories','mobile-accessories',NULL,'/img/cat/mobile-accessories.webp',1,4,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(5,'Smart Watches & Wearables','smart-watches-wearables',NULL,'/img/cat/smart-watches-wearables.jpg',1,5,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(6,'Cameras & Photography','cameras-photography',NULL,'/img/cat/cameras-photography.jpg',1,6,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(7,'Televisions','televisions',NULL,'/img/cat/televisions.jpg',1,7,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(8,'Gaming Consoles & Accessories','gaming-consoles-accessories',NULL,'/img/cat/gaming-consoles-accessories.png',1,8,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(9,'Home Appliances','home-appliances',NULL,'/img/cat/home-appliances.jpg',1,9,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(10,'Computer Accessories','computer-accessories',NULL,'/img/cat/computer-accessories.jpg',1,10,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(11,'Power Banks & Chargers','power-banks-chargers',NULL,'/img/cat/power-banks-chargers.jpg',1,11,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(12,'Storage Devices','storage-devices',NULL,'/img/cat/storage-devices.jpg',1,12,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(13,'Networking Devices','networking-devices',NULL,'/img/cat/networking-devices.jpg',1,13,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(14,'Personal Care Electronics','personal-care-electronics',NULL,'/img/cat/personal-care-electronics.jpg',1,14,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(15,'Kids & Baby Tech','kids-and-baby-tech',NULL,'/img/cat/kids-and-baby-tech.webp',1,15,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(16,'Office Electronics','office-electronics',NULL,'/img/cat/office-electronics.jpg',1,16,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(17,'Smart Home','smart-home',NULL,'/img/cat/smart-home.webp',1,17,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(18,'Health & Fitness Tech','health-and-fitness-tech',NULL,'/img/cat/health-and-fitness-tech.jpg',1,18,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(19,'Premium & Flagship','premium-and-flagship',NULL,'/img/cat/premium-and-flagship.webp',1,19,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(20,'Car Electronics','car-electronics',NULL,'/img/cat/car-electronics.jpg',1,20,'2026-09-09 01:12:49','2026-09-14 06:01:19');
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `failed_jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) NOT NULL,
  `connection` varchar(255) NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`),
  KEY `failed_jobs_connection_queue_failed_at_index` (`connection`,`queue`,`failed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `failed_jobs` WRITE;
/*!40000 ALTER TABLE `failed_jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `failed_jobs` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `gift_card_redemptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gift_card_redemptions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `gift_card_id` bigint(20) unsigned NOT NULL,
  `order_id` bigint(20) unsigned NOT NULL,
  `amount_cents` int(10) unsigned NOT NULL,
  `reversed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `gift_card_redemptions_gift_card_id_foreign` (`gift_card_id`),
  KEY `gift_card_redemptions_order_id_foreign` (`order_id`),
  CONSTRAINT `gift_card_redemptions_gift_card_id_foreign` FOREIGN KEY (`gift_card_id`) REFERENCES `gift_cards` (`id`) ON DELETE CASCADE,
  CONSTRAINT `gift_card_redemptions_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `gift_card_redemptions` WRITE;
/*!40000 ALTER TABLE `gift_card_redemptions` DISABLE KEYS */;
/*!40000 ALTER TABLE `gift_card_redemptions` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `gift_cards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gift_cards` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `pin_hash` varchar(255) NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `issued_by` bigint(20) unsigned DEFAULT NULL,
  `support_thread_id` bigint(20) unsigned DEFAULT NULL,
  `order_id` bigint(20) unsigned DEFAULT NULL,
  `initial_cents` int(10) unsigned NOT NULL,
  `balance_cents` int(10) unsigned NOT NULL,
  `reason` varchar(200) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `gift_cards_code_unique` (`code`),
  KEY `gift_cards_issued_by_foreign` (`issued_by`),
  KEY `gift_cards_support_thread_id_foreign` (`support_thread_id`),
  KEY `gift_cards_order_id_foreign` (`order_id`),
  KEY `gift_cards_user_id_is_active_index` (`user_id`,`is_active`),
  CONSTRAINT `gift_cards_issued_by_foreign` FOREIGN KEY (`issued_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `gift_cards_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL,
  CONSTRAINT `gift_cards_support_thread_id_foreign` FOREIGN KEY (`support_thread_id`) REFERENCES `support_threads` (`id`) ON DELETE SET NULL,
  CONSTRAINT `gift_cards_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `gift_cards` WRITE;
/*!40000 ALTER TABLE `gift_cards` DISABLE KEYS */;
INSERT INTO `gift_cards` VALUES (1,'GC-CYJE-482G','$2y$12$y1Sa7Th/HYauU6FhbHCQhu8adrdaC8ngvAs2kZIoYrupnCNrEyToe',15,NULL,NULL,NULL,350,350,NULL,1,'2026-09-10 07:56:07','2026-09-10 07:56:07'),(2,'GC-5FSZ-EYUA','$2y$12$1ntNpBpn/b8YlFxFtGfhsu/HifkYFvZobKfct52QdRKMi7qIcwcba',17,15,NULL,NULL,2350,0,'Client not happy with order.',0,'2026-09-11 00:14:43','2026-09-11 02:16:33'),(3,'GC-HMAV-D8X5','$2y$12$nmvFAoT7yed7ihnAmTjm5OF7seniTrLaB5cUAFQUnSnuQXU/VvAtG',17,15,NULL,NULL,500,500,'Test issue without thread',1,'2026-09-11 00:54:36','2026-09-11 00:54:36'),(4,'GC-56UL-WBTS','$2y$12$/hntxfZReWtfKUt98394qOmOsgauRfQg2o5IG9qOQkRVSlFIbxFBi',17,15,NULL,NULL,649,649,'broken received.',1,'2026-09-11 04:43:40','2026-09-11 04:43:40');
/*!40000 ALTER TABLE `gift_cards` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `home_tiles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `home_tiles` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `category_slug` varchar(255) DEFAULT NULL,
  `link_url` varchar(255) DEFAULT NULL,
  `sort_order` int(10) unsigned NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `home_tiles_is_active_sort_order_index` (`is_active`,`sort_order`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `home_tiles` WRITE;
/*!40000 ALTER TABLE `home_tiles` DISABLE KEYS */;
INSERT INTO `home_tiles` VALUES (1,NULL,NULL,'mobiles-smartphones',NULL,1,1,'2026-09-09 01:12:49','2026-09-14 23:42:24'),(2,NULL,NULL,'laptops-computers',NULL,2,1,'2026-09-09 01:12:49','2026-09-14 23:42:24'),(3,NULL,NULL,'audio-headphones',NULL,3,1,'2026-09-09 01:12:49','2026-09-14 23:42:25'),(4,NULL,NULL,'mobile-accessories',NULL,4,1,'2026-09-09 01:12:49','2026-09-14 23:42:25'),(5,NULL,NULL,'smart-watches-wearables',NULL,5,1,'2026-09-09 01:12:49','2026-09-14 23:42:25'),(6,NULL,NULL,'cameras-photography',NULL,6,1,'2026-09-09 01:12:49','2026-09-14 23:42:26'),(7,NULL,NULL,'televisions',NULL,7,1,'2026-09-09 01:12:49','2026-09-14 23:42:26'),(8,NULL,NULL,'gaming-consoles-accessories',NULL,8,1,'2026-09-09 01:12:49','2026-09-14 23:42:26'),(9,NULL,NULL,'home-appliances',NULL,9,1,'2026-09-09 01:12:49','2026-09-14 23:42:27'),(10,NULL,NULL,'computer-accessories',NULL,10,1,'2026-09-09 01:12:49','2026-09-14 23:42:27'),(11,NULL,NULL,'power-banks-chargers',NULL,11,1,'2026-09-09 01:12:49','2026-09-14 23:42:27'),(12,NULL,NULL,'storage-devices',NULL,12,1,'2026-09-09 01:12:49','2026-09-14 23:42:28'),(13,NULL,NULL,'networking-devices',NULL,13,1,'2026-09-09 01:12:49','2026-09-14 23:42:28'),(14,NULL,NULL,'personal-care-electronics',NULL,14,1,'2026-09-09 01:12:49','2026-09-14 23:42:28'),(15,NULL,NULL,'kids-and-baby-tech',NULL,15,1,'2026-09-09 01:12:49','2026-09-14 23:42:29'),(16,NULL,NULL,'office-electronics',NULL,16,1,'2026-09-09 01:12:49','2026-09-14 23:42:29'),(17,NULL,NULL,'smart-home',NULL,17,1,'2026-09-09 01:12:49','2026-09-14 23:42:29'),(18,NULL,NULL,'health-and-fitness-tech',NULL,18,1,'2026-09-09 01:12:49','2026-09-14 23:42:30'),(19,NULL,NULL,'premium-and-flagship',NULL,19,1,'2026-09-09 01:12:49','2026-09-14 23:42:30'),(20,NULL,NULL,'car-electronics',NULL,20,1,'2026-09-09 01:12:49','2026-09-14 23:42:30');
/*!40000 ALTER TABLE `home_tiles` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
  `finished_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `job_batches` WRITE;
/*!40000 ALTER TABLE `job_batches` DISABLE KEYS */;
/*!40000 ALTER TABLE `job_batches` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` smallint(5) unsigned NOT NULL,
  `reserved_at` int(10) unsigned DEFAULT NULL,
  `available_at` int(10) unsigned NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `jobs` WRITE;
/*!40000 ALTER TABLE `jobs` DISABLE KEYS */;
/*!40000 ALTER TABLE `jobs` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `migrations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=69 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
INSERT INTO `migrations` VALUES (1,'0001_01_01_000000_create_users_table',1),(2,'0001_01_01_000001_create_cache_table',1),(3,'0001_01_01_000002_create_jobs_table',1),(4,'2026_09_04_054409_create_personal_access_tokens_table',1),(5,'2026_09_04_060000_create_categories_table',1),(6,'2026_09_04_060001_create_products_table',1),(7,'2026_09_04_070000_create_carts_table',1),(8,'2026_09_04_070001_create_cart_items_table',1),(9,'2026_09_04_080000_create_orders_table',1),(10,'2026_09_04_080001_create_order_items_table',1),(11,'2026_09_04_090000_create_addresses_table',1),(12,'2026_09_04_100000_add_stripe_payment_intent_to_orders_table',1),(13,'2026_09_04_110000_create_stripe_events_table',1),(14,'2026_09_04_120000_add_is_admin_to_users_table',1),(15,'2026_09_04_130000_add_courier_name_to_orders_table',1),(16,'2026_09_04_140000_create_auth_otps_table',1),(17,'2026_09_04_150000_create_stores_table',1),(18,'2026_09_04_150001_add_geo_to_addresses_table',1),(19,'2026_09_07_120000_create_settings_table',1),(20,'2026_09_07_120001_add_payment_method_to_orders_table',1),(21,'2026_09_07_140000_add_fee_breakdown_to_orders_table',1),(22,'2026_09_07_160000_create_product_variants_table',1),(23,'2026_09_07_160001_add_variant_to_cart_items_table',1),(24,'2026_09_07_160002_add_variant_to_order_items_table',1),(25,'2026_09_07_180000_relax_address_text_columns',1),(26,'2026_09_07_190000_add_delivery_instructions_to_orders_table',1),(27,'2026_09_07_200000_rename_preparing_status_to_packing',1),(28,'2026_09_07_210000_add_stripe_refund_id_to_orders_table',1),(29,'2026_09_07_220000_create_support_threads_table',1),(30,'2026_09_07_220001_create_support_messages_table',1),(31,'2026_09_07_220002_create_order_refunds_table',1),(32,'2026_09_07_230000_add_last_staff_message_at_to_support_threads',1),(33,'2026_09_07_240000_add_is_rider_to_users_table',1),(34,'2026_09_07_240001_add_delivery_partner_to_orders_table',1),(35,'2026_09_07_250000_add_phone_to_users_table',1),(36,'2026_09_07_260000_create_banners_table',1),(37,'2026_09_07_270000_create_home_tiles_table',1),(38,'2026_09_07_280000_create_pages_table',1),(39,'2026_09_08_090000_add_placement_to_banners_table',1),(40,'2026_09_08_100000_add_compare_at_price_to_products_and_variants',1),(41,'2026_09_08_110000_add_compare_at_price_to_order_items_table',1),(42,'2026_09_08_120000_add_sections_to_pages_table',1),(43,'2026_09_08_130000_add_banner_image_to_pages_table',1),(44,'2026_09_08_140000_add_stripe_customer_id_to_users_table',1),(45,'2026_09_09_120000_create_store_inventory_table',2),(46,'2026_09_09_130000_add_store_id_to_orders_table',2),(47,'2026_09_09_140000_add_rider_profile_and_stores',2),(48,'2026_09_09_150000_drop_legacy_product_store_scope',2),(49,'2026_09_09_160000_add_delivery_confirmation_to_orders',3),(50,'2026_09_09_170000_create_rider_reviews_table',4),(51,'2026_09_09_180000_add_chat_rating_to_support_threads',5),(52,'2026_09_10_000000_add_delivery_offer_to_orders_table',6),(53,'2026_09_10_000001_add_rider_offer_counters_to_users_table',6),(54,'2026_09_10_010000_create_rider_attendance',7),(55,'2026_09_10_020000_add_rider_offers_count_to_users_table',8),(56,'2026_09_10_030000_add_rider_daily_target_to_users_table',9),(57,'2026_09_10_040000_add_rider_since_to_users_table',10),(58,'2026_09_10_050000_add_receipt_emailed_at_to_orders_table',11),(59,'2026_09_10_060000_create_gift_cards',12),(60,'2026_09_11_000000_add_cash_settled_at_to_orders_table',13),(61,'2026_09_11_010000_add_cash_collected_at_to_orders_table',14),(62,'2026_09_11_020000_add_reversed_at_to_gift_card_redemptions_table',15),(63,'2026_09_11_030000_add_cancellation_reason_to_orders_table',16),(64,'2026_09_11_040000_add_items_returned_at_to_orders_table',17),(65,'2026_09_11_050000_add_internal_to_support_messages_table',18),(66,'2026_09_14_000000_create_product_reviews_table',19),(67,'2026_09_14_010000_add_rating_and_sold_to_products_table',19),(68,'2026_09_14_020000_add_sold_counted_at_to_orders_table',19);
/*!40000 ALTER TABLE `migrations` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `order_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order_items` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) unsigned NOT NULL,
  `product_id` bigint(20) unsigned NOT NULL,
  `product_variant_id` bigint(20) unsigned DEFAULT NULL,
  `product_name` varchar(255) NOT NULL,
  `sku` varchar(255) NOT NULL,
  `variant_label` varchar(255) DEFAULT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `unit_price_cents` int(10) unsigned NOT NULL,
  `compare_at_price_cents` int(10) unsigned DEFAULT NULL,
  `line_total_cents` int(10) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `order_items_order_id_foreign` (`order_id`),
  KEY `order_items_product_id_foreign` (`product_id`),
  KEY `order_items_product_variant_id_foreign` (`product_variant_id`),
  CONSTRAINT `order_items_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `order_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `order_items_product_variant_id_foreign` FOREIGN KEY (`product_variant_id`) REFERENCES `product_variants` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `order_items` WRITE;
/*!40000 ALTER TABLE `order_items` DISABLE KEYS */;
INSERT INTO `order_items` VALUES (30,27,17,NULL,'Silicone Phone Case','GDP-PROD-017',NULL,1,1499,NULL,1499,'2026-09-14 06:14:06','2026-09-14 06:14:06');
/*!40000 ALTER TABLE `order_items` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `order_refunds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order_refunds` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) unsigned NOT NULL,
  `support_thread_id` bigint(20) unsigned DEFAULT NULL,
  `created_by` bigint(20) unsigned DEFAULT NULL,
  `amount_cents` int(10) unsigned NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `stripe_refund_id` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `order_refunds_order_id_foreign` (`order_id`),
  KEY `order_refunds_support_thread_id_foreign` (`support_thread_id`),
  KEY `order_refunds_created_by_foreign` (`created_by`),
  CONSTRAINT `order_refunds_created_by_foreign` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `order_refunds_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `order_refunds_support_thread_id_foreign` FOREIGN KEY (`support_thread_id`) REFERENCES `support_threads` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `order_refunds` WRITE;
/*!40000 ALTER TABLE `order_refunds` DISABLE KEYS */;
/*!40000 ALTER TABLE `order_refunds` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `orders` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `store_id` bigint(20) unsigned DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending_payment',
  `cancelled_by` varchar(20) DEFAULT NULL,
  `cancel_reason` varchar(300) DEFAULT NULL,
  `items_returned_at` timestamp NULL DEFAULT NULL,
  `delivered_at` timestamp NULL DEFAULT NULL,
  `cash_settled_at` timestamp NULL DEFAULT NULL,
  `cash_collected_at` timestamp NULL DEFAULT NULL,
  `receipt_emailed_at` timestamp NULL DEFAULT NULL,
  `sold_counted_at` timestamp NULL DEFAULT NULL,
  `delivery_verified` tinyint(1) DEFAULT NULL,
  `delivery_note` varchar(300) DEFAULT NULL,
  `delivery_code` varchar(8) DEFAULT NULL,
  `delivery_code_expires_at` timestamp NULL DEFAULT NULL,
  `courier_name` varchar(255) DEFAULT NULL,
  `delivery_partner_id` bigint(20) unsigned DEFAULT NULL,
  `rider_offer_expires_at` timestamp NULL DEFAULT NULL,
  `rider_accepted_at` timestamp NULL DEFAULT NULL,
  `rider_offer_declined_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`rider_offer_declined_ids`)),
  `rider_offer_decline_count` int(10) unsigned NOT NULL DEFAULT 0,
  `payment_status` varchar(255) NOT NULL DEFAULT 'pending',
  `payment_method` varchar(255) NOT NULL DEFAULT 'card',
  `stripe_payment_intent_id` varchar(255) DEFAULT NULL,
  `stripe_refund_id` varchar(255) DEFAULT NULL,
  `refunded_amount_cents` int(10) unsigned NOT NULL DEFAULT 0,
  `subtotal_cents` int(10) unsigned NOT NULL,
  `tax_cents` int(10) unsigned NOT NULL DEFAULT 0,
  `delivery_fee_cents` int(10) unsigned NOT NULL DEFAULT 0,
  `handling_fee_cents` int(10) unsigned NOT NULL DEFAULT 0,
  `small_cart_fee_cents` int(10) unsigned NOT NULL DEFAULT 0,
  `gift_card_discount_cents` int(10) unsigned NOT NULL DEFAULT 0,
  `total_cents` int(10) unsigned NOT NULL,
  `delivery_address` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`delivery_address`)),
  `delivery_instructions` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `orders_stripe_payment_intent_id_unique` (`stripe_payment_intent_id`),
  KEY `orders_user_id_foreign` (`user_id`),
  KEY `orders_status_index` (`status`),
  KEY `orders_payment_status_index` (`payment_status`),
  KEY `orders_payment_method_index` (`payment_method`),
  KEY `orders_delivery_partner_id_foreign` (`delivery_partner_id`),
  KEY `orders_store_id_foreign` (`store_id`),
  KEY `orders_rider_offer_expires_at_index` (`rider_offer_expires_at`),
  CONSTRAINT `orders_delivery_partner_id_foreign` FOREIGN KEY (`delivery_partner_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `orders_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE SET NULL,
  CONSTRAINT `orders_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES (27,17,1,'completed',NULL,NULL,NULL,'2026-09-14 06:27:52',NULL,'2026-09-14 06:27:39','2026-09-14 06:27:53',NULL,0,'delivered.',NULL,NULL,'Sam Rider',16,NULL,NULL,NULL,0,'paid','cod',NULL,NULL,0,1499,133,299,99,0,0,2030,'{\"id\":17,\"user_id\":17,\"label\":\"Home\",\"name\":\"Testcaresort\",\"line1\":\"34 Jan Marg\",\"line2\":null,\"city\":\"Mohali\",\"state\":\"PB\",\"postal_code\":\"160061\",\"latitude\":30.7149794,\"longitude\":76.7227993,\"is_default\":false,\"created_at\":\"2026-09-14T11:44:06.000000Z\",\"updated_at\":\"2026-09-14T11:44:06.000000Z\",\"phone\":\"+15551234567\"}',NULL,'2026-09-14 06:14:06','2026-09-14 06:27:53');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `pages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pages` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `slug` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `banner_image` varchar(255) DEFAULT NULL,
  `content` longtext DEFAULT NULL,
  `sections` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`sections`)),
  `is_published` tinyint(1) NOT NULL DEFAULT 1,
  `show_in_footer` tinyint(1) NOT NULL DEFAULT 1,
  `footer_group` varchar(255) NOT NULL DEFAULT 'useful_links',
  `sort_order` int(10) unsigned NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pages_slug_unique` (`slug`),
  KEY `pages_is_published_show_in_footer_sort_order_index` (`is_published`,`show_in_footer`,`sort_order`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `pages` WRITE;
/*!40000 ALTER TABLE `pages` DISABLE KEYS */;
INSERT INTO `pages` VALUES (1,'about','About Us',NULL,'NexTech delivers everyday groceries and household essentials to your door, fast.','[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/about-hero.jpg\",\"heading\":\"Groceries at your door in minutes\",\"text\":\"NexTech is a demo storefront for fast local grocery delivery \\u2014 fresh produce, pantry staples and household essentials, picked and delivered from a store near you.\",\"button_label\":\"Start shopping\",\"button_url\":\"#\\/\"},{\"type\":\"stats\",\"heading\":\"NexTech by the numbers\",\"items\":[{\"title\":\"~10 min\",\"text\":\"Average delivery time\"},{\"title\":\"20+\",\"text\":\"Categories in stock\"},{\"title\":\"4.8 \\/ 5\",\"text\":\"Average order rating\"},{\"title\":\"Every morning\",\"text\":\"Fresh restocks\"}]},{\"type\":\"feature_grid\",\"heading\":\"Why shop with us\",\"items\":[{\"title\":\"10-minute delivery\",\"text\":\"Orders leave the nearest store within minutes of checkout.\"},{\"title\":\"Real prices\",\"text\":\"Everyday low prices with discounts shown clearly \\u2014 no surprises at checkout.\"},{\"title\":\"Fresh every day\",\"text\":\"Produce and dairy are restocked each morning.\"},{\"title\":\"Easy returns\",\"text\":\"Raise an issue from your order history and get a fast refund.\"}]},{\"type\":\"steps\",\"heading\":\"How it works\",\"items\":[{\"title\":\"Fill your basket\",\"text\":\"Browse the aisles and add what you need. Prices and offers are shown upfront.\"},{\"title\":\"Check out in a tap\",\"text\":\"Pay by card or cash on delivery \\u2014 the fee and ETA are confirmed before you pay.\"},{\"title\":\"We pick and pack\",\"text\":\"Your order is assembled at the nearest store within minutes.\"},{\"title\":\"Delivered to your door\",\"text\":\"Track it on the way; hand over cash on arrival if you chose that.\"}]},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/about-story.jpg\",\"image_side\":\"left\",\"heading\":\"Our story\",\"markdown\":\"NexTech started as a single neighbourhood store and now runs a small network of local hubs.\\n\\nThis whole site is a **demo build** \\u2014 every page here, including this one, is editable in **Admin -> Pages** using drag-and-drop sections.\"},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/about-hero.jpg\",\"image_side\":\"right\",\"heading\":\"From local stores, not a warehouse\",\"markdown\":\"We stock and dispatch from small hubs inside your neighbourhood, so produce travels metres, not miles.\\n\\nShorter journeys mean fresher food, less packaging and a delivery rider who can be at your door before the kettle boils.\"},{\"type\":\"quote\",\"text\":\"I ordered eggs and coriander at 8pm and it was at my door before I had finished chopping the onions. Genuinely faster than walking to the corner shop.\",\"author\":\"Priya M. \\u2014 early tester\"},{\"type\":\"feature_grid\",\"heading\":\"On the roadmap\",\"items\":[{\"title\":\"Scheduled delivery\",\"text\":\"Pick a future time slot, not just \\u201cas soon as possible\\u201d.\"},{\"title\":\"More neighbourhoods\",\"text\":\"New store hubs opening across the city through the year.\"},{\"title\":\"Loyalty perks\",\"text\":\"Rewards and member pricing for regulars, coming soon.\"}]},{\"type\":\"cta\",\"heading\":\"Hungry already?\",\"text\":\"Browse thousands of items and check out in under a minute.\",\"button_label\":\"Shop now\",\"button_url\":\"#\\/\"}]',1,1,'company',1,'2026-09-09 01:12:49','2026-09-14 23:43:53'),(2,'blog','Blog',NULL,'Recipes, seasonal picks and a look behind the delivery promise.','[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"heading\":\"The NexTech Blog\",\"text\":\"Recipes, seasonal picks and a look behind the 10-minute delivery promise.\"},{\"type\":\"feature_grid\",\"heading\":\"Latest posts\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get groceries to you in 10 minutes\",\"text\":\"A look under the hood of the delivery promise \\u2014 from stocked hubs to planned routes.\",\"link_url\":\"#\\/p\\/blog-10-minute-delivery\"},{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 weeknight dinners in under 20 minutes\",\"text\":\"Five ingredients or fewer, on the table before the news finishes.\",\"link_url\":\"#\\/p\\/blog-weeknight-dinners\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"What\'s in season this month\",\"text\":\"The produce that is cheapest, freshest and best right now \\u2014 and how to use it.\",\"link_url\":\"#\\/p\\/blog-seasonal-produce\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 easy ways to waste less food\",\"text\":\"Small habits that cut your grocery bill and your bin at the same time.\",\"link_url\":\"#\\/p\\/blog-less-food-waste\"}]},{\"type\":\"stats\",\"heading\":\"The blog so far\",\"items\":[{\"title\":\"4\",\"text\":\"Posts published\"},{\"title\":\"~5 min\",\"text\":\"Average read\"},{\"title\":\"Weekly\",\"text\":\"New posts (soon)\"},{\"title\":\"0\",\"text\":\"Sponsored posts\"}]},{\"type\":\"feature_grid\",\"heading\":\"Browse by topic\",\"items\":[{\"title\":\"Recipes\",\"text\":\"Quick, real-food cooking with what is in the aisles this week.\"},{\"title\":\"Seasonal\",\"text\":\"What to buy now and why it tastes better.\"},{\"title\":\"Behind the scenes\",\"text\":\"How the store hubs, picking and routing actually work.\"},{\"title\":\"Sustainability\",\"text\":\"Less waste, less packaging, shorter journeys.\"}]},{\"type\":\"quote\",\"text\":\"Short, useful and no fluff \\u2014 I actually cooked two of the weeknight recipes the same evening I read them.\",\"author\":\"Alex R. \\u2014 newsletter subscriber\"},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"image_side\":\"right\",\"heading\":\"Write for us\",\"markdown\":\"Got a fast recipe, a market tip or a strong opinion about tinned tomatoes? We publish guest posts.\\n\\nEmail **hello@nextech.example** with a two-line pitch. This is a demo build, so treat these as sample posts you can replace in **Admin -> Pages**.\"},{\"type\":\"rich_text\",\"markdown\":\"**Editorial note** \\u2014 nothing here is sponsored. Product mentions are picked by the writer, and prices and availability shown in posts can change.\"},{\"type\":\"cta\",\"heading\":\"Get new posts by email\",\"text\":\"A subscribe box is coming soon \\u2014 for now, check back weekly for the next one.\"}]',1,1,'company',2,'2026-09-09 01:12:49','2026-09-14 23:43:53'),(3,'blog-fast-shipping','How we get your order shipped fast',NULL,'A look under the hood of the NexTech shipping promise.','[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"heading\":\"How we get your order shipped fast\",\"text\":\"From stocked local hubs to routes built for your address \\u2014 a look under the hood.\"},{\"type\":\"stats\",\"heading\":\"The promise in numbers\",\"items\":[{\"title\":\"Same day\",\"text\":\"Dispatch in serviceable areas\"},{\"title\":\"1\\u20133 days\",\"text\":\"Typical delivery window\"},{\"title\":\"Every unit\",\"text\":\"Scanned before it ships\"},{\"title\":\"Live tracking\",\"text\":\"Shown after checkout\"}]},{\"type\":\"rich_text\",\"markdown\":\"### It starts at a local hub, not one giant warehouse\\nInstead of a single depot on the edge of town, we stock small hubs closer to our customers, so your order doesn\'t have to travel far to start moving.\\n\\n### Careful packing\\nElectronics get extra padding and a tamper-evident seal. Fragile items like TVs and monitors are boxed and checked twice before they leave.\\n\\n### Planned routes\\nCouriers leave with a route built for your address, so the last mile doesn\'t eat the time we saved upstream.\\n\\n### What can slow it down\\nStock availability, distance from the nearest hub, or an address we can\'t place on the map. You\'ll always see an estimated delivery window before you pay.\"},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/about-story.jpg\",\"image_side\":\"left\",\"heading\":\"Why a hub beats a warehouse\",\"markdown\":\"A single warehouse on the edge of the city is efficient for trucks, not for you.\\n\\nOur hubs carry the products people actually reorder, closer to where you live \\u2014 less range on the shelf, far less distance to your door.\"},{\"type\":\"feature_grid\",\"heading\":\"What we optimise for\",\"items\":[{\"title\":\"Distance\",\"text\":\"Kilometres from hub to door, not the country.\"},{\"title\":\"Careful handling\",\"text\":\"Fragile electronics get extra padding, always.\"},{\"title\":\"Real tracking\",\"text\":\"A status you can trust, updated as it moves.\"},{\"title\":\"Route quality\",\"text\":\"Delivery windows built around your address.\"}]},{\"type\":\"steps\",\"heading\":\"From order to doorstep\",\"items\":[{\"title\":\"Order placed\",\"text\":\"Your order is checked for stock at the nearest hub.\"},{\"title\":\"Packed and sealed\",\"text\":\"A second person verifies every item before boxing.\"},{\"title\":\"Courier dispatched\",\"text\":\"With a route built for your address.\"},{\"title\":\"At your door\",\"text\":\"Same day where available, within a few days otherwise.\"}]},{\"type\":\"quote\",\"text\":\"I ordered a monitor in the morning and it was on my desk by evening, still sealed in the manufacturer\'s box.\",\"author\":\"Dan K. \\u2014 verified buyer\"},{\"type\":\"rich_text\",\"markdown\":\"### A few things people ask\\n**Can I add to an order after checkout?** Not once packing starts \\u2014 place a second order and we\'ll try to align delivery.\\n\\n**What if I\'m not in?** The courier attempts contact, then holds the parcel at a nearby point or arranges a retry.\\n\\n**Do you ship everywhere?** Only inside a serviceable area for now. Enter your address at checkout to check.\"},{\"type\":\"cta\",\"heading\":\"See your delivery window\",\"text\":\"Enter your address and add items to your cart to see an estimate.\",\"button_label\":\"Start shopping\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 easy home office upgrades under $50\",\"text\":\"Small buys that make working from home better.\",\"link_url\":\"#\\/p\\/blog-home-office-upgrades\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"The best time of year to buy tech\",\"text\":\"When prices actually drop, by category.\",\"link_url\":\"#\\/p\\/blog-seasonal-tech-deals\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 ways to cut down on e-waste\",\"text\":\"Get more life out of what you already own.\",\"link_url\":\"#\\/p\\/blog-reduce-ewaste\"}]}]',1,0,'blog',1,'2026-09-09 01:12:49','2026-09-14 06:33:33'),(4,'blog-home-office-upgrades','5 easy home office upgrades under $50',NULL,'Small, cheap upgrades that make working from home noticeably better.','[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"heading\":\"5 easy home office upgrades under $50\",\"text\":\"No big renovation needed \\u2014 five small buys that make a real difference.\"},{\"type\":\"rich_text\",\"markdown\":\"Keep a few basics on hand and any of these takes minutes to set up.\\n\\n1. **A laptop stand** \\u2014 raises your screen to eye level and frees up desk space underneath.\\n2. **A wireless mouse and keyboard** \\u2014 less cable clutter, more room to move.\\n3. **A USB-C hub** \\u2014 one cable in, everything else plugged in.\\n4. **A webcam with a physical shutter** \\u2014 sharper video calls, and privacy when you\'re not on one.\\n5. **A basic desk lamp** \\u2014 better lighting fixes video calls and eye strain in one move.\"},{\"type\":\"stats\",\"heading\":\"Why this is worth doing\",\"items\":[{\"title\":\"Under $50\",\"text\":\"Total for most of these\"},{\"title\":\"~10 min\",\"text\":\"Typical setup time\"},{\"title\":\"No tools\",\"text\":\"For most of them\"},{\"title\":\"0\",\"text\":\"Special skills needed\"}]},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"image_side\":\"right\",\"heading\":\"Start with what slows you down most\",\"markdown\":\"Not sure where to begin? Fix the thing that annoys you daily \\u2014 a cramped mouse, a low webcam angle, or reaching for a cable every morning.\\n\\nOne good upgrade beats five mediocre ones.\"},{\"type\":\"feature_grid\",\"heading\":\"Keep these on your list\",\"items\":[{\"title\":\"A spare charging cable\",\"text\":\"One for the bag, one for the desk.\"},{\"title\":\"A power strip with USB ports\",\"text\":\"Charge three things without hunting for an outlet.\"},{\"title\":\"A monitor arm\",\"text\":\"Frees up desk space and fixes your posture.\"},{\"title\":\"A pair of good headphones\",\"text\":\"Fewer distractions, clearer calls.\"}]},{\"type\":\"steps\",\"heading\":\"Upgrade one thing a week\",\"items\":[{\"title\":\"Look\",\"text\":\"Notice what you reach for or complain about daily.\"},{\"title\":\"Compare\",\"text\":\"Check reviews and prices before you buy.\"},{\"title\":\"Install\",\"text\":\"Most of these take under 10 minutes.\"}]},{\"type\":\"rich_text\",\"markdown\":\"### Make it last\\nA laptop stand and a hub are useful even if you change desks or jobs \\u2014 they\'re not tied to one setup.\"},{\"type\":\"quote\",\"text\":\"I didn\'t realise how much a $20 laptop stand would help my neck until I used one for a week.\",\"author\":\"Meera S.\"},{\"type\":\"cta\",\"heading\":\"Shop desk essentials\",\"text\":\"Add a few small upgrades to your next order.\",\"button_label\":\"Shop accessories\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get your order shipped fast\",\"text\":\"A look under the hood of our shipping promise.\",\"link_url\":\"#\\/p\\/blog-fast-shipping\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"The best time of year to buy tech\",\"text\":\"When prices actually drop, by category.\",\"link_url\":\"#\\/p\\/blog-seasonal-tech-deals\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 ways to cut down on e-waste\",\"text\":\"Get more life out of what you already own.\",\"link_url\":\"#\\/p\\/blog-reduce-ewaste\"}]}]',1,0,'blog',2,'2026-09-09 01:12:49','2026-09-14 06:33:33'),(5,'blog-seasonal-tech-deals','The best time of year to buy tech',NULL,'When prices actually drop, category by category.','[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"heading\":\"The best time of year to buy tech\",\"text\":\"Buy at the right time and the same product costs noticeably less.\"},{\"type\":\"rich_text\",\"markdown\":\"Prices on electronics move with release cycles and shopping seasons, not the weather \\u2014 but the pattern is just as predictable.\\n\\n### What to watch for\\nNew phone and laptop models usually launch in a similar window each year, which is exactly when last year\'s model gets discounted.\"},{\"type\":\"stats\",\"heading\":\"Why timing matters\",\"items\":[{\"title\":\"Lower\",\"text\":\"Price when a new model just launched\"},{\"title\":\"Shorter\",\"text\":\"Wait for open-box and clearance deals\"},{\"title\":\"Better\",\"text\":\"Availability right after a launch window\"},{\"title\":\"Less\",\"text\":\"Rush, if you buy ahead of season\"}]},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"image_side\":\"left\",\"heading\":\"Buy the outgoing model\",\"markdown\":\"The newest model rarely offers the best value \\u2014 the one it replaces usually does.\\n\\nCheck the spec difference before paying extra for \'new\'.\"},{\"type\":\"feature_grid\",\"heading\":\"A rough calendar\",\"items\":[{\"title\":\"Early in the year\",\"text\":\"Last year\'s TVs and laptops get discounted.\"},{\"title\":\"Mid-year\",\"text\":\"Back-to-school deals on laptops and tablets.\"},{\"title\":\"Autumn\",\"text\":\"New phone launches \\u2014 older models drop in price.\"},{\"title\":\"Late in the year\",\"text\":\"The year\'s biggest sales across every category.\"}]},{\"type\":\"feature_grid\",\"heading\":\"Three ways to buy smart\",\"items\":[{\"title\":\"Compare the spec sheet\",\"text\":\"A cheaper older model may outperform a newer budget one.\"},{\"title\":\"Set a price alert\",\"text\":\"Buy the moment it hits your number.\"},{\"title\":\"Check the return window\",\"text\":\"Know your options before you commit.\"}]},{\"type\":\"rich_text\",\"markdown\":\"### What about open-box and refurbished\\nOpen-box electronics are often unused returns at a lower price, still covered by warranty. Worth checking before paying full price for new.\"},{\"type\":\"quote\",\"text\":\"Waited three weeks for a sale and saved enough to buy a case and screen protector too.\",\"author\":\"Tomasz W.\"},{\"type\":\"cta\",\"heading\":\"Browse today\'s prices\",\"text\":\"See what\'s in stock and shop the current lineup.\",\"button_label\":\"Browse electronics\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get your order shipped fast\",\"text\":\"From stocked hubs to planned routes.\",\"link_url\":\"#\\/p\\/blog-fast-shipping\"},{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 easy home office upgrades under $50\",\"text\":\"Small buys, real difference.\",\"link_url\":\"#\\/p\\/blog-home-office-upgrades\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 ways to cut down on e-waste\",\"text\":\"Buy well, waste less.\",\"link_url\":\"#\\/p\\/blog-reduce-ewaste\"}]}]',1,0,'blog',3,'2026-09-09 01:12:49','2026-09-14 06:33:33'),(6,'blog-reduce-ewaste','7 ways to cut down on e-waste',NULL,'Small habits that keep your gadgets running longer and out of landfill.','[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"heading\":\"7 ways to cut down on e-waste\",\"text\":\"Small habits that keep your gadgets running longer and out of landfill.\"},{\"type\":\"rich_text\",\"markdown\":\"1. **Update before you replace.** A slow phone or laptop is often a software problem, not a hardware one.\\n2. **Replace the battery, not the device.** Many phones and laptops can have just the battery swapped.\\n3. **Use a proper case and screen protector.** The single biggest driver of early replacement is accidental damage.\\n4. **Recycle, don\'t bin.** Old electronics contain materials that shouldn\'t go to landfill \\u2014 most stores accept them for recycling.\\n5. **Sell or trade in what still works.** One person\'s outdated phone is still useful to someone else.\\n6. **Keep the original box and cables.** Makes resale or warranty claims far easier later.\\n7. **Buy for longevity.** A slightly more expensive product that lasts twice as long is the better deal.\"},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"image_side\":\"right\",\"heading\":\"Recycle, don\'t bin it\",\"markdown\":\"Dead batteries and old devices contain materials that shouldn\'t go into general waste.\\n\\nMost electronics retailers, including local hubs, accept old devices for proper recycling \\u2014 check before you throw anything out.\"},{\"type\":\"steps\",\"heading\":\"Before you replace anything\",\"items\":[{\"title\":\"Diagnose\",\"text\":\"Check if it\'s a software issue or a cheap fix first.\"},{\"title\":\"Repair or upgrade\",\"text\":\"A new battery or extra storage can add years.\"},{\"title\":\"Recycle or trade in\",\"text\":\"If it\'s beyond saving, dispose of it properly.\"}]},{\"type\":\"stats\",\"heading\":\"What e-waste actually costs\",\"items\":[{\"title\":\"Fastest-growing\",\"text\":\"Waste stream in the world\"},{\"title\":\"Most valuable\",\"text\":\"Materials often go unrecovered\"},{\"title\":\"A checkup\",\"text\":\"How often a device tune-up helps\"},{\"title\":\"Recycling\",\"text\":\"The thing that actually fixes it\"}]},{\"type\":\"feature_grid\",\"heading\":\"Make it last longer\",\"items\":[{\"title\":\"Keep it charged sensibly\",\"text\":\"Avoid always running at 0% or 100%.\"},{\"title\":\"Don\'t let it overheat\",\"text\":\"Heat is the biggest driver of battery wear.\"},{\"title\":\"Update software\",\"text\":\"Security and performance fixes, for free.\"},{\"title\":\"Protect the screen\",\"text\":\"Cheaper than a full replacement.\"}]},{\"type\":\"rich_text\",\"markdown\":\"### Trade in what you\'re not using\\nA drawer of old phones and chargers isn\'t doing anyone any good. Trading in or recycling them is better than letting them sit unused.\"},{\"type\":\"quote\",\"text\":\"Traded in my old laptop instead of leaving it in a drawer \\u2014 paid for half of the new one.\",\"author\":\"Priya M.\"},{\"type\":\"cta\",\"heading\":\"Ready for an upgrade?\",\"text\":\"Browse the latest devices and trade in your old one.\",\"button_label\":\"Shop now\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get your order shipped fast\",\"text\":\"Why fast, careful shipping matters.\",\"link_url\":\"#\\/p\\/blog-fast-shipping\"},{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 easy home office upgrades under $50\",\"text\":\"Use what you have, better.\",\"link_url\":\"#\\/p\\/blog-home-office-upgrades\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"The best time of year to buy tech\",\"text\":\"Buy well, waste less.\",\"link_url\":\"#\\/p\\/blog-seasonal-tech-deals\"}]}]',1,0,'blog',4,'2026-09-09 01:12:49','2026-09-14 06:33:33'),(7,'contact','Contact us','/img/pages/contact-banner.jpg','**For any query about an order, your account or the service, use the addresses and contact details below. For the fastest help with a specific order, open it in your account and tap \"Get help\" so it reaches the team with the order already attached.**\n\n## Registered office\n\nNexTech Retail Private Limited\n\n4th Floor, Market House, 12 Commerce Road\n\nCityville, State 100001, India\n\n## Corporate office\n\nNexTech Retail Private Limited\n\nTower B, Riverside Business Park, 88 Harbour Avenue\n\nMetro City, State 400001, India\n\n## Contact details\n\n**Customer support:** support@nextech.example — replies within a few hours, every day 8am to 10pm.\n\n**Phone:** +91 00000 00000 — for urgent delivery issues only.\n\n**Press and partnerships:** hello@nextech.example\n\n## Grievance Officer\n\nIn line with the Consumer Protection (E-Commerce) Rules, 2020, complaints can be sent to our Grievance Officer.\n\n**Name:** Grievance Officer, NexTech Retail Private Limited\n\n**Email:** grievance@nextech.example\n\n**Address:** 4th Floor, Market House, 12 Commerce Road, Cityville, State 100001, India\n\nWe acknowledge every complaint within 48 hours and aim to resolve it within one month of receipt.\n\n## Company details\n\n**Legal entity:** NexTech Retail Private Limited\n\n**CIN:** U00000XX2020PTC000000\n\n**GSTIN:** 00AAAAA0000A0Z0\n\n**Registered address:** 4th Floor, Market House, 12 Commerce Road, Cityville, State 100001, India\n\n---\n\n*This is placeholder contact information for a demo store. Replace the entity name, addresses, identifiers and officer details in Admin -> Pages before going live.*','[]',1,1,'company',3,'2026-09-09 01:12:49','2026-09-14 06:26:31'),(8,'faqs','FAQs',NULL,'Quick answers about delivery, payments and returns.','[{\"type\":\"hero\",\"heading\":\"Frequently asked questions\",\"text\":\"Answers about delivery, payments, refunds and your account. Tap a question to see the full answer.\"},{\"type\":\"faq\",\"heading\":\"Orders & delivery\",\"items\":[{\"title\":\"How long does delivery take?\",\"text\":\"Most orders arrive within the time window shown at checkout \\u2014 often around 10 minutes. Weather, a large basket or building access can add a little time, and your live ETA updates if anything changes.\"},{\"title\":\"Do you deliver to my area?\",\"text\":\"Enter your address on the home page. If we deliver there you can start shopping straight away; if not, we\'ll say so and note your interest for when we expand.\"},{\"title\":\"Is there a minimum order?\",\"text\":\"There is no strict minimum, but a very small basket may carry a small-cart fee, which is always shown before you pay. Larger orders often qualify for free delivery.\"},{\"title\":\"Can I add items after placing an order?\",\"text\":\"Not once picking has started. You can place a second order, and if it is within a few minutes we will try to send both together.\"},{\"title\":\"What if I am not home when the rider arrives?\",\"text\":\"The rider calls and waits a couple of minutes. If delivery cannot be completed, the order returns to the store and we refund it or arrange a retry.\"}]},{\"type\":\"faq\",\"heading\":\"Payments\",\"items\":[{\"title\":\"How can I pay?\",\"text\":\"By card through our payment provider, or by cash on delivery where that option is shown at checkout.\"},{\"title\":\"Is it safe to save my card?\",\"text\":\"Card details are handled by our PCI-compliant payment provider and are never stored on NexTech servers. We keep only a reference and the payment status.\"},{\"title\":\"When am I charged?\",\"text\":\"For card orders, at checkout. For cash on delivery, you pay the rider the full amount on hand-over.\"},{\"title\":\"My payment failed but money was deducted \\u2014 what now?\",\"text\":\"A failed-payment hold is usually released by your bank within a few working days. If no order was created, no purchase was made. Contact support with the order time if it does not clear.\"}]},{\"type\":\"faq\",\"heading\":\"Refunds & returns\",\"items\":[{\"title\":\"How do I report a missing or wrong item?\",\"text\":\"Open the order in your account and tap **Get help**. Tell us which items were affected; we review and, where appropriate, refund or replace them.\"},{\"title\":\"How long do refunds take?\",\"text\":\"Approved refunds go to your original payment method. Card refunds can take several working days to appear, depending on your bank. Cash-on-delivery refunds are made by a method we agree with you.\"},{\"title\":\"Can I return groceries I\'ve changed my mind about?\",\"text\":\"Perishable items generally cannot be returned once delivered. For unopened non-perishable items, contact support within a reasonable time.\"},{\"title\":\"Can I cancel an order?\",\"text\":\"Yes, until it leaves the store. After that, cancellation may not be possible \\u2014 contact support and we will help where we can.\"}]},{\"type\":\"faq\",\"heading\":\"Your account\",\"items\":[{\"title\":\"How do I sign in?\",\"text\":\"Use the email-code option, or set a password and sign in with your email and password. Staff accounts sign in on a separate admin page.\"},{\"title\":\"How do I change my address or phone number?\",\"text\":\"Edit them in your account. The details on an order that is already placed are frozen at the time you placed it.\"},{\"title\":\"How do I delete my account?\",\"text\":\"Contact support or email privacy@nextech.example. The Privacy Policy explains what happens to your data.\"},{\"title\":\"I am not getting order updates.\",\"text\":\"Check the email address on your account and your spam folder. You can always see live status on the order in your account.\"}]},{\"type\":\"cta\",\"heading\":\"Still need help?\",\"text\":\"Open the order in your account and tap \\u201cGet help\\u201d \\u2014 it reaches support with the order already attached.\"}]',1,1,'help',1,'2026-09-09 01:12:49','2026-09-14 23:43:53'),(9,'privacy','Privacy Policy',NULL,'NexTech Retail Private Limited (**\"NexTech\"**, **\"we\"**, **\"us\"** or **\"our\"**) is committed to protecting your privacy. This Privacy Policy explains what information we collect when you use the NexTech website and app (the **\"Platform\"**), how we use it, who we share it with, and the choices you have.\n\nBy using the Platform you agree to the practices described in this Policy. If you do not agree, please do not use the Platform.\n\n**Effective date:** this is a demo document — set a real date before going live.\n\n## 1. Information we collect\n\n### 1.1 Information you give us\n\n- **Account information** — your name, email address and phone number when you register or place an order.\n- **Delivery information** — the addresses you save, delivery instructions, and the contact number for a given order.\n- **Order information** — the items you buy, order value, and any issues or refunds you raise.\n- **Communications** — messages you send us through support chat or email.\n\n### 1.2 Information we collect automatically\n\n- **Device and usage data** — device type, browser, operating system, IP address, pages viewed and actions taken on the Platform.\n- **Approximate location** — derived from your address or, with your permission, your device, to check whether we deliver to you and to estimate delivery times.\n- **Cookies and similar technologies** — see Section 4.\n\n### 1.3 Information from third parties\n\n- **Payment status** from our payment processor. We never receive your full card number.\n- **Fraud and risk signals** from providers that help us keep accounts secure.\n\nWe do **not** knowingly collect sensitive personal data, and we ask that you do not send it to us.\n\n## 2. How we use your information\n\nWe use your information to:\n\n- create and manage your account;\n- process, pack and deliver your orders, and handle returns and refunds;\n- share the details a delivery rider needs — your name, address and phone — so your order can reach you;\n- provide customer support and respond to your queries;\n- detect, prevent and investigate fraud, abuse and security incidents;\n- improve the Platform, our range and our delivery operations;\n- send you service messages such as order updates and security notices; and\n- send you offers and updates **only if you have opted in**, which you can stop at any time.\n\n## 3. Payment information\n\nCard payments are processed by our third-party payment processor. Your card details are entered on their secure systems and are **not stored on NexTech servers**. We retain only a payment reference and the status of the transaction.\n\n## 4. Cookies and similar technologies\n\nWe use:\n\n- **Essential cookies and local storage** to keep you signed in and remember your cart and chosen location. The Platform does not work properly without these.\n- **Analytics** to understand which features are used so we can improve them.\n\nYou can clear or block cookies in your browser settings; some parts of the Platform may then stop working.\n\n## 5. How we share information\n\nWe share information only as described here:\n\n- **Delivery partners** — the name, address, phone number and order contents needed to deliver your order.\n- **Service providers** — payment processing, hosting, communications, mapping and analytics providers who process data on our instructions.\n- **Legal and safety** — where required by law, court order or a government request, or to protect the rights, property or safety of NexTech, our customers or the public.\n- **Business transfers** — if NexTech is involved in a merger, acquisition or sale of assets, your information may be transferred, subject to this Policy.\n\nWe do **not** sell your personal information.\n\n## 6. Data retention\n\nWe keep your information for as long as your account is active and for a reasonable period afterwards to meet legal, tax, accounting and dispute-resolution requirements. When it is no longer needed we delete or anonymise it.\n\n## 7. Your rights and choices\n\nDepending on where you live, you may have the right to:\n\n- **access** the personal information we hold about you;\n- **correct** information that is inaccurate — you can edit your profile and addresses in your account;\n- **delete** your account and associated personal information;\n- **object to or restrict** certain processing; and\n- **withdraw consent** for marketing at any time.\n\nTo exercise any of these, contact us using the details in Section 12. We may need to verify your identity before acting on a request.\n\n## 8. Security\n\nWe use technical and organisational measures to protect your information, including encryption in transit (HTTPS / TLS), access controls that limit staff and rider access to what they need, and revocable sign-in tokens. No method of transmission or storage is completely secure, so we cannot guarantee absolute security.\n\n## 9. Children\n\nThe Platform is not directed at children below the age required to form a binding contract where they live, and we do not knowingly collect their personal information. If you believe a child has provided us information, contact us and we will delete it.\n\n## 10. Third-party links\n\nThe Platform may link to third-party sites and services. We are not responsible for their privacy practices; please read their policies.\n\n## 11. International transfers\n\nYour information may be processed in countries other than the one you live in. Where we transfer information across borders, we use appropriate safeguards as required by applicable law.\n\n## 12. Grievance Officer and contact\n\nFor questions about this Policy or to exercise your rights, contact:\n\nGrievance Officer, NexTech Retail Private Limited\n\nEmail: privacy@nextech.example\n\nAddress: 4th Floor, Market House, 12 Commerce Road, Cityville, State 100001, India\n\nIn line with the Consumer Protection (E-Commerce) Rules, 2020, we acknowledge complaints within 48 hours and aim to resolve them within one month of receipt.\n\n## 13. Changes to this Policy\n\nWe may update this Policy from time to time. If we make material changes we will post the updated Policy on the Platform and, where appropriate, notify you. The **Effective date** above shows when it last changed.\n\n---\n\n*This is placeholder text for a demo store. Replace it with a privacy policy prepared and reviewed by your legal team, and set a real effective date, entity details and contact information in Admin -> Pages.*','[]',1,1,'legal',1,'2026-09-09 01:12:49','2026-09-14 06:21:56'),(10,'terms','Terms of Service',NULL,'These Terms of Service (**\"Terms\"**) govern your use of the NexTech website and app (the **\"Platform\"**), operated by NexTech Retail Private Limited (**\"NexTech\"**, **\"we\"**, **\"us\"** or **\"our\"**). By creating an account, placing an order or otherwise using the Platform, you agree to these Terms and to our Privacy Policy. If you do not agree, do not use the Platform.\n\n**Effective date:** this is a demo document — set a real date before going live.\n\n## 1. Eligibility and your account\n\n- You must be old enough to form a legally binding contract where you live, and not barred from receiving our services under applicable law.\n- You must provide accurate, current and complete account and delivery information, and keep it up to date.\n- You are responsible for activity that happens under your account and for keeping your sign-in credentials secure. Tell us promptly if you suspect unauthorised use.\n- We may refuse, suspend or close an account for a breach of these Terms, suspected fraud or abuse, or where required by law.\n\n## 2. The service\n\nThe Platform lets you order groceries and household items from a nearby store for delivery. Product range, images, pricing and delivery areas vary by location and change over time. Nothing on the Platform is an offer; your order is an offer to buy, which we accept when we confirm it.\n\n## 3. Orders, pricing and availability\n\n- Prices, taxes, delivery fees and any other charges are shown before you confirm an order. Totals are calculated and confirmed by our servers at checkout.\n- Product weights and pack sizes are approximate. Substitutions are only made with your agreement.\n- If an item is unavailable, mispriced or ordered in quantities we consider abnormal, we may cancel all or part of the order and refund the affected amount.\n- Promotional prices and offers are subject to their own terms and may be withdrawn at any time.\n\n## 4. Payment\n\n- You can pay by card through our third-party payment processor, or by cash on delivery where that option is shown.\n- Card details are entered on the payment processor\'s systems and are **not stored on NexTech servers**.\n- For cash-on-delivery orders, the full amount is due to the delivery rider on hand-over.\n- If a payment fails or is reversed, we may cancel the order or suspend your account until it is resolved.\n\n## 5. Delivery\n\n- We deliver only to addresses within a serviceable area. Enter your address on the Platform to check.\n- Delivery time estimates are indicative and may be affected by weather, traffic, demand or access to your building.\n- Someone must be available to receive the order at the address. If delivery cannot be completed after reasonable attempts, the order may be returned and a cancellation fee or a partial refund may apply.\n- Risk in the goods passes to you on delivery.\n\n## 6. Cancellations and refunds\n\n- You may cancel an order until it leaves the store. After that, cancellation may not be possible.\n- Approved refunds are made to your original payment method. Card refunds may take several business days to appear, depending on your bank.\n- For missing, damaged or incorrect items, raise an issue from your order history within a reasonable time so we can review and, where appropriate, refund or replace.\n\n## 7. Acceptable use\n\nYou agree not to:\n\n- use the Platform for any unlawful, fraudulent or harmful purpose;\n- interfere with or disrupt the Platform, its servers or networks, or attempt to gain unauthorised access;\n- scrape, copy or harvest data from the Platform except as expressly permitted;\n- resell products bought through the Platform, or place orders you do not intend to pay for or receive;\n- abuse promotions, referral schemes or the refund process; or\n- upload or transmit anything unlawful, defamatory, infringing or malicious.\n\n## 8. Intellectual property\n\nThe Platform, including its content, design, logos and software, is owned by NexTech or its licensors and is protected by intellectual-property laws. We grant you a limited, non-exclusive, non-transferable, revocable licence to use the Platform for its intended purpose. All other rights are reserved.\n\n## 9. User content\n\nIf you submit content — such as support messages, feedback or ratings — you grant us a non-exclusive, worldwide, royalty-free licence to use it to operate and improve the service. You are responsible for the content you submit and confirm you have the right to submit it.\n\n## 10. Third-party services\n\nThe Platform relies on and may link to third-party services (for example payments, mapping and messaging). Their terms and policies apply to your use of those services, and we are not responsible for them.\n\n## 11. Disclaimers\n\nThe Platform and all products and services are provided on an **\"as is\"** and **\"as available\"** basis. To the fullest extent permitted by law, we disclaim all warranties, express or implied, including merchantability, fitness for a particular purpose and non-infringement. We do not warrant that the Platform will be uninterrupted, error-free or secure.\n\n## 12. Limitation of liability\n\nTo the fullest extent permitted by law, NexTech and its officers, employees and partners will not be liable for any indirect, incidental, special, consequential or punitive damages, or for loss of profits, data or goodwill, arising from your use of the Platform. Our total liability for any claim relating to an order will not exceed the amount you paid for that order.\n\n## 13. Indemnity\n\nYou agree to indemnify and hold NexTech harmless from claims, losses and expenses (including reasonable legal fees) arising from your breach of these Terms or your misuse of the Platform.\n\n## 14. Suspension and termination\n\nWe may suspend or terminate your access to the Platform at any time for a breach of these Terms, suspected fraud or abuse, or where required by law. You may stop using the Platform and close your account at any time. Sections that by their nature should survive termination will do so.\n\n## 15. Changes to these Terms\n\nWe may update these Terms from time to time. Material changes will be posted on the Platform and, where appropriate, notified to you. Continued use of the Platform after changes take effect means you accept the updated Terms.\n\n## 16. Governing law and disputes\n\nThese Terms are governed by the laws of India, without regard to conflict-of-law rules. Subject to any mandatory consumer-protection rights you have where you live, the courts at Metro City, India will have jurisdiction over disputes arising from these Terms.\n\n## 17. Grievance Officer and contact\n\nFor complaints or questions about these Terms, contact:\n\nGrievance Officer, NexTech Retail Private Limited\n\nEmail: grievance@nextech.example\n\nAddress: 4th Floor, Market House, 12 Commerce Road, Cityville, State 100001, India\n\nIn line with the Consumer Protection (E-Commerce) Rules, 2020, we acknowledge complaints within 48 hours and aim to resolve them within one month of receipt.\n\n## 18. General\n\n- **Entire agreement** — these Terms and the Privacy Policy are the entire agreement between you and NexTech regarding the Platform.\n- **Severability** — if any provision is held unenforceable, the rest remains in effect.\n- **No waiver** — our failure to enforce a provision is not a waiver of it.\n- **Assignment** — you may not assign these Terms; we may assign them in connection with a merger, acquisition or sale of assets.\n- **Force majeure** — we are not liable for delays or failures caused by events beyond our reasonable control.\n\n---\n\n*This is placeholder text for a demo store. Replace it with terms of service prepared and reviewed by your legal team, and set a real effective date, entity details, governing law and contact information in Admin -> Pages.*','[]',1,1,'legal',2,'2026-09-09 01:12:49','2026-09-14 23:43:53'),(11,'security','Security','/img/pages/security-banner.jpg','NexTech Retail Private Limited (**\"NexTech\"**) takes the security of our customers and their data seriously. We value the work of security researchers and welcome reports of vulnerabilities in our website, app and infrastructure.\n\nThis page sets out how to report a security issue to us and what you can expect in return.\n\n**Effective date:** this is a demo document — set a real date before going live.\n\n## Our commitment\n\nIf you make a good-faith effort to comply with this policy during your research, we will:\n\n- work with you to understand and validate your report;\n- keep you informed of our progress towards a fix;\n- not pursue or support legal action against you for accidental, good-faith violations of this policy; and\n- credit you, with your permission, once the issue is resolved.\n\nActivities carried out in a manner consistent with this policy will be considered authorised conduct, and we will not treat them as a breach of our Terms of Service.\n\n## Guidelines\n\nPlease:\n\n- only test against accounts and data that you own or have explicit permission to use;\n- stop testing and report immediately if you encounter customer data, and do not access, modify, save, transfer or disclose it;\n- give us a reasonable time to investigate and fix an issue before disclosing it publicly, and coordinate any disclosure with us;\n- provide enough detail for us to reproduce the issue; and\n- make every effort to avoid privacy violations, data loss and service disruption.\n\nPlease do **not**:\n\n- run automated scanners against production, or any test that degrades or disrupts our services (including denial-of-service, brute force at volume, or spam);\n- use social engineering, phishing, or physical attempts against our staff, riders, offices or infrastructure;\n- attempt to access, download or exfiltrate data that is not yours;\n- publicly disclose a vulnerability before we have confirmed it is fixed; or\n- demand payment as a condition of disclosure.\n\n## In scope\n\n- Our customer website and web app\n- Our customer mobile apps\n- APIs that serve the above\n\n## Out of scope\n\nThe following generally do **not** qualify on their own, unless you can show a concrete, exploitable security impact:\n\n- Missing security headers, cookie flags, or best-practice hardening with no demonstrated exploit\n- Self-XSS, or issues requiring a fully compromised device or browser\n- Clickjacking on pages with no sensitive state-changing actions\n- Rate-limiting or brute-force concerns on non-authentication endpoints\n- Reports from automated tools without a working proof of concept\n- SPF / DKIM / DMARC configuration, or email spoofing of non-existent addresses\n- Outdated library versions with no proven vulnerability in our usage\n- Denial-of-service, resource-exhaustion, or volumetric findings\n- Social engineering, or physical security of our premises\n\n## How to report\n\nEmail **security@nextech.example** with:\n\n1. a clear description of the vulnerability and the affected URL, endpoint or app screen;\n2. step-by-step instructions to reproduce it;\n3. a proof of concept (script, request, screenshots or a short video); and\n4. your assessment of the impact and any suggested remediation.\n\nOne issue per report, please. If you need to share sensitive details, ask us for a secure channel.\n\n## What happens next\n\n- **Acknowledgement** — we aim to confirm receipt within 3 working days.\n- **Triage** — we validate the report and assign a severity, and will ask for more detail if needed.\n- **Fix** — remediation time depends on severity and complexity; we will keep you updated.\n- **Closure** — we let you know when the issue is resolved and confirm any credit.\n\n## Recognition\n\nWith your consent, we are happy to acknowledge researchers who report valid, previously unknown issues. NexTech does not currently run a paid bug-bounty programme; any reward is at our discretion.\n\n## Contact\n\nSecurity reports: **security@nextech.example**\n\nFor anything else, see the [Contact](/#/p/contact) page.\n\n---\n\n*This is placeholder text for a demo store. Replace it with a responsible-disclosure policy reviewed by your security and legal teams, and set real scope, contact details and an effective date in Admin -> Pages.*','[]',1,1,'legal',3,'2026-09-09 01:12:49','2026-09-14 06:18:24'),(12,'blog-10-minute-delivery','How we get groceries to you in 10 minutes',NULL,'A look under the hood of the NexTech delivery promise.','[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"heading\":\"How we get groceries to you in 10 minutes\",\"text\":\"From stocked neighbourhood hubs to routes built for your street \\u2014 a look under the hood.\"},{\"type\":\"stats\",\"heading\":\"The promise in numbers\",\"items\":[{\"title\":\"under 10 min\",\"text\":\"Typical door-to-door\"},{\"title\":\"3+\",\"text\":\"Pickers on one basket at peak\"},{\"title\":\"Every line\",\"text\":\"Scanned before it leaves\"},{\"title\":\"Live ETA\",\"text\":\"Shown before you pay\"}]},{\"type\":\"rich_text\",\"markdown\":\"### It starts with the store, not a warehouse\\nInstead of one big depot on the edge of town, we run small stocked hubs inside neighbourhoods. When your order lands, the picker is already a few metres from the shelf.\\n\\n### Picking in parallel\\nThe moment you check out, your list is split across the aisles so several people pack it at once. Chilled and frozen items are grabbed last so they stay cold.\\n\\n### Short, planned routes\\nRiders leave with a route that already accounts for one-way streets and building access, so the last hundred metres don\'t eat the time we just saved.\\n\\n### What can slow it down\\nHeavy weather, a very large basket, or an address we can\'t place on the map. You\'ll always see a live ETA before you pay, and it updates if something changes.\"},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/about-story.jpg\",\"image_side\":\"left\",\"heading\":\"Why a hub beats a warehouse\",\"markdown\":\"A warehouse on the ring road is efficient for lorries, not for you.\\n\\nOur hubs carry a tighter range \\u2014 the few thousand things people actually reorder \\u2014 a short walk from where you live. Less range on the shelf, far less distance to your door.\"},{\"type\":\"feature_grid\",\"heading\":\"What we optimise for\",\"items\":[{\"title\":\"Distance\",\"text\":\"Metres from shelf to door, not miles.\"},{\"title\":\"Parallel picking\",\"text\":\"Several people pack one order at once.\"},{\"title\":\"Cold chain\",\"text\":\"Chilled and frozen items are grabbed last.\"},{\"title\":\"Route quality\",\"text\":\"One-way streets and door access, solved before the rider leaves.\"}]},{\"type\":\"steps\",\"heading\":\"The ten minutes, step by step\",\"items\":[{\"title\":\"0:00 \\u2014 Order placed\",\"text\":\"Your list appears on the hub\'s screen and is split by aisle.\"},{\"title\":\"0:30 \\u2014 Picking starts\",\"text\":\"Several pickers work in parallel; chilled items come last.\"},{\"title\":\"3:00 \\u2014 Packed and checked\",\"text\":\"A second person scans every line against your order.\"},{\"title\":\"4:00 \\u2014 Rider dispatched\",\"text\":\"With a route built for your street, not just your postcode.\"},{\"title\":\"~10:00 \\u2014 At your door\",\"text\":\"Hand over cash now if you chose cash on delivery.\"}]},{\"type\":\"quote\",\"text\":\"The rider messaged when he was outside and waited while I found change. Felt like a neighbour dropping something round, not a courier.\",\"author\":\"Dan K. \\u2014 Camberwell\"},{\"type\":\"rich_text\",\"markdown\":\"### A few things people ask\\n**Can I add to an order after checkout?** Not once picking starts \\u2014 but you can place a second order, and if it\'s within a few minutes we try to send them out together.\\n\\n**What if I\'m not in?** The rider calls, then waits a couple of minutes. Undelivered orders come back to the hub and we refund or retry.\\n\\n**Do you deliver everywhere?** Only inside a hub\'s range for now. Enter your address on the home page to check.\"},{\"type\":\"cta\",\"heading\":\"See how fast it lands for you\",\"text\":\"Enter your address and add a few items to get a live ETA.\",\"button_label\":\"Start shopping\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 weeknight dinners in under 20 minutes\",\"text\":\"Five ingredients or fewer, on the table fast.\",\"link_url\":\"#\\/p\\/blog-weeknight-dinners\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"What\'s in season this month\",\"text\":\"Cheaper, fresher, and it tastes better.\",\"link_url\":\"#\\/p\\/blog-seasonal-produce\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 easy ways to waste less food\",\"text\":\"Cut your bill and your bin at once.\",\"link_url\":\"#\\/p\\/blog-less-food-waste\"}]}]',1,0,'blog',1,'2026-09-14 23:43:53','2026-09-14 23:43:53'),(13,'blog-weeknight-dinners','5 weeknight dinners in under 20 minutes',NULL,'Five ingredients or fewer, on the table before the news finishes.','[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"heading\":\"5 weeknight dinners in under 20 minutes\",\"text\":\"Five ingredients or fewer, minimal washing up, on the table fast.\"},{\"type\":\"rich_text\",\"markdown\":\"Keep a few basics in and any of these comes together in the time it takes rice to cook.\\n\\n1. **Garlic butter pasta** \\u2014 pasta, butter, garlic, parmesan, black pepper. Reserve a little pasta water to bring it together.\\n2. **Chickpea & spinach curry** \\u2014 tinned chickpeas, curry paste, coconut milk, spinach. Simmer 10 minutes, serve with rice or bread.\\n3. **Egg fried rice** \\u2014 cold cooked rice, eggs, spring onion, soy, frozen peas. High heat, keep it moving.\\n4. **Halloumi & tomato traybake** \\u2014 halloumi, cherry tomatoes, olive oil, oregano. 15 minutes at 220\\u00b0C.\\n5. **Tuna & white bean salad** \\u2014 tinned tuna, cannellini beans, red onion, lemon, olive oil. No cooking at all.\"},{\"type\":\"stats\",\"heading\":\"Why this works on a weeknight\",\"items\":[{\"title\":\"5 or fewer\",\"text\":\"Ingredients per recipe\"},{\"title\":\"~15 min\",\"text\":\"Hands-on time\"},{\"title\":\"1 pan\",\"text\":\"For most of them\"},{\"title\":\"0\",\"text\":\"Special equipment\"}]},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"image_side\":\"right\",\"heading\":\"Swap with the seasons\",\"markdown\":\"Every recipe above takes a swap. Spinach becomes chard or kale. Cherry tomatoes become any tomato, halved. Chickpeas become butter beans.\\n\\nCook whatever is cheap and good that week and the method still works.\"},{\"type\":\"feature_grid\",\"heading\":\"Keep these in the cupboard\",\"items\":[{\"title\":\"Dried pasta & rice\",\"text\":\"The base of three of the five above.\"},{\"title\":\"Tinned beans & tomatoes\",\"text\":\"Instant protein and a sauce in one tin.\"},{\"title\":\"Coconut milk & curry paste\",\"text\":\"A 10-minute curry any night.\"},{\"title\":\"Olive oil, garlic, lemon\",\"text\":\"Turns plain ingredients into a meal.\"}]},{\"type\":\"steps\",\"heading\":\"Get faster every week\",\"items\":[{\"title\":\"Prep in batches\",\"text\":\"Chop onion and garlic for two nights at a time.\"},{\"title\":\"Cook rice ahead\",\"text\":\"Cold rice is better for fried rice anyway.\"},{\"title\":\"Always double it\",\"text\":\"Tomorrow\'s lunch, sorted.\"}]},{\"type\":\"rich_text\",\"markdown\":\"### Make it a meal\\nRound any of these out with a bag of salad, some bread, or a piece of fruit. None of them need a starter.\"},{\"type\":\"quote\",\"text\":\"I stopped ordering takeaway on Tuesdays. The chickpea curry is genuinely faster than opening the app.\",\"author\":\"Meera S.\"},{\"type\":\"cta\",\"heading\":\"Stock the basics\",\"text\":\"Add the cupboard staples to your next order in a couple of taps.\",\"button_label\":\"Shop staples\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get groceries to you in 10 minutes\",\"text\":\"A look under the hood of the delivery promise.\",\"link_url\":\"#\\/p\\/blog-10-minute-delivery\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"What\'s in season this month\",\"text\":\"The produce worth buying right now.\",\"link_url\":\"#\\/p\\/blog-seasonal-produce\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 easy ways to waste less food\",\"text\":\"Small habits, smaller bin.\",\"link_url\":\"#\\/p\\/blog-less-food-waste\"}]}]',1,0,'blog',2,'2026-09-14 23:43:53','2026-09-14 23:43:53'),(14,'blog-seasonal-produce','What\'s in season this month',NULL,'The produce that is cheapest, freshest and best right now.','[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"heading\":\"What\'s in season this month\",\"text\":\"Buy with the seasons: cheaper, fresher, and it simply tastes better.\"},{\"type\":\"rich_text\",\"markdown\":\"Produce that\'s in season hasn\'t travelled far or sat in storage, so it costs less and tastes more like itself.\\n\\n### Vegetables to reach for\\nLeafy greens, carrots, beetroot, cabbage, leeks and squash are all at their best and their cheapest.\\n\\n### Fruit worth buying\\nApples, pears and citrus are crisp and well priced. Berries are better frozen this time of year.\"},{\"type\":\"stats\",\"heading\":\"Why buy in season\",\"items\":[{\"title\":\"Lower\",\"text\":\"Price when supply is high\"},{\"title\":\"Shorter\",\"text\":\"Time from field to shelf\"},{\"title\":\"Better\",\"text\":\"Flavour and texture\"},{\"title\":\"Less\",\"text\":\"Packaging and cold storage\"}]},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"image_side\":\"left\",\"heading\":\"Cook it simply\",\"markdown\":\"In-season produce doesn\'t need much done to it. Roast it, dress it with lemon and oil, or drop it in a soup.\\n\\nThe less you do, the more it tastes of itself.\"},{\"type\":\"feature_grid\",\"heading\":\"A rough month-by-month\",\"items\":[{\"title\":\"Late winter\",\"text\":\"Citrus, leeks, cabbage, stored apples.\"},{\"title\":\"Spring\",\"text\":\"Asparagus, spring greens, new potatoes, rhubarb.\"},{\"title\":\"Summer\",\"text\":\"Tomatoes, courgettes, berries, stone fruit.\"},{\"title\":\"Autumn\",\"text\":\"Squash, mushrooms, pears, root veg.\"}]},{\"type\":\"feature_grid\",\"heading\":\"Three ways to use a glut\",\"items\":[{\"title\":\"Roast a tray\",\"text\":\"Any root veg, olive oil, salt, 30 minutes. Eats hot or cold all week.\"},{\"title\":\"Make a soup base\",\"text\":\"Onion, carrot, celery, stock. Freezes in portions.\"},{\"title\":\"Quick pickle\",\"text\":\"Vinegar, sugar, salt over sliced veg. Ready by dinner.\"}]},{\"type\":\"rich_text\",\"markdown\":\"### What about frozen and tinned\\nFrozen peas, spinach, berries and sweetcorn are picked and frozen at their peak \\u2014 often better than \\\"fresh\\\" that has travelled a week. Tinned tomatoes and beans are pantry gold.\"},{\"type\":\"quote\",\"text\":\"Started shopping the \'in season\' shelf and my veg bill dropped without me trying.\",\"author\":\"Tomasz W.\"},{\"type\":\"cta\",\"heading\":\"Shop fresh produce\",\"text\":\"See what your nearest store has in today.\",\"button_label\":\"Browse produce\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get groceries to you in 10 minutes\",\"text\":\"From stocked hubs to planned routes.\",\"link_url\":\"#\\/p\\/blog-10-minute-delivery\"},{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 weeknight dinners in under 20 minutes\",\"text\":\"Fast, cheap, five ingredients.\",\"link_url\":\"#\\/p\\/blog-weeknight-dinners\"},{\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"title\":\"7 easy ways to waste less food\",\"text\":\"Buy less, bin less.\",\"link_url\":\"#\\/p\\/blog-less-food-waste\"}]}]',1,0,'blog',3,'2026-09-14 23:43:53','2026-09-14 23:43:53'),(15,'blog-less-food-waste','7 easy ways to waste less food',NULL,'Small habits that cut your grocery bill and your bin at the same time.','[{\"type\":\"hero\",\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"heading\":\"7 easy ways to waste less food\",\"text\":\"Small habits that cut your grocery bill and your bin at the same time.\"},{\"type\":\"rich_text\",\"markdown\":\"1. **Shop your fridge first.** Plan two meals around what\'s already there before you order.\\n2. **Order little and often.** Fast delivery means you don\'t need to over-buy fresh food.\\n3. **Learn the labels.** \\\"Best before\\\" is about quality; \\\"use by\\\" is about safety.\\n4. **Store it right.** Herbs in water, potatoes in the dark, bread in the freezer.\\n5. **Cook once, eat twice.** Make a bit extra and label it for later.\\n6. **Keep a \\\"use me first\\\" shelf.** One spot in the fridge for things on the edge.\\n7. **Freeze the odds and ends.** Overripe fruit for smoothies, veg scraps for stock.\"},{\"type\":\"media_text\",\"image_url\":\"\\/img\\/pages\\/blog-waste.jpg\",\"image_side\":\"right\",\"heading\":\"The \'use me first\' shelf\",\"markdown\":\"Pick one shelf in the fridge \\u2014 eye level is best \\u2014 for anything close to the edge.\\n\\nEveryone in the house checks it before opening a new pack. It\'s the single habit that moves the needle most.\"},{\"type\":\"steps\",\"heading\":\"A two-minute weekly reset\",\"items\":[{\"title\":\"Look\",\"text\":\"Scan the fridge and note what needs using.\"},{\"title\":\"Plan\",\"text\":\"Pin two meals to those items.\"},{\"title\":\"Top up\",\"text\":\"Order only the gaps.\"}]},{\"type\":\"stats\",\"heading\":\"What waste actually costs\",\"items\":[{\"title\":\"~1 in 5\",\"text\":\"Bags of shopping binned, on average\"},{\"title\":\"Fresh food\",\"text\":\"The category wasted most\"},{\"title\":\"A month\",\"text\":\"How often a full reset helps\"},{\"title\":\"Planning\",\"text\":\"The thing that fixes it\"}]},{\"type\":\"feature_grid\",\"heading\":\"Store it so it lasts\",\"items\":[{\"title\":\"Herbs\",\"text\":\"Stems in a glass of water, a loose bag over the top.\"},{\"title\":\"Bread\",\"text\":\"Freeze half the loaf the day you get it.\"},{\"title\":\"Potatoes & onions\",\"text\":\"Cool, dark, and not right next to each other.\"},{\"title\":\"Leafy greens\",\"text\":\"Wrapped in a dry cloth, not left soaking.\"}]},{\"type\":\"rich_text\",\"markdown\":\"### Cook the scraps\\nVegetable ends and herb stalks go in a stock bag in the freezer. Overripe bananas get peeled and frozen for smoothies or bread. Stale bread becomes croutons or breadcrumbs.\"},{\"type\":\"quote\",\"text\":\"Ordering smaller amounts more often was the fix. I don\'t buy a week of salad and watch half of it wilt any more.\",\"author\":\"Priya M.\"},{\"type\":\"cta\",\"heading\":\"Plan this week\",\"text\":\"Build a short list around what you already have.\",\"button_label\":\"Start a list\",\"button_url\":\"#\\/\"},{\"type\":\"feature_grid\",\"heading\":\"Keep reading\",\"items\":[{\"image_url\":\"\\/img\\/pages\\/blog-delivery.jpg\",\"title\":\"How we get groceries to you in 10 minutes\",\"text\":\"Why fast delivery means buying less.\",\"link_url\":\"#\\/p\\/blog-10-minute-delivery\"},{\"image_url\":\"\\/img\\/pages\\/blog-dinner.jpg\",\"title\":\"5 weeknight dinners in under 20 minutes\",\"text\":\"Use what you have, fast.\",\"link_url\":\"#\\/p\\/blog-weeknight-dinners\"},{\"image_url\":\"\\/img\\/pages\\/blog-seasonal.jpg\",\"title\":\"What\'s in season this month\",\"text\":\"Buy well, waste less.\",\"link_url\":\"#\\/p\\/blog-seasonal-produce\"}]}]',1,0,'blog',4,'2026-09-14 23:43:53','2026-09-14 23:43:53');
/*!40000 ALTER TABLE `pages` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `password_reset_tokens` WRITE;
/*!40000 ALTER TABLE `password_reset_tokens` DISABLE KEYS */;
/*!40000 ALTER TABLE `password_reset_tokens` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `personal_access_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) unsigned NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=187 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `personal_access_tokens` WRITE;
/*!40000 ALTER TABLE `personal_access_tokens` DISABLE KEYS */;
INSERT INTO `personal_access_tokens` VALUES (7,'App\\Models\\User',17,'customer','456796337ac1d836c1154146175b25528d58aa7869bfca580ba29b1ab373a31f','[\"*\"]','2026-09-09 02:28:52',NULL,'2026-09-09 02:25:33','2026-09-09 02:28:52'),(10,'App\\Models\\User',16,'customer','8fdc9fbafcf3cc942fa134edea164a87468fca875fef8adbfae8365b4d8b5978','[\"*\"]','2026-09-09 02:32:40',NULL,'2026-09-09 02:30:45','2026-09-09 02:32:40'),(13,'App\\Models\\User',16,'customer','523f28e36ce4c3be8307320ea60a0c0841c1fc7e81651b87ec1e01981c665d10','[\"*\"]','2026-09-09 02:39:14',NULL,'2026-09-09 02:34:07','2026-09-09 02:39:14'),(23,'App\\Models\\User',16,'customer','08d1476873ee76edd238f947b8a6bdbd95cb51de55064f6b7d3c3bc320b861f5','[\"*\"]','2026-09-09 04:49:30',NULL,'2026-09-09 04:49:14','2026-09-09 04:49:30'),(24,'App\\Models\\User',17,'customer','6e1418b75405dd71aa8656e2f5be0a721a725fe04e35b439acb002c868e89d16','[\"*\"]',NULL,NULL,'2026-09-09 04:49:42','2026-09-09 04:49:42'),(26,'App\\Models\\User',16,'customer','c3b22b30312f4efc2bb46da67896d60c0d98db74594c81755f414c6ad747ac4a','[\"*\"]','2026-09-09 04:50:17',NULL,'2026-09-09 04:50:11','2026-09-09 04:50:17'),(30,'App\\Models\\User',16,'customer','eb7d0f829f0baef7af1b3bce1329714c8ee8a291d5505cd0beb45b5c0ffd7832','[\"*\"]','2026-09-09 05:00:53',NULL,'2026-09-09 05:00:19','2026-09-09 05:00:53'),(31,'App\\Models\\User',17,'customer','89f81e8cded777c546d7c26df2bc9dbfc01377b9cd6cf375ee8b5bae8706f96e','[\"*\"]',NULL,NULL,'2026-09-09 05:01:05','2026-09-09 05:01:05'),(33,'App\\Models\\User',16,'customer','b764b4d49406f5204ebe19b541f51eb693911e74fc35417979818a55fd025eb6','[\"*\"]','2026-09-09 05:02:15',NULL,'2026-09-09 05:01:27','2026-09-09 05:02:15'),(34,'App\\Models\\User',17,'customer','a85cabe67ba928751616ade687760bd7ab810ded65534a0187eba48c74805962','[\"*\"]',NULL,NULL,'2026-09-09 05:02:22','2026-09-09 05:02:22'),(43,'App\\Models\\User',16,'customer','7ad55327f05f20fe77067321d1627f177278d02d0976f8944b107220872de1d3','[\"*\"]','2026-09-09 05:36:35',NULL,'2026-09-09 05:36:30','2026-09-09 05:36:35'),(44,'App\\Models\\User',16,'customer','2ddb9ca2b6232a706c01fbd5889d70ba430949dbe50242e19a0707f8b6738849','[\"*\"]','2026-09-09 05:36:49',NULL,'2026-09-09 05:36:47','2026-09-09 05:36:49'),(48,'App\\Models\\User',16,'customer','3eeb808a865e69b6cb6606baa5c837fafee6026fdb3fd8d66936ec5f7394f76e','[\"*\"]','2026-09-10 01:32:05',NULL,'2026-09-09 23:53:46','2026-09-10 01:32:05'),(56,'App\\Models\\User',16,'customer','25c1e76dcd9646cb4ec576b2f05b236b123b29c2491883a2fc3687de12cd8221','[\"*\"]',NULL,NULL,'2026-09-10 01:40:03','2026-09-10 01:40:03'),(57,'App\\Models\\User',16,'customer','c024a66028f7068a0192df8846972f4d3e2b6bd6cf55c2044f696ec73b6bef82','[\"*\"]','2026-09-10 01:47:05',NULL,'2026-09-10 01:40:06','2026-09-10 01:47:05'),(61,'App\\Models\\User',16,'customer','913d24db963de2f035d6f88eaf4b32f5a783a70d1baf3079f8f69e384790e01e','[\"*\"]','2026-09-10 02:23:07',NULL,'2026-09-10 02:07:17','2026-09-10 02:23:07'),(63,'App\\Models\\User',28,'t','a0914c64b2715efee575f5f543d386913db4a51773e1fc2a0095741c874ebd8d','[\"*\"]','2026-09-11 00:00:49',NULL,'2026-09-10 02:14:06','2026-09-11 00:00:49'),(64,'App\\Models\\User',16,'customer','745b98f4daf38ac279fa60f0e4c8c97433ea6a114ea4d26becd73d86c00e0371','[\"*\"]','2026-09-10 03:06:03',NULL,'2026-09-10 02:50:37','2026-09-10 03:06:03'),(66,'App\\Models\\User',16,'customer','043eb6ea1f031d73e37ef0f345474d24dd07b9967c131228a207d2a7834dad83','[\"*\"]','2026-09-10 04:15:09',NULL,'2026-09-10 04:14:38','2026-09-10 04:15:09'),(69,'App\\Models\\User',16,'customer','f9bf02190ff06ae73e68cd40c37b4b3511d3e05e52cebde48dce0a5fe1280c7d','[\"*\"]','2026-09-10 05:14:13',NULL,'2026-09-10 05:08:28','2026-09-10 05:14:13'),(70,'App\\Models\\User',17,'customer','6781b764e032a764801929595cda7fe6b1de45a6fdcfd773b7281db970318bdf','[\"*\"]','2026-09-10 05:32:21',NULL,'2026-09-10 05:14:33','2026-09-10 05:32:21'),(74,'App\\Models\\User',17,'customer','48ba6cefda5815400870c6b205e3c7ac07d4738b4300694a190e4a971ca22219','[\"*\"]',NULL,NULL,'2026-09-10 06:13:59','2026-09-10 06:13:59'),(75,'App\\Models\\User',16,'customer','e445f8bbbb737c10ab372c11b9ceea0b67f349c956b29925ae7a8b29449fad06','[\"*\"]','2026-09-10 07:15:25',NULL,'2026-09-10 06:14:05','2026-09-10 07:15:25'),(77,'App\\Models\\User',17,'customer','3b46ad6af609da2ae084e17ee249ecc7b34a998898e44c3e7eac5f9e5bd7a766','[\"*\"]','2026-09-10 07:26:23',NULL,'2026-09-10 07:25:36','2026-09-10 07:26:23'),(79,'App\\Models\\User',16,'customer','14bbf59e5a3bd59f7ffd4518e6bb28d5567757cef76b0f6da9cd72ef28e188d6','[\"*\"]','2026-09-10 07:53:04',NULL,'2026-09-10 07:29:09','2026-09-10 07:53:04'),(81,'App\\Models\\User',17,'customer','4ce885de3957ceefec8c484e45cffe46d17dc8923275c67436224c90894787f9','[\"*\"]','2026-09-10 07:40:28',NULL,'2026-09-10 07:39:58','2026-09-10 07:40:28'),(86,'App\\Models\\User',17,'customer','4ef3282f50af047c24856987211ec5b6563303c8a51df8d3f25a7059119683ee','[\"*\"]','2026-09-10 23:58:11',NULL,'2026-09-10 23:57:11','2026-09-10 23:58:11'),(89,'App\\Models\\User',17,'customer','70a866475fb4be8b8fece1cd52c7a6768ae0aa38eab4336f0b6a4d7f32047cb5','[\"*\"]','2026-09-11 00:01:09',NULL,'2026-09-11 00:00:50','2026-09-11 00:01:09'),(91,'App\\Models\\User',15,'cdp-test','9a6753fc632d81e03bbbe33c7f79ab8556101bd342652ea4454b8a052209ef8c','[\"*\"]','2026-09-11 01:03:24',NULL,'2026-09-11 00:01:28','2026-09-11 01:03:24'),(93,'App\\Models\\User',17,'customer','8c0723fd185e590338f35e2fb5fa9b515c6ed663c8ee8e634b2d796ed6561a04','[\"*\"]','2026-09-11 00:04:15',NULL,'2026-09-11 00:03:50','2026-09-11 00:04:15'),(94,'App\\Models\\User',15,'customer','ced97e5f86752945d3cf2a6f7cab604bb3df0f09ff435bc514d2b9dbb866a442','[\"*\"]','2026-09-11 00:09:08',NULL,'2026-09-11 00:04:17','2026-09-11 00:09:08'),(95,'App\\Models\\User',16,'customer','31bd5b2dc28798a67ff91b05d67a988b76248597314026e893c02e77dc1741d3','[\"*\"]','2026-09-11 00:23:39',NULL,'2026-09-11 00:07:52','2026-09-11 00:23:39'),(99,'App\\Models\\User',17,'customer','74f468f217836aa5ae7cf4bf06aaade258fc5fe66f040308c03f9ca5bf7651c2','[\"*\"]','2026-09-11 00:19:10',NULL,'2026-09-11 00:15:16','2026-09-11 00:19:10'),(103,'App\\Models\\User',16,'customer','f0f419a7af19499b254a6d064e96a2f769629def420cd7f67d76dec45867da34','[\"*\"]','2026-09-11 00:26:54',NULL,'2026-09-11 00:26:23','2026-09-11 00:26:54'),(107,'App\\Models\\User',17,'customer','553e227fbd8943e6266c23fb7d38f54c06c6072f9a5a479af80cd5ae7f47e38a','[\"*\"]','2026-09-11 02:18:07',NULL,'2026-09-11 01:47:55','2026-09-11 02:18:07'),(108,'App\\Models\\User',17,'cdp-test','4861f17f8d77f978099d49c169f4dbf730fb157c5f8009a9f231b794ba434ea0','[\"*\"]','2026-09-11 02:03:23',NULL,'2026-09-11 01:56:17','2026-09-11 02:03:23'),(110,'App\\Models\\User',16,'customer','28888caeb76891d5d7b53b16d8184395faeee8b54dc683c305be55af0f737b28','[\"*\"]','2026-09-11 02:23:04',NULL,'2026-09-11 02:18:41','2026-09-11 02:23:04'),(111,'App\\Models\\User',15,'customer','4b607b116b97ef0c25a7650680587854bfc0477d2ca21681246502551696789d','[\"*\"]','2026-09-11 02:25:33',NULL,'2026-09-11 02:21:45','2026-09-11 02:25:33'),(112,'App\\Models\\User',16,'customer','22f58c89c896972fe00965585c56655a2a67fde5403e6f4728f27940cff4e774','[\"*\"]','2026-09-11 02:26:07',NULL,'2026-09-11 02:23:13','2026-09-11 02:26:07'),(113,'App\\Models\\User',15,'customer','9fff924bfddd58c2c408d048224c35872c2480a7405e537afa2ee713ddb87a1e','[\"*\"]','2026-09-11 02:38:27',NULL,'2026-09-11 02:25:40','2026-09-11 02:38:27'),(116,'App\\Models\\User',15,'customer','8892f12e643a3264f41749ab75f736d08872cc6ddea3f15ef1584aca4fb2f86a','[\"*\"]','2026-09-11 02:43:34',NULL,'2026-09-11 02:38:32','2026-09-11 02:43:34'),(117,'App\\Models\\User',16,'customer','0c388c1f5cfd06360967c47b4e98997015dd1998a9e96ab768cc5c9d7ed81fb0','[\"*\"]','2026-09-11 02:44:19',NULL,'2026-09-11 02:43:17','2026-09-11 02:44:19'),(118,'App\\Models\\User',15,'customer','2fa77c1c295f0dd7135ac29a184f75accfa31c54655f62385fb500e6817a7882','[\"*\"]','2026-09-11 02:45:53',NULL,'2026-09-11 02:43:42','2026-09-11 02:45:53'),(119,'App\\Models\\User',16,'customer','25520cd133c831d163f97602943d00b91c37e7cf0366287cf0e167ad45c0466b','[\"*\"]','2026-09-11 02:45:39',NULL,'2026-09-11 02:44:26','2026-09-11 02:45:39'),(121,'App\\Models\\User',17,'customer','bb5939640d05c45ff07dc2ccf64e8a7a0972534aecc3581e5f1045cc9e750950','[\"*\"]','2026-09-11 02:52:15',NULL,'2026-09-11 02:51:45','2026-09-11 02:52:15'),(126,'App\\Models\\User',16,'customer','2c629f2bede71d18b92b734eb96ce35966194c4c741052b3ad08f5e0c4a0c018','[\"*\"]','2026-09-11 03:48:06',NULL,'2026-09-11 03:47:46','2026-09-11 03:48:06'),(131,'App\\Models\\User',17,'customer','974661dc0e69cfcf17ff88acdf997a58d244c9981971111e825c8f6c1ae7d628','[\"*\"]','2026-09-11 04:35:12',NULL,'2026-09-11 04:34:59','2026-09-11 04:35:12'),(132,'App\\Models\\User',15,'customer','b819ae0cec48a438fffdfc9b977122745a55dc028865415d36079e22268501ea','[\"*\"]','2026-09-11 04:41:27',NULL,'2026-09-11 04:35:15','2026-09-11 04:41:27'),(133,'App\\Models\\User',16,'customer','118b44c45e7d6bda50cc01b4ca98b3328173cf96d34b10371f955f77d04d4a81','[\"*\"]','2026-09-11 05:19:32',NULL,'2026-09-11 04:41:30','2026-09-11 05:19:32'),(145,'App\\Models\\User',17,'customer','6a7627c7ab0b89a2ae1264fff32b48b28d2c3e25d7c4409ed3d654b75421e9f5','[\"*\"]','2026-09-11 07:36:03',NULL,'2026-09-11 07:30:49','2026-09-11 07:36:03'),(146,'App\\Models\\User',15,'customer','cf685902bb90e6db866250f19b7cea477bf72f49313c39d4da692a2650d126ad','[\"*\"]','2026-09-11 07:36:39',NULL,'2026-09-11 07:36:05','2026-09-11 07:36:39'),(147,'App\\Models\\User',16,'customer','71aad9a79dabcb0d72947f46a1fbca9b098074322f975dc99fb2cd2ea81d6c8f','[\"*\"]','2026-09-11 07:37:03',NULL,'2026-09-11 07:36:42','2026-09-11 07:37:03'),(148,'App\\Models\\User',15,'customer','453edb1cb275cb32c85ccf96398164691e5263104899db20982cfae888fd12dc','[\"*\"]','2026-09-14 03:08:11',NULL,'2026-09-11 07:37:06','2026-09-14 03:08:11'),(149,'App\\Models\\User',15,'customer','0bf3eb0c8e2dd814d5ba4f1cdd67e1838a1b72b04da56589af28364a629be502','[\"*\"]','2026-09-13 23:32:42',NULL,'2026-09-13 23:32:42','2026-09-13 23:32:42'),(150,'App\\Models\\User',15,'customer','1ae90deec199a3cf5c940a906167dbb0726377f1f0778b0a4bcfd5edd29697b8','[\"*\"]','2026-09-14 00:20:59',NULL,'2026-09-14 00:11:44','2026-09-14 00:20:59'),(153,'App\\Models\\User',15,'customer','ac4a2f76103886358ce0f635dbb15aa1b703cb380715045c33b2cf12871d9f7a','[\"*\"]','2026-09-14 04:23:28',NULL,'2026-09-14 02:43:54','2026-09-14 04:23:28'),(154,'App\\Models\\User',15,'customer','245c7c504ed01d0f0fc7eb53756b8cd5024a0f8869df50f282b3731c1fd7525d','[\"*\"]','2026-09-14 04:48:10',NULL,'2026-09-14 04:30:32','2026-09-14 04:48:10'),(158,'App\\Models\\User',17,'customer','f166a90c43a69c53ee8dbbadab9b2885f00e1de8af6a1a035f31ead7ee2d177d','[\"*\"]','2026-09-14 06:26:19',NULL,'2026-09-14 06:13:56','2026-09-14 06:26:19'),(159,'App\\Models\\User',15,'customer','0ea402e82ee630740a4f2f6ed5e0eceb7f51b44d0645166a5c39808ca2387e81','[\"*\"]','2026-09-14 06:26:43',NULL,'2026-09-14 06:26:22','2026-09-14 06:26:43'),(160,'App\\Models\\User',16,'customer','53c2369b82e6e7e328fd7a7739e51d50d354de10c7b6de5f443bcc399c6a34c6','[\"*\"]','2026-09-14 06:27:01',NULL,'2026-09-14 06:26:46','2026-09-14 06:27:01'),(161,'App\\Models\\User',15,'customer','68b0fcb8c771a1e667549f0c1f444c5ecdc2c9fb5d4682f88a994e46712fb269','[\"*\"]','2026-09-14 06:27:31',NULL,'2026-09-14 06:27:04','2026-09-14 06:27:31'),(162,'App\\Models\\User',16,'customer','a657005f08a34d1e4a72f95b06d8749344c16cb8d19b912eb8f3ec338d72a7a2','[\"*\"]','2026-09-14 06:28:00',NULL,'2026-09-14 06:27:35','2026-09-14 06:28:00'),(163,'App\\Models\\User',15,'customer','bc309d5cedbe759d2848c21e21483bbd485c1c1ae4683f428ed0592f9c641d7f','[\"*\"]','2026-09-14 07:12:48',NULL,'2026-09-14 06:28:03','2026-09-14 07:12:48'),(164,'App\\Models\\User',15,'customer','ad45565d4a612df543a8b28409c2db499a339fad2ffb527034e92a782d9e44c8','[\"*\"]','2026-09-14 23:40:06',NULL,'2026-09-14 23:04:36','2026-09-14 23:40:06'),(165,'App\\Models\\User',15,'customer','f4d1cd8933f131aed117c8f6ca0211d3eae8e425a878374c0829c13be056d838','[\"*\"]','2026-09-14 23:12:03',NULL,'2026-09-14 23:11:45','2026-09-14 23:12:03'),(166,'App\\Models\\User',15,'customer','1ab89b49492474320441399641e12536b300b6fedb5a15276387e5aceec92e1d','[\"*\"]','2026-09-14 23:13:04',NULL,'2026-09-14 23:13:00','2026-09-14 23:13:04'),(167,'App\\Models\\User',15,'customer','408506de3db4f0c8b7e4bd6dbab6bf4dc10cc5b309bbb5dfd1548b03547894c3','[\"*\"]','2026-09-14 23:13:57',NULL,'2026-09-14 23:13:25','2026-09-14 23:13:57'),(168,'App\\Models\\User',15,'customer','644a7f4b620cda1eb71699257d4a5a27c2995b3f93973705cb6e19be3d00b64f','[\"*\"]','2026-09-14 23:14:30',NULL,'2026-09-14 23:14:26','2026-09-14 23:14:30'),(169,'App\\Models\\User',15,'customer','9d057692b63e660d2c4808ddc62c8e0f9ac22f084119291ac0a60f4febcdb232','[\"*\"]','2026-09-14 23:14:53',NULL,'2026-09-14 23:14:47','2026-09-14 23:14:53'),(170,'App\\Models\\User',15,'customer','6daf152493a465aba7fd3a7d5537ef078d7ee7f50e2777db9ca8e5aa9e30d444','[\"*\"]','2026-09-14 23:15:14',NULL,'2026-09-14 23:15:13','2026-09-14 23:15:14'),(171,'App\\Models\\User',15,'customer','e5238445a6d3f6fed905837627afe2f7f89a6cd045650ccd16db8bbd1dd0847b','[\"*\"]','2026-09-14 23:15:50',NULL,'2026-09-14 23:15:44','2026-09-14 23:15:50'),(172,'App\\Models\\User',15,'customer','08c79865ad6b2070ae9744a0aab87e9d306862b7c3bed9b8d06164b2303f4149','[\"*\"]','2026-09-14 23:16:28',NULL,'2026-09-14 23:16:23','2026-09-14 23:16:28'),(173,'App\\Models\\User',15,'customer','a34001db3b79296bc7d2fd4bc8553def694db2bf89581194f183ca33d0e32bb7','[\"*\"]','2026-09-14 23:16:55',NULL,'2026-09-14 23:16:49','2026-09-14 23:16:55'),(174,'App\\Models\\User',15,'customer','0ec40c78dc0218e3ff17abe999aac933c079e306ac6b249a47330fbb896fa1c2','[\"*\"]','2026-09-14 23:17:17',NULL,'2026-09-14 23:17:13','2026-09-14 23:17:17'),(175,'App\\Models\\User',15,'customer','f44a053a7f10c18c4a093f33707a85b8134e3b57f216eed11898be26108fec1e','[\"*\"]','2026-09-14 23:17:48',NULL,'2026-09-14 23:17:41','2026-09-14 23:17:48'),(176,'App\\Models\\User',15,'customer','c75927817aad21d68a0479bed46ef795217e0ce0ec00449fd8a809c21f2ff1f9','[\"*\"]','2026-09-14 23:18:19',NULL,'2026-09-14 23:18:11','2026-09-14 23:18:19'),(177,'App\\Models\\User',15,'customer','4a496f2d69a4f32256226b9470685f4ab74029ce40cda4bdc2d4095ddc8d316e','[\"*\"]','2026-09-14 23:19:11',NULL,'2026-09-14 23:18:49','2026-09-14 23:19:11'),(178,'App\\Models\\User',15,'customer','7ec5a3d6a4e1e3ba001a205b118c6f6fc89de3b57784771301e71e11d59f78b8','[\"*\"]','2026-09-14 23:19:53',NULL,'2026-09-14 23:19:41','2026-09-14 23:19:53'),(179,'App\\Models\\User',15,'customer','b04e39de4eeee0355e587b93b7d8b0b5157fa6e0e8ba03e2844b9eee1fc9992b','[\"*\"]','2026-09-14 23:20:28',NULL,'2026-09-14 23:20:16','2026-09-14 23:20:28'),(180,'App\\Models\\User',15,'customer','7268733f880129f7071be5f1071fc7841c714698db8c95201c4573ce068652f5','[\"*\"]','2026-09-14 23:23:56',NULL,'2026-09-14 23:23:55','2026-09-14 23:23:56'),(181,'App\\Models\\User',16,'customer','d579f8f78aecef9abcc8b20f53535e144a14a5e776bc7b2176068dfa683a6625','[\"*\"]','2026-09-14 23:41:04',NULL,'2026-09-14 23:26:20','2026-09-14 23:41:04'),(182,'App\\Models\\User',15,'customer','755c643da10783ffda7639e97cd8ed8868d63d60370e0364202faa2fe3c54b79','[\"*\"]','2026-09-14 23:29:03',NULL,'2026-09-14 23:29:03','2026-09-14 23:29:03'),(183,'App\\Models\\User',15,'customer','a0bd01209aadedc63b88590f9c1b8b32469fe0b1409c77cb936e8e0f248dd148','[\"*\"]','2026-09-14 23:42:30',NULL,'2026-09-14 23:42:22','2026-09-14 23:42:30'),(184,'App\\Models\\User',15,'customer','d28f25ae74e2714273deaa219c2e64f1cad4e31ed31998cce97aabf3437b03b0','[\"*\"]','2026-09-14 23:44:29',NULL,'2026-09-14 23:44:28','2026-09-14 23:44:29'),(185,'App\\Models\\User',15,'customer','3c199fdac82cb285270c1f0a627a740d1e3bbf48b16faf0e40e7727efe85cb15','[\"*\"]','2026-09-14 23:45:41',NULL,'2026-09-14 23:45:40','2026-09-14 23:45:41'),(186,'App\\Models\\User',15,'customer','c7dfcf7c1c9836d8146c734474b4cf2967285cb5b75026c0ebe0abd94fa1451f','[\"*\"]','2026-09-14 23:46:12',NULL,'2026-09-14 23:46:11','2026-09-14 23:46:12');
/*!40000 ALTER TABLE `personal_access_tokens` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `product_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_reviews` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) unsigned NOT NULL,
  `order_item_id` bigint(20) unsigned NOT NULL,
  `product_id` bigint(20) unsigned NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `rating` tinyint(3) unsigned NOT NULL,
  `comment` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `product_reviews_order_item_id_unique` (`order_item_id`),
  KEY `product_reviews_order_id_foreign` (`order_id`),
  KEY `product_reviews_user_id_foreign` (`user_id`),
  KEY `product_reviews_product_id_created_at_index` (`product_id`,`created_at`),
  CONSTRAINT `product_reviews_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `product_reviews_order_item_id_foreign` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`) ON DELETE CASCADE,
  CONSTRAINT `product_reviews_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  CONSTRAINT `product_reviews_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `product_reviews` WRITE;
/*!40000 ALTER TABLE `product_reviews` DISABLE KEYS */;
/*!40000 ALTER TABLE `product_reviews` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `product_variants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `product_variants` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) unsigned NOT NULL,
  `label` varchar(255) NOT NULL,
  `sku` varchar(255) NOT NULL,
  `price_cents` int(10) unsigned NOT NULL,
  `compare_at_price_cents` int(10) unsigned DEFAULT NULL,
  `inventory_quantity` int(10) unsigned NOT NULL DEFAULT 0,
  `image_url` varchar(255) DEFAULT NULL,
  `sort_order` smallint(5) unsigned NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `product_variants_sku_unique` (`sku`),
  KEY `product_variants_product_id_sort_order_index` (`product_id`,`sort_order`),
  KEY `product_variants_is_active_index` (`is_active`),
  CONSTRAINT `product_variants_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `product_variants` WRITE;
/*!40000 ALTER TABLE `product_variants` DISABLE KEYS */;
INSERT INTO `product_variants` VALUES (1,7,'256GB SSD / 8GB RAM','GDP-PROD-004-500',99900,NULL,80,NULL,1,1,'2026-09-09 01:12:49','2026-09-14 04:15:22'),(2,7,'512GB SSD / 16GB RAM','GDP-PROD-004-1000',119900,NULL,58,NULL,2,1,'2026-09-09 01:12:49','2026-09-14 04:15:22'),(3,7,'1TB SSD / 32GB RAM','GDP-PROD-004-2000',149900,NULL,22,NULL,3,1,'2026-09-09 01:12:49','2026-09-14 04:15:22'),(4,11,'Midnight Black','GDP-PROD-005-1KG',34900,NULL,50,NULL,1,1,'2026-09-09 01:12:49','2026-09-14 04:15:22'),(5,11,'Platinum Silver','GDP-PROD-005-5KG',36900,NULL,15,NULL,2,1,'2026-09-09 01:12:49','2026-09-14 04:15:22'),(6,1,'256GB','GDP-PROD-001-V1',109900,NULL,40,'/storage/products/08qPFcHzRNRtfDWtI3xgql5mOPaCVg0fUdUWSYiN.webp',0,1,'2026-09-14 04:55:09','2026-09-14 07:04:36'),(7,1,'512GB','GDP-PROD-001-V2',129900,NULL,40,'/storage/products/PT66ONnzX8Kml67rgAB9wU8BYBRxvCSTkZ8hinSm.webp',1,1,'2026-09-14 04:55:09','2026-09-14 07:04:36'),(8,2,'256GB','GDP-PROD-002-V1',89900,NULL,40,NULL,1,1,'2026-09-14 04:55:09','2026-09-14 04:55:09'),(9,6,'16GB / 512GB','GDP-PROD-003-V1',139900,NULL,40,NULL,1,1,'2026-09-14 04:55:09','2026-09-14 04:55:09'),(10,8,'16GB / 1TB','GDP-PROD-010-V1',159900,NULL,40,NULL,1,1,'2026-09-14 04:55:09','2026-09-14 04:55:09'),(11,17,'Ocean Blue','GDP-PROD-017-V1',1499,NULL,40,NULL,1,1,'2026-09-14 04:55:09','2026-09-14 04:55:09'),(12,17,'Blossom Pink','GDP-PROD-017-V2',1499,NULL,40,NULL,2,1,'2026-09-14 04:55:09','2026-09-14 04:55:09'),(13,19,'45mm','GDP-PROD-019-V1',42900,NULL,40,NULL,1,1,'2026-09-14 04:55:09','2026-09-14 04:55:09'),(14,21,'Coral','GDP-PROD-021-V1',15900,NULL,40,NULL,1,1,'2026-09-14 04:55:09','2026-09-14 04:55:09'),(15,28,'Digital Edition','GDP-PROD-028-V1',44900,NULL,40,'/img/products/28-v15.png',1,1,'2026-09-14 04:55:09','2026-09-14 06:01:19'),(16,30,'Neon Red / Neon Blue','GDP-PROD-030-V1',34900,NULL,40,NULL,1,1,'2026-09-14 04:55:09','2026-09-14 04:55:09'),(17,34,'Pale Grey','GDP-PROD-034-V1',9900,NULL,40,'/img/products/34-v17.jpg',1,1,'2026-09-14 04:55:09','2026-09-14 06:01:19');
/*!40000 ALTER TABLE `product_variants` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `products` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `category_id` bigint(20) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `sku` varchar(255) NOT NULL,
  `price_cents` int(10) unsigned NOT NULL,
  `compare_at_price_cents` int(10) unsigned DEFAULT NULL,
  `inventory_quantity` int(10) unsigned NOT NULL DEFAULT 0,
  `image_url` varchar(255) DEFAULT NULL,
  `rating_avg` decimal(3,2) DEFAULT NULL,
  `rating_count` int(10) unsigned NOT NULL DEFAULT 0,
  `units_sold` int(10) unsigned NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `products_slug_unique` (`slug`),
  UNIQUE KEY `products_sku_unique` (`sku`),
  KEY `products_category_id_foreign` (`category_id`),
  KEY `products_is_active_index` (`is_active`),
  CONSTRAINT `products_category_id_foreign` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES (1,1,'Apple iPhone 15 Pro','apple-iphone-15-pro','Apple\'s titanium-body flagship with the A17 Pro chip, a 48MP main camera, and USB-C — built for all-day performance in the pocket.','GDP-PROD-001',99900,NULL,100,'/img/products/1.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(2,1,'Samsung Galaxy S24','samsung-galaxy-s24','A compact Android flagship with a bright Dynamic AMOLED display, Snapdragon power, and Galaxy AI features built in.','GDP-PROD-002',79900,NULL,99,'/img/products/2.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(3,1,'Google Pixel 8','google-pixel-8','Google\'s pure-Android phone with the Tensor G3 chip and a camera tuned for standout low-light and portrait shots.','GDP-PROD-007',69900,74900,100,'/img/products/3.png',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(4,1,'OnePlus 12','oneplus-12','A fast, fluid flagship with Hasselblad-tuned cameras and 100W charging that tops up the battery in minutes.','GDP-PROD-008',73900,NULL,100,'/img/products/4.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(5,1,'Xiaomi 14','xiaomi-14','A pocketable flagship with Leica optics and flagship-tier Snapdragon performance at a sharp price.','GDP-PROD-009',64900,NULL,100,'/img/products/5.png',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(6,2,'Apple MacBook Air M3','apple-macbook-air-m3','Apple\'s fanless, all-day laptop — the M3 chip handles everyday work and creative apps without breaking a sweat.','GDP-PROD-003',109900,NULL,80,'/img/products/6.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(7,2,'Dell XPS 13','dell-xps-13','A compact ultrabook with an edge-to-edge InfinityEdge display, built for work on the go.','GDP-PROD-004',99900,NULL,100,'/img/products/7.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(8,2,'HP Spectre x360','hp-spectre-x360','A convertible 2-in-1 with a gem-cut design that folds flat into tablet mode for sketching, notes, or streaming.','GDP-PROD-010',129900,NULL,91,'/img/products/8.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(9,2,'Lenovo ThinkPad X1 Carbon','lenovo-thinkpad-x1-carbon','The business standard: a carbon-fibre chassis, legendary keyboard, and MIL-SPEC durability.','GDP-PROD-011',159900,NULL,89,'/img/products/9.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(10,2,'Asus ROG Zephyrus G14','asus-rog-zephyrus-g14','A compact gaming laptop that punches well above its size, with enough GPU power for the latest titles.','GDP-PROD-012',179900,NULL,98,'/img/products/10.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(11,3,'Sony WH-1000XM5','sony-wh-1000xm5','Industry-leading noise cancellation and all-day comfort, tuned for travel and focus.','GDP-PROD-005',34900,NULL,99,'/img/products/11.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(12,3,'Apple AirPods Pro 2','apple-airpods-pro-2','Adaptive noise cancellation, Transparency mode, and spatial audio in Apple\'s smallest true wireless earbuds.','GDP-PROD-006',24900,NULL,99,'/img/products/12.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(13,3,'Bose QuietComfort Ultra','bose-quietcomfort-ultra','Bose\'s quietest headphones yet, with immersive spatial audio and plush all-day comfort.','GDP-PROD-013',42900,NULL,100,'/img/products/13.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(14,3,'JBL Flip 6 Speaker','jbl-flip-6-speaker','A rugged, waterproof Bluetooth speaker with punchy JBL sound for the beach, the shower, or the backyard.','GDP-PROD-014',12900,NULL,99,'/img/products/14.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(15,3,'Sennheiser Momentum 4','sennheiser-momentum-4','Audiophile-tuned sound with up to 60 hours of battery life on a single charge.','GDP-PROD-015',34900,NULL,99,'/img/products/15.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(16,4,'Tempered Glass Screen Protector','tempered-glass-screen-protector','9H hardness, an oleophobic coating, and edge-to-edge clarity that keeps your screen scratch-free.','GDP-PROD-016',999,NULL,100,'/img/products/16.png',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(17,4,'Silicone Phone Case','silicone-phone-case','A soft-touch silicone case with a microfibre lining that protects without adding bulk.','GDP-PROD-017',1499,NULL,99,'/img/products/17.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:14:06'),(18,4,'MagSafe Wireless Charger','magsafe-wireless-charger','Snap-on magnetic charging for a clean, cable-free charge every time you set your phone down.','GDP-PROD-018',3999,NULL,100,'/img/products/18.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(19,5,'Apple Watch Series 9','apple-watch-series-9','Apple\'s smartwatch with the new double-tap gesture, a brighter always-on display, and deep health tracking.','GDP-PROD-019',39900,NULL,100,'/img/products/19.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(20,5,'Samsung Galaxy Watch 6','samsung-galaxy-watch-6','A sleek Wear OS smartwatch with advanced sleep coaching and body composition tracking.','GDP-PROD-020',32900,NULL,100,'/img/products/20.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(21,5,'Fitbit Charge 6','fitbit-charge-6','A slim fitness tracker with built-in GPS, heart-rate tracking, and up to a week of battery life.','GDP-PROD-021',15900,NULL,100,'/img/products/21.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(22,6,'Canon EOS R50','canon-eos-r50','An entry-level mirrorless camera with fast autofocus, ideal for stepping up from a phone camera.','GDP-PROD-022',79900,NULL,100,'/img/products/22.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(23,6,'Sony Alpha ZV-E10','sony-alpha-zv-e10','A vlogging-focused mirrorless camera with a fully articulating screen and background-defocus mode.','GDP-PROD-023',69900,NULL,100,'/img/products/23.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(24,6,'GoPro Hero 12','gopro-hero-12','Rugged, waterproof, and stabilized — built to capture action from anywhere.','GDP-PROD-024',39900,NULL,100,'/img/products/24.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(25,7,'Samsung 55\" QLED TV','samsung-55-qled-tv','Quantum Dot colour and a wide viewing angle bring movies and sport to life in a 55-inch frame.','GDP-PROD-025',89900,NULL,100,'/img/products/25.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(26,7,'LG 65\" OLED TV','lg-65-oled-tv','Self-lit OLED pixels deliver perfect blacks and infinite contrast on a 65-inch canvas.','GDP-PROD-026',179900,NULL,100,'/img/products/26.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(27,7,'Sony 43\" Bravia TV','sony-43-bravia-tv','Sony\'s processing engine sharpens detail and motion for a crisp, cinematic picture.','GDP-PROD-027',54900,NULL,100,'/img/products/27.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(28,8,'Sony PlayStation 5','sony-playstation-5','Lightning-fast SSD loading, stunning visuals, and the DualSense controller\'s haptic feedback.','GDP-PROD-028',49900,NULL,100,'/img/products/28.png',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(29,8,'Microsoft Xbox Series X','microsoft-xbox-series-x','Microsoft\'s most powerful console, built for 4K gaming at up to 120fps.','GDP-PROD-029',49900,NULL,100,'/img/products/29.png',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(30,8,'Nintendo Switch OLED','nintendo-switch-oled','A vivid 7-inch OLED screen makes handheld play pop, and it still docks to the TV in seconds.','GDP-PROD-030',34900,NULL,100,'/img/products/30.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(31,9,'Dyson V15 Vacuum Cleaner','dyson-v15-vacuum-cleaner','A laser reveals hidden dust while a cordless motor delivers powerful, whole-home suction.','GDP-PROD-031',74900,NULL,100,'/img/products/31.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(32,9,'Philips Air Fryer XXL','philips-air-fryer-xxl','Rapid Air technology cooks crispy, low-oil favourites fast enough for a weeknight dinner.','GDP-PROD-032',19900,NULL,100,'/img/products/32.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(33,9,'LG 8kg Front Load Washing Machine','lg-8kg-front-load-washing-machine','Steam-cleaning and a quiet direct-drive motor make laundry day easier.','GDP-PROD-033',54900,NULL,100,'/img/products/33.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(34,10,'Logitech MX Master 3S Mouse','logitech-mx-master-3s-mouse','A precision mouse with silent clicks and an ultra-fast scroll wheel, built for all-day productivity.','GDP-PROD-034',9900,NULL,100,'/img/products/34.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(35,10,'Keychron K2 Mechanical Keyboard','keychron-k2-mechanical-keyboard','Hot-swappable mechanical switches and Bluetooth multi-device pairing in a compact 75% layout.','GDP-PROD-035',8900,NULL,100,'/img/products/35.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(36,10,'Dell 27\" 4K Monitor','dell-27-4k-monitor','Sharp 4K clarity and accurate colour on a 27-inch panel built for work and creative editing.','GDP-PROD-036',39900,NULL,100,'/img/products/36.png',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(37,11,'Anker 20000mAh Power Bank','anker-20000mah-power-bank','Enough capacity for multiple full phone charges, with fast pass-through charging.','GDP-PROD-037',4999,NULL,100,'/img/products/37.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(38,11,'Apple 20W USB-C Fast Charger','apple-20w-usb-c-fast-charger','Apple\'s compact charger tops up an iPhone to 50% in about 30 minutes.','GDP-PROD-038',1999,NULL,100,'/img/products/38.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(39,11,'Belkin 3-in-1 Wireless Charging Stand','belkin-3-in-1-wireless-charging-stand','Charge your phone, watch, and earbuds together from a single stand.','GDP-PROD-039',9999,NULL,100,'/img/products/39.png',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(40,12,'SanDisk 1TB Portable SSD','sandisk-1tb-portable-ssd','Pocket-sized storage with fast transfer speeds, built to survive drops and bumps on the go.','GDP-PROD-040',8999,NULL,100,'/img/products/40.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(41,12,'Samsung 256GB microSD Card','samsung-256gb-microsd-card','High-speed storage for phones, cameras, and handheld consoles.','GDP-PROD-041',2999,NULL,100,'/img/products/41.png',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(42,12,'WD 2TB External Hard Drive','wd-2tb-external-hard-drive','Reliable backup storage with plug-and-play simplicity for photos, videos, and files.','GDP-PROD-042',6999,NULL,100,'/img/products/42.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(43,13,'TP-Link Archer WiFi 6 Router','tp-link-archer-wifi-6-router','Faster, more reliable Wi-Fi for a house full of devices with WiFi 6 speeds.','GDP-PROD-043',12900,NULL,100,'/img/products/43.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(44,13,'Netgear Orbi Mesh WiFi System','netgear-orbi-mesh-wifi-system','Whole-home mesh coverage that eliminates dead zones without losing speed.','GDP-PROD-044',22900,NULL,100,'/img/products/44.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(45,13,'TP-Link 8-Port Gigabit Switch','tp-link-8-port-gigabit-switch','Expand your wired network with eight reliable gigabit ports.','GDP-PROD-045',3999,NULL,100,'/img/products/45.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(46,14,'Philips Hair Dryer','philips-hair-dryer','Fast-drying airflow with a cooling shot to lock in your style.','GDP-PROD-046',2999,NULL,100,'/img/products/46.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(47,14,'Oral-B Electric Toothbrush','oral-b-electric-toothbrush','A pressure sensor and timer help you brush the dentist-recommended way, every time.','GDP-PROD-047',4999,NULL,100,'/img/products/47.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(48,14,'Panasonic Beard Trimmer','panasonic-beard-trimmer','Precision blades and multiple length settings for a clean, consistent trim.','GDP-PROD-048',3499,NULL,100,'/img/products/48.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(49,15,'Motorola Video Baby Monitor','motorola-video-baby-monitor','See and hear your baby clearly with night vision and two-way audio.','GDP-PROD-049',8999,NULL,100,'/img/products/49.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(50,15,'Amazon Fire Kids Tablet','amazon-fire-kids-tablet','A durable, parent-controlled tablet built for young explorers, with a kid-proof case included.','GDP-PROD-050',9999,NULL,100,'/img/products/50.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(51,15,'LeapFrog Learning Tablet','leapfrog-learning-tablet','A screen-time companion designed to teach letters, numbers, and problem-solving through play.','GDP-PROD-051',5999,NULL,100,'/img/products/51.webp',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(52,16,'HP LaserJet Printer','hp-laserjet-printer','Crisp, fast black-and-white printing built for the home office.','GDP-PROD-052',17900,NULL,100,'/img/products/52.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(53,16,'Epson Portable Projector','epson-portable-projector','A compact projector that turns any wall into a big screen for movies or presentations.','GDP-PROD-053',39900,NULL,100,'/img/products/53.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19'),(54,16,'Logitech Webcam C920','logitech-webcam-c920','Full HD 1080p video and clear audio, built for sharp video calls and streaming.','GDP-PROD-054',6999,7999,100,'/img/products/54.jpg',NULL,0,0,1,'2026-09-09 01:12:49','2026-09-14 06:01:19');
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `rider_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rider_reviews` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) unsigned NOT NULL,
  `rider_id` bigint(20) unsigned NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `rating` tinyint(3) unsigned NOT NULL,
  `comment` text DEFAULT NULL,
  `source` varchar(16) NOT NULL DEFAULT 'delivery',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rider_reviews_order_id_unique` (`order_id`),
  KEY `rider_reviews_user_id_foreign` (`user_id`),
  KEY `rider_reviews_rider_id_created_at_index` (`rider_id`,`created_at`),
  CONSTRAINT `rider_reviews_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `rider_reviews_rider_id_foreign` FOREIGN KEY (`rider_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `rider_reviews_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `rider_reviews` WRITE;
/*!40000 ALTER TABLE `rider_reviews` DISABLE KEYS */;
/*!40000 ALTER TABLE `rider_reviews` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `rider_shift_breaks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rider_shift_breaks` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `rider_shift_id` bigint(20) unsigned NOT NULL,
  `reason` varchar(80) DEFAULT NULL,
  `started_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `ended_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `rider_shift_breaks_rider_shift_id_index` (`rider_shift_id`),
  CONSTRAINT `rider_shift_breaks_rider_shift_id_foreign` FOREIGN KEY (`rider_shift_id`) REFERENCES `rider_shifts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `rider_shift_breaks` WRITE;
/*!40000 ALTER TABLE `rider_shift_breaks` DISABLE KEYS */;
INSERT INTO `rider_shift_breaks` VALUES (1,1,'Lunch','2026-09-10 06:47:38','2026-09-10 01:17:38','2026-09-10 01:17:30','2026-09-10 01:17:38'),(4,1,'Lunch','2026-09-10 09:44:50','2026-09-10 04:14:50','2026-09-10 04:14:44','2026-09-10 04:14:50'),(5,1,'Lunch','2026-09-10 10:38:42','2026-09-10 05:08:42','2026-09-10 05:08:34','2026-09-10 05:08:42'),(6,10,'Lunch','2026-09-14 11:56:53','2026-09-14 06:26:53','2026-09-11 02:43:32','2026-09-14 06:26:53');
/*!40000 ALTER TABLE `rider_shift_breaks` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `rider_shifts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rider_shifts` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `clock_in_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `clock_out_at` timestamp NULL DEFAULT NULL,
  `source` varchar(10) NOT NULL DEFAULT 'rider',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `rider_shifts_user_id_clock_in_at_index` (`user_id`,`clock_in_at`),
  CONSTRAINT `rider_shifts_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `rider_shifts` WRITE;
/*!40000 ALTER TABLE `rider_shifts` DISABLE KEYS */;
INSERT INTO `rider_shifts` VALUES (1,16,'2026-09-10 10:38:47','2026-09-10 05:08:47','rider','2026-09-10 01:17:26','2026-09-10 05:08:47'),(10,16,'2026-09-10 05:08:49',NULL,'rider','2026-09-10 05:08:49','2026-09-10 05:08:49');
/*!40000 ALTER TABLE `rider_shifts` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `rider_store`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `rider_store` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `store_id` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rider_store_user_id_store_id_unique` (`user_id`,`store_id`),
  KEY `rider_store_store_id_foreign` (`store_id`),
  CONSTRAINT `rider_store_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `rider_store_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `rider_store` WRITE;
/*!40000 ALTER TABLE `rider_store` DISABLE KEYS */;
INSERT INTO `rider_store` VALUES (3,16,1),(4,18,2);
/*!40000 ALTER TABLE `rider_store` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `sessions` WRITE;
/*!40000 ALTER TABLE `sessions` DISABLE KEYS */;
INSERT INTO `sessions` VALUES ('3oISb7Njdw4tKH5J5FntsNvMPeZvdPZt82SXyr4x',NULL,'127.0.0.1','curl/8.21.0','eyJfdG9rZW4iOiI5eHZJQzA1M1FNRWFFdDh0ZTM3S3lsMlFMY1ZJbklLdGVweGNnWjVEIiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cLzEyNy4wLjAuMTo4MDAwXC9hcGlcL2Jhbm5lcnMiLCJyb3V0ZSI6bnVsbH0sIl9mbGFzaCI6eyJvbGQiOltdLCJuZXciOltdfX0=',1789017213),('5iKl36D45BSmZw2tSmv3YKKCEPl4XQlqZACdTMAo',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36 Edg/152.0.0.0','eyJfdG9rZW4iOiIyQXhSN0s5Mmh4NzNJbkRsSmxoTDVZTEJrWmJFUUVSRXZXRTJTaVI4IiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cL2xvY2FsaG9zdDo4MDAwIiwicm91dGUiOm51bGx9LCJfZmxhc2giOnsib2xkIjpbXSwibmV3IjpbXX19',1789367069),('E3uiXV8elXX319hZg99S3K9ivwaG5bNMZA1NgvB2',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36 Edg/152.0.0.0','eyJfdG9rZW4iOiJnWTFvWmlTVjVOcDZoWXRaYUJBOEJYcUtNdHhET2R3ME1WbVEwSlVoIiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cL2xvY2FsaG9zdDo4MDAwIiwicm91dGUiOm51bGx9LCJfZmxhc2giOnsib2xkIjpbXSwibmV3IjpbXX19',1789044363),('EcUaxHeMLWcyD1TPvFwuchfWw7Xg7nmdGwJgXbJ4',NULL,'127.0.0.1','curl/8.21.0','eyJfdG9rZW4iOiI2a05aWWFqaEY0UHlabVdRbTh1VXJTWlE3cG9MTFI4ZzhLRUdwSmN4IiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cLzEyNy4wLjAuMTo4MDAwXC9hcGlcL2hlYWx0aCIsInJvdXRlIjpudWxsfSwiX2ZsYXNoIjp7Im9sZCI6W10sIm5ldyI6W119fQ==',1789032140),('LfYGkhTNNaonvFh2fAxz8ISJrItMdWw9bqKz8LRi',NULL,'127.0.0.1','curl/8.21.0','eyJfdG9rZW4iOiI5Sk9ONTNjUEczU2ViWDhZUGVFNlpiUXlvSjc2akROV3FuR21Vdm44IiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cLzEyNy4wLjAuMTo4MDAwXC9hcGlcL2F1dGhcL21lIiwicm91dGUiOm51bGx9LCJfZmxhc2giOnsib2xkIjpbXSwibmV3IjpbXX19',1789111585),('UTbg5UPwPiWkoC54ywTxGtgu03viEwtrup5vfuf8',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36 Edg/152.0.0.0','eyJfdG9rZW4iOiJjM0RBT05GUWNJb1FPTWl3WElPTTJsY0hCbTh0TUtHZUR0dU54WllzIiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cL2xvY2FsaG9zdDo4MDAwIiwicm91dGUiOm51bGx9LCJfZmxhc2giOnsib2xkIjpbXSwibmV3IjpbXX19',1788953496),('VbUeTGNJe0w12iJenDsJSM2ByZjaYiW3lC3tldpR',NULL,'127.0.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36 Edg/152.0.0.0','eyJfdG9rZW4iOiJpZFl1WTh3Y09tUUQ4SlhJZVNYaGhHRURIamVodU1oSGFjTm1wY3h5IiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cL2xvY2FsaG9zdDo4MDAwIiwicm91dGUiOm51bGx9LCJfZmxhc2giOnsib2xkIjpbXSwibmV3IjpbXX19',1788940289),('ZiwnkODKgtrcT3FKTmLZaSQhoOVtb0NLbJ689l6k',NULL,'127.0.0.1','curl/8.21.0','eyJfdG9rZW4iOiJvZjFhdjZjcXZCVHczN25PV1p0VWNKNkFVYVJHN2xrY2YxNE1mbG9BIiwiX3ByZXZpb3VzIjp7InVybCI6Imh0dHA6XC9cLzEyNy4wLjAuMTo4MDAwXC9hcGlcL2hvbWUiLCJyb3V0ZSI6bnVsbH0sIl9mbGFzaCI6eyJvbGQiOltdLCJuZXciOltdfX0=',1789447022);
/*!40000 ALTER TABLE `sessions` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `settings` (
  `key` varchar(255) NOT NULL,
  `value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`value`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `settings` WRITE;
/*!40000 ALTER TABLE `settings` DISABLE KEYS */;
INSERT INTO `settings` VALUES ('branding','{\"v\":{\"store_name\":\"NexTech\",\"tagline\":\"Navigate to the Future of Technology\",\"logo_url\":null,\"favicon_url\":\"\\/storage\\/products\\/UwbDkyfQGw98w7hhx7hlPcFS1Cw9VZfnz06klnyk.jpg\",\"theme\":\"light\",\"layout_width\":\"full\",\"color_brand\":\"#2563EB\",\"color_accent\":\"#F97316\",\"color_heading\":\"#0F172A\"}}','2026-09-09 01:31:48','2026-09-14 07:06:38'),('checkout_fees','{\"v\":{\"delivery_mode\":\"fixed\",\"delivery_fee_cents\":299,\"delivery_near_fee_cents\":199,\"delivery_far_fee_cents\":599,\"free_delivery_threshold_cents\":3500,\"handling_fee_cents\":99,\"small_cart_fee_cents\":199,\"small_cart_min_cents\":1000,\"tax_rate_bps\":887}}','2026-09-10 07:26:50','2026-09-10 07:26:50'),('cod_enabled','{\"v\":true}','2026-09-10 07:26:49','2026-09-10 07:26:49'),('footer','{\"v\":{\"copyright\":\"\\u00a9 {year} nextech\",\"note\":\"NexTech is a demo storefront. Prices, delivery estimates and content pages are illustrative and set by the store operator in the admin console.\",\"app_store_url\":\"https:\\/\\/apps.apple.com\\/app\\/grocerly-demo\",\"play_store_url\":\"https:\\/\\/play.google.com\\/store\\/apps\\/details?id=com.grocerly.demo\",\"socials\":{\"facebook\":\"https:\\/\\/facebook.com\\/grocerly\",\"x\":\"https:\\/\\/x.com\\/grocerly\",\"instagram\":\"https:\\/\\/instagram.com\\/grocerly\",\"linkedin\":\"https:\\/\\/www.linkedin.com\\/company\\/grocerly\",\"youtube\":\"https:\\/\\/www.youtube.com\\/@grocerly\"},\"links\":[]}}','2026-09-09 01:12:49','2026-09-14 05:52:41');
/*!40000 ALTER TABLE `settings` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `store_inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `store_inventory` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `store_id` bigint(20) unsigned NOT NULL,
  `product_id` bigint(20) unsigned NOT NULL,
  `product_variant_id` bigint(20) unsigned DEFAULT NULL,
  `quantity` int(10) unsigned NOT NULL DEFAULT 0,
  `is_stocked` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `store_inventory_store_id_product_id_product_variant_id_unique` (`store_id`,`product_id`,`product_variant_id`),
  KEY `store_inventory_product_variant_id_foreign` (`product_variant_id`),
  KEY `store_inventory_product_id_store_id_index` (`product_id`,`store_id`),
  CONSTRAINT `store_inventory_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `store_inventory_product_variant_id_foreign` FOREIGN KEY (`product_variant_id`) REFERENCES `product_variants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `store_inventory_store_id_foreign` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `store_inventory` WRITE;
/*!40000 ALTER TABLE `store_inventory` DISABLE KEYS */;
INSERT INTO `store_inventory` VALUES (1,1,54,NULL,50,1,'2026-09-09 04:21:55','2026-09-09 04:21:55');
/*!40000 ALTER TABLE `store_inventory` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `stores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stores` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT 'Main Store',
  `line1` varchar(255) NOT NULL,
  `line2` varchar(255) DEFAULT NULL,
  `city` varchar(100) NOT NULL,
  `state` varchar(60) NOT NULL,
  `postal_code` varchar(12) NOT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `delivery_radius_km` smallint(5) unsigned NOT NULL DEFAULT 5,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `stores` WRITE;
/*!40000 ALTER TABLE `stores` DISABLE KEYS */;
INSERT INTO `stores` VALUES (1,'Caresort Solutions','C-86, Pannu Tower 4th Floor','Phase 7, Industrial Area','Sahibzada Ajit Singh Nagar','Punjab','160055',30.6908804,76.7114879,5,1,'2026-09-09 01:33:16','2026-09-09 01:33:16'),(2,'The Royal Majestic','chowk, 200 Feet Rd, near Phullanwal','Passi Nagar','Ludhiana','Punjab','141013',30.9090157,75.8516010,5,1,'2026-09-09 01:36:49','2026-09-09 01:36:49');
/*!40000 ALTER TABLE `stores` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `stripe_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stripe_events` (
  `id` varchar(255) NOT NULL,
  `type` varchar(255) NOT NULL,
  `processed_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `stripe_events_type_index` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `stripe_events` WRITE;
/*!40000 ALTER TABLE `stripe_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `stripe_events` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `support_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `support_messages` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `support_thread_id` bigint(20) unsigned NOT NULL,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `is_staff` tinyint(1) NOT NULL DEFAULT 0,
  `internal` tinyint(1) NOT NULL DEFAULT 0,
  `body` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `support_messages_user_id_foreign` (`user_id`),
  KEY `support_messages_support_thread_id_id_index` (`support_thread_id`,`id`),
  CONSTRAINT `support_messages_support_thread_id_foreign` FOREIGN KEY (`support_thread_id`) REFERENCES `support_threads` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `support_messages_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `support_messages` WRITE;
/*!40000 ALTER TABLE `support_messages` DISABLE KEYS */;
INSERT INTO `support_messages` VALUES (1,1,NULL,0,0,'Support request opened — item missing.','2026-09-09 02:28:35','2026-09-09 02:28:35'),(2,1,17,0,0,'Hi','2026-09-09 02:28:35','2026-09-09 02:28:35'),(3,1,15,1,0,'Hi','2026-09-09 02:39:52','2026-09-09 02:39:52'),(4,1,15,1,0,'We have noticed that your order is just packed and ready to be delivered. Please elaborate your issue.','2026-09-09 02:40:31','2026-09-09 02:40:31'),(8,1,15,1,0,'Delivered.','2026-09-09 05:07:13','2026-09-09 05:07:13'),(36,1,17,0,0,'Client ended chat.','2026-09-14 06:26:02','2026-09-14 06:26:02');
/*!40000 ALTER TABLE `support_messages` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `support_threads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `support_threads` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `order_id` bigint(20) unsigned DEFAULT NULL,
  `issue_type` varchar(255) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'open',
  `last_message_at` timestamp NULL DEFAULT NULL,
  `last_staff_message_at` timestamp NULL DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `rating` tinyint(3) unsigned DEFAULT NULL,
  `rating_comment` text DEFAULT NULL,
  `rated_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `support_threads_user_id_foreign` (`user_id`),
  KEY `support_threads_order_id_foreign` (`order_id`),
  KEY `support_threads_status_index` (`status`),
  KEY `support_threads_last_message_at_index` (`last_message_at`),
  CONSTRAINT `support_threads_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `support_threads_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `support_threads` WRITE;
/*!40000 ALTER TABLE `support_threads` DISABLE KEYS */;
INSERT INTO `support_threads` VALUES (1,17,NULL,'item_missing','resolved','2026-09-14 06:26:02','2026-09-09 05:07:13','2026-09-14 06:28:26',5,'got order.','2026-09-09 05:47:54','2026-09-09 02:28:35','2026-09-14 06:28:26');
/*!40000 ALTER TABLE `support_threads` ENABLE KEYS */;
UNLOCK TABLES;
DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `stripe_customer_id` varchar(255) DEFAULT NULL,
  `is_admin` tinyint(1) NOT NULL DEFAULT 0,
  `is_rider` tinyint(1) NOT NULL DEFAULT 0,
  `rider_is_active` tinyint(1) NOT NULL DEFAULT 1,
  `rider_rating_avg` decimal(3,2) DEFAULT NULL,
  `rider_rating_count` int(10) unsigned NOT NULL DEFAULT 0,
  `rider_declined_count` int(10) unsigned NOT NULL DEFAULT 0,
  `rider_missed_count` int(10) unsigned NOT NULL DEFAULT 0,
  `rider_offers_count` int(10) unsigned NOT NULL DEFAULT 0,
  `rider_daily_target_minutes` smallint(5) unsigned DEFAULT NULL,
  `rider_since` timestamp NULL DEFAULT NULL,
  `rider_available` tinyint(1) NOT NULL DEFAULT 0,
  `rider_unavailable_reason` varchar(200) DEFAULT NULL,
  `rider_last_seen_at` timestamp NULL DEFAULT NULL,
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
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (15,'Test User','test@example.com','+15551234567','cus_VEAEdiTnuYPjHz',1,0,1,NULL,0,0,0,0,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-09-14 23:45:34','$2y$12$g5tHJ.DFCrrpKZljpURgPOLI45v01uAYIMzGZsLQ4PYlgosrxpM5.',NULL,'2026-09-09 01:12:48','2026-09-14 23:45:34'),(16,'Sam Rider','rider@example.com',NULL,NULL,0,1,1,NULL,0,0,2,9,NULL,'2026-09-10 01:17:26',1,NULL,'2026-09-14 23:41:04',NULL,NULL,NULL,NULL,NULL,NULL,'2026-09-14 23:45:34','$2y$12$Kpz.EmIfJK7h7AZfl8iL2e01Sj7LyLQnSH0hWXa28jW9oyZp1Uu52',NULL,'2026-09-09 01:12:48','2026-09-14 23:45:34'),(17,'Testcaresort','testcaresort@outlook.com','+15551234567','cus_VE8eecdx05e2pN',0,0,1,NULL,0,0,0,0,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'$2y$12$skX3B4/nh5s/002bOYkfZ.uO5eeXCokTCYPh.8Q.Z28wpSnfcUDvy',NULL,'2026-09-09 02:25:33','2026-09-10 07:25:57'),(18,'New Ride','new_ride@example.com',NULL,NULL,0,1,1,NULL,0,0,0,0,480,'2026-09-09 05:14:36',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'$2y$12$kvtzqkILF65K1f7Zekch8ux7wHqhyNNSBFQG0zutKPpuhtETcpLZe',NULL,'2026-09-09 05:14:36','2026-09-11 01:33:45'),(19,'Ride Example','ride_example@gmail.com',NULL,NULL,0,0,0,NULL,0,0,0,0,NULL,'2026-09-09 05:15:06',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'$2y$12$s8TjsvlZWoF3ROrlOuTM2ucqQDyws.3wK9rRNdYSEe4Y6x/JnNos2',NULL,'2026-09-09 05:15:06','2026-09-11 01:34:32'),(28,'UI Admin','uiadmin@ex.com',NULL,NULL,1,0,1,NULL,0,0,0,0,NULL,NULL,0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'$2y$12$V6kPxpexIX6LF07gDN.9I.z9ssx/seSKPat5GgisFgIzNM9l0mhTW',NULL,'2026-09-10 02:14:06','2026-09-10 02:14:06');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

